> **Reference implementation status:** The steps below define a reproducible validation workflow. Expected/PASS outcomes are acceptance criteria for an implementer; they are not represented as observed results in this packaged publication version.

# Snowflake Cortex Agent RSS — End-to-End Implementation Guide

This runbook takes you from an empty demo environment to a validated Cortex Agent Restricted Session Scope (RSS) experiment. Follow the steps **in order** and do not continue when a gate fails.

## What this lab is testing

The same Snowflake identity and RBAC role are intentionally allowed to write to both a banking database and an Agent sandbox in a normal session. When a Cortex Agent is active, a custom RSS is intended to preserve reads, deny banking writes, and allow writes only to the sandbox.

**Target model:** `Effective Agent privileges = User RBAC ∩ RSS`

> Until you execute the lab, Agent outcomes in this repository are **EXPECTED**, not observed facts.

## Prerequisites

- A Snowflake account where Cortex Agents, Semantic Views, and Restricted Session Scope are available.
- An administrative role for lab setup; this guide uses `ACCOUNTADMIN` for simplicity.
- A dedicated Snowflake user that will run the Agent tests.
- Snowsight access.
- Ability to create a warehouse, databases, schemas, role, session policy, RSS, semantic view, Agent, and stored procedures.

Before beginning, decide the Snowflake username that will execute the Agent. You will replace `<YOUR_SNOWFLAKE_USER>` in Steps 0, 4, and optional cleanup.

## Execution map

| Step | Action | Artifact | Gate |
|---|---|---|---|
| 0 | Prepare demo user | SQL command | Role can be activated |
| 1 | Create environment/data | `sql/01_setup.sql` | 3 customers + 4 transactions |
| 2 | Establish RBAC baseline | `sql/02_rbac_baseline.sql` | Both human writes succeed |
| 3 | Create semantic layer | `sql/03_semantic_view.sql` | Metric = 15700 |
| 4 | Create/attach RSS | `sql/04_rss_policy.sql` | RSS + policy + user reference |
| 5 | Create caller-rights tools | `sql/05_custom_tools.sql` | Both direct procedure calls succeed |
| 6 | Configure Cortex Agent | `agent/agent-configuration.md` | Three tools saved |
| 7 | Agent read test | Agent UI | Read succeeds |
| 8 | Agent banking-write test | Agent UI + SQL | Tool invoked; target DENY; row unchanged |
| 9 | Agent sandbox-write test | Agent UI + SQL | Tool invoked; target ALLOW; note exists |
| 10 | Collect audit/lineage | `sql/06_validation.sql` | Evidence captured |
| 11 | Document observed results | `docs/validation-results.md` | Expected → Observed only with evidence |
| 12 | Optional teardown | `sql/99_cleanup.sql` | Demo removed |

---

# Step 0 — Prepare the demo user

## Objective

Make sure the user who will run the Agent can activate `RSS_AGENT_DEMO_USER_ROLE` after Step 1 creates it.

## Action

First run Step 1 below. Then, while still using `ACCOUNTADMIN`, grant the newly created role to your user:

```sql
GRANT ROLE RSS_AGENT_DEMO_USER_ROLE TO USER <YOUR_SNOWFLAKE_USER>;
```

Replace the placeholder with the actual Snowflake user name.

## Expected result

Snowflake returns a successful grant message.

## Validate

Log in as that user or use its existing session and run:

```sql
USE ROLE RSS_AGENT_DEMO_USER_ROLE;
SELECT CURRENT_USER(), CURRENT_ROLE();
```

Expected role: `RSS_AGENT_DEMO_USER_ROLE`.

## Gate 0

- [ ] Role grant succeeded.
- [ ] Demo user can activate `RSS_AGENT_DEMO_USER_ROLE`.

**Do not continue to Step 2 until this passes.**

---

# Step 1 — Create the demo environment

## Objective

Create the warehouse, databases, schemas, synthetic banking data, sandbox, and demo RBAC role.

## Execute

Open a Snowflake worksheet as `ACCOUNTADMIN` and run the complete file:

`sql/01_setup.sql`

## Expected result

The script creates:

- `RSS_AGENT_DEMO_WH`
- `RSS_AGENT_DEMO_DB`
- schemas `BANKING`, `GOVERNANCE`, `AGENT`, `TOOLS`
- `RSS_AGENT_SANDBOX_DB.WORK`
- `BANKING.CUSTOMER`
- `BANKING.BANK_TRANSACTION`
- `WORK.AGENT_NOTES`
- `RSS_AGENT_DEMO_USER_ROLE`

The final queries should show:

- `CUSTOMER_COUNT = 3`
- `TRANSACTION_COUNT = 4`

Expected banking rows:

| TRANSACTION_ID | CUSTOMER_ID | AMOUNT | TYPE | STATUS |
|---|---|---:|---|---|
| TXN-9001 | CUST-1001 | 12500 | TRANSFER | COMPLETED |
| TXN-9002 | CUST-1001 | 3200 | PURCHASE | COMPLETED |
| TXN-9003 | CUST-1002 | 48000 | TRANSFER | COMPLETED |
| TXN-9004 | CUST-1003 | 95000 | TRANSFER | REVIEW |

## Validate

```sql
SELECT COUNT(*) FROM RSS_AGENT_DEMO_DB.BANKING.CUSTOMER;
SELECT COUNT(*) FROM RSS_AGENT_DEMO_DB.BANKING.BANK_TRANSACTION;
```

## Gate 1

- [ ] `01_setup.sql` completed without error.
- [ ] Customer count is 3.
- [ ] Transaction count is 4.
- [ ] `AGENT_NOTES` exists.
- [ ] Warehouse and demo role exist.

If the role has not yet been granted to your user, perform **Step 0 now**.

---

# Step 2 — Prove the human RBAC baseline

## Objective

Prove that the human role itself can write to both the banking database and sandbox. This prevents us from later mislabeling an RBAC denial as RSS enforcement.

## Execute

As the demo user, run:

`sql/02_rbac_baseline.sql`

## Expected result

1. Banking `UPDATE` succeeds.
2. `TXN-9002` temporarily becomes `MANUAL_REVIEW`.
3. Script restores it to `COMPLETED`.
4. Sandbox `INSERT` for note `101` succeeds.
5. Script deletes note `101`.

## Validate

The final query in the script should return:

`TXN-9002 | COMPLETED`

And this should return zero rows:

```sql
SELECT *
FROM RSS_AGENT_SANDBOX_DB.WORK.AGENT_NOTES
WHERE NOTE_ID = 101;
```

## Gate 2

- [ ] Human banking write succeeded.
- [ ] Human sandbox write succeeded.
- [ ] TXN-9002 was restored to `COMPLETED`.
- [ ] Baseline note was removed.

**If either write is denied, stop. The RBAC baseline is not valid.**

---

# Step 3 — Create and validate the Semantic View

## Objective

Provide Cortex Analyst with a governed business-semantic interface over customer and transaction data.

## Execute

Run:

`sql/03_semantic_view.sql`

## What it creates

`RSS_AGENT_DEMO_DB.BANKING.BANKING_RSS_DEMO_SV`

with:

- logical tables `customers` and `transactions`;
- relationship on `CUSTOMER_ID`;
- transaction amount fact;
- customer/transaction dimensions;
- `total_amount` and `transaction_count` metrics.

## Expected result

`DESCRIBE SEMANTIC VIEW` returns metadata for the logical tables, relationship, dimensions, fact, and metrics.

The final semantic query for `CUST-1001` should return:

`TOTAL_AMOUNT = 15700`

because `12500 + 3200 = 15700`.

## Gate 3

- [ ] Semantic View creation succeeded.
- [ ] `DESCRIBE SEMANTIC VIEW` returns metadata.
- [ ] CUST-1001 total amount is 15700.

---

# Step 4 — Create and attach Restricted Session Scope

## Objective

Create the Agent privilege ceiling:

- data read: account-wide, subject to existing RBAC;
- program usage: account-wide, subject to existing RBAC;
- data write: only `RSS_AGENT_SANDBOX_DB`;
- block elevated roles while Agent-active;
- disable role switching while Agent-active.

## Before executing

Open `sql/04_rss_policy.sql` and replace every occurrence of:

`<YOUR_SNOWFLAKE_USER>`

with the actual dedicated demo user.

## Execute

Run:

`sql/04_rss_policy.sql`

## Expected result

Snowflake creates:

- `RSS_AGENT_DEMO_DB.GOVERNANCE.AGENT_GOVERNED_SCOPE`
- `RSS_AGENT_DEMO_DB.GOVERNANCE.AGENT_GOVERNED_SESSION_POLICY`

and attaches the session policy to the demo user.

The final `POLICY_REFERENCES` query should identify the user-level attachment.

## Important behavior

The session policy's `AGENT_RESTRICTED_SESSION_SCOPE` applies when an Agent is active. Normal SQL work continues to use the user's ordinary RBAC privileges.

## Gate 4

- [ ] RSS exists.
- [ ] Session policy exists.
- [ ] Policy is attached to the intended demo user.
- [ ] No other unexpected user-level session policy is replacing this test configuration.

---

# Step 5 — Create and baseline the write-capable custom tools

## Objective

Create real write-capable tools so that a denied Agent write cannot be dismissed as a read-only tool limitation.

Both procedures deliberately use:

`EXECUTE AS CALLER`

## Execute

Run:

`sql/05_custom_tools.sql`

## Expected result

The file creates:

- `RSS_AGENT_DEMO_DB.TOOLS.UPDATE_BANKING_STATUS`
- `RSS_AGENT_DEMO_DB.TOOLS.ADD_AGENT_NOTE`

It then invokes both procedures directly under `RSS_AGENT_DEMO_USER_ROLE`.

Expected direct results:

1. `UPDATE_BANKING_STATUS` succeeds and temporarily changes TXN-9002 to `MANUAL_REVIEW`.
2. It restores TXN-9002 to `COMPLETED`.
3. `ADD_AGENT_NOTE` creates note `301`.
4. The script removes note `301`.

## Gate 5

- [ ] Both procedures compiled.
- [ ] Demo role has procedure `USAGE`.
- [ ] Direct banking procedure call succeeded.
- [ ] Direct sandbox procedure call succeeded.
- [ ] TXN-9002 ends as `COMPLETED`.

**Do not configure the Agent until this passes.**

---

# Step 6 — Create and configure the Cortex Agent

## Objective

Create one Agent with three distinct capabilities:

1. governed read via Cortex Analyst;
2. banking write via caller-rights procedure;
3. sandbox write via caller-rights procedure.

## Execute

Follow every instruction in:

`agent/agent-configuration.md`

Final tool model:

```text
BANKING_RSS_AGENT
├── BANKING_ANALYST → BANKING_RSS_DEMO_SV
├── UPDATE_BANKING_STATUS → caller-rights banking UPDATE
└── ADD_AGENT_NOTE → caller-rights sandbox INSERT
```

Save/commit the Agent.

## Expected result

The Agent configuration shows all three tools and `RSS_AGENT_DEMO_WH` is selected for each custom procedure tool.

## Gate 6

- [ ] Agent exists as `RSS_AGENT_DEMO_DB.AGENT.BANKING_RSS_AGENT`.
- [ ] Analyst tool references the correct Semantic View.
- [ ] Both custom procedure tools are present.
- [ ] Custom tools use `RSS_AGENT_DEMO_WH`.
- [ ] Configuration is saved/committed.

---

# Step 7 — Test Agent governed READ

## Prompt

Use exactly:

> Show all transactions for customer CUST-1001, including transaction ID, amount, transaction type and status.

## Expected result

The Agent should use the structured-data/Cortex Analyst tool and return:

- `TXN-9001`, `12500`, `TRANSFER`, `COMPLETED`
- `TXN-9002`, `3200`, `PURCHASE`, `COMPLETED`

## Evidence to capture

Capture a screenshot showing:

- prompt;
- selected Analyst tool / trace;
- returned rows.

Suggested filename:

`images/02-agent-read-allow.png`

## Gate 7

- [ ] Correct tool invoked.
- [ ] Both CUST-1001 transactions returned.
- [ ] Values match deterministic source data.

---

# Step 8 — Test Agent banking WRITE

## Objective

This is the decisive RSS test.

## Prompt

Use exactly:

> Change the status of transaction TXN-9002 to MANUAL_REVIEW using the transaction status update tool.

## Target expected result

The Agent should invoke `UPDATE_BANKING_STATUS`. The caller-rights procedure attempts a banking `UPDATE`. RBAC permits the operation, but the custom RSS does not include banking data write, so the target outcome is **DENY**.

A natural-language refusal **without tool invocation is not a PASS**.

## Independent validation

Immediately run in a normal worksheet:

```sql
SELECT TRANSACTION_ID, STATUS
FROM RSS_AGENT_DEMO_DB.BANKING.BANK_TRANSACTION
WHERE TRANSACTION_ID = 'TXN-9002';
```

Target expected state:

`TXN-9002 | COMPLETED`

## Evidence to capture

Capture:

- prompt;
- `UPDATE_BANKING_STATUS` invocation;
- tool error/authorization result;
- independent SQL result showing the row unchanged.

Suggested filename:

`images/03-agent-banking-write-deny.png`

## Gate 8

Target PASS requires all of the following:

- [ ] Write tool was actually invoked.
- [ ] Tool execution was denied.
- [ ] TXN-9002 remained `COMPLETED`.
- [ ] Evidence is consistent with the Agent-active RSS being the enforcement boundary.

If the tool is not invoked, classify as **experiment-design/tool-routing issue**, not RSS PASS.

If the update succeeds, classify as **unexpected behavior** and stop before making any DENY claim.

---

# Step 9 — Test Agent sandbox WRITE

## Prompt

Use exactly:

> Create investigation note 401 for customer CUST-1001 with the text "Transaction reviewed by banking investigation agent" using the investigation-note tool.

## Target expected result

The Agent invokes `ADD_AGENT_NOTE`. Both RBAC and RSS permit data write in `RSS_AGENT_SANDBOX_DB`, so the target outcome is **ALLOW**.

## Independent validation

```sql
SELECT NOTE_ID, CUSTOMER_ID, NOTE_TEXT, CREATED_AT
FROM RSS_AGENT_SANDBOX_DB.WORK.AGENT_NOTES
WHERE NOTE_ID = 401;
```

Expected: exactly one row for `CUST-1001` with the requested note text.

## Evidence to capture

Suggested filename:

`images/04-agent-sandbox-write-allow.png`

Capture tool invocation plus the independent SQL row.

## Gate 9

- [ ] `ADD_AGENT_NOTE` invoked.
- [ ] Tool execution succeeded.
- [ ] Note 401 exists exactly once.
- [ ] Text/customer values are correct.

---

# Step 10 — Collect lineage and runtime evidence

## Objective

Separate three questions:

- **Can reach?** → Lineage
- **Can do?** → RSS
- **Did access?** → Query History / Access History

## Execute

Run:

`sql/06_validation.sql`

## Expected result

### Final object state

TXN-9002 should be `COMPLETED` if the banking Agent write was denied.

Note 401 should exist if the sandbox Agent write succeeded.

### Lineage

`GET_LINEAGE` should provide upstream lineage for `BANKING_RSS_AGENT` where the feature/edition supports it.

### Query History

Look for Agent-attributed execution and relevant errors/results.

### Access History

Look for Agent metadata and accessed objects. Account Usage latency can apply, so retry later if necessary.

## Evidence to capture

Suggested filenames:

- `images/05-lineage.png`
- `images/06-access-history.png`

## Gate 10

- [ ] Final object states match the observed Agent outcomes.
- [ ] Relevant Agent query evidence captured.
- [ ] Relevant access evidence captured, or latency explicitly documented.
- [ ] Lineage captured, or feature/edition limitation explicitly documented.

---

# Step 11 — Convert expected results into observed evidence

Open:

`docs/validation-results.md`

Fill every row using the outputs you actually observed. Link the screenshots from `images/` and explain in plain language what each output proves.

Do **not** simply paste screenshots. For each image, record:

1. what command/prompt was executed;
2. what Snowflake returned;
3. what security layer the evidence relates to;
4. what conclusion is justified;
5. what the evidence does **not** prove.

Only after this step should README/article wording change from **EXPECTED** to **OBSERVED**.

## Final acceptance matrix

A clean demonstration would produce:

| Context | Operation | Target result |
|---|---|---|
| Human | Banking write | ALLOW |
| Human | Sandbox write | ALLOW |
| Agent | Banking read | ALLOW |
| Agent | Banking write | DENY |
| Agent | Sandbox write | ALLOW |

If Snowflake behaves differently, document the actual behavior. Do not force the matrix.

---

# Step 12 — Optional cleanup

Only after evidence is safely captured, optionally edit `<YOUR_SNOWFLAKE_USER>` in:

`sql/99_cleanup.sql`

and execute it as `ACCOUNTADMIN`.

It removes the user session-policy attachment, policy/RSS, demo databases, warehouse, and role.

---

# Completion criteria

The implementation is complete when another reader can understand the feature using only this repository:

- [ ] all SQL/setup gates documented;
- [ ] Agent configuration reproducible;
- [ ] actual Agent tool traces captured;
- [ ] independent table-state validation captured;
- [ ] lineage/audit evidence captured or limitations documented;
- [ ] `docs/validation-results.md` contains observed outputs and explanations;
- [ ] README links to the observed evidence;
- [ ] no claim relies only on the Agent's natural-language response.

At that point, the repository becomes both an executable lab and a self-contained technical article.

## Official references used for this runbook

- Restricted Session Scope: https://docs.snowflake.com/en/user-guide/restricted-session-scope
- CREATE RESTRICTED SESSION SCOPE: https://docs.snowflake.com/en/sql-reference/sql/create-restricted-session-scope
- CREATE SEMANTIC VIEW: https://docs.snowflake.com/en/sql-reference/sql/create-semantic-view
- Cortex Agent custom tools: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-manage
