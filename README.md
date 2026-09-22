# Snowflake Cortex Agent Restricted Session Scope (RSS) Demo

A reproducible reference implementation for exploring how **Restricted Session Scope (RSS)** can place an Agent-specific privilege ceiling over a user's existing Snowflake RBAC privileges.

> **Implementation note:** This repository is a reproducible reference implementation. Snowflake Cortex Agent and Restricted Session Scope capabilities evolve rapidly. Validate version-sensitive syntax and behavior against current Snowflake documentation before using this pattern in production.

## Start here

1. Read [`IMPLEMENTATION_GUIDE.md`](IMPLEMENTATION_GUIDE.md) and follow the gates in order.
2. Use [`SEQUENCE_DIAGRAMS.md`](SEQUENCE_DIAGRAMS.md) for execution-flow reference.
3. Use [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the governance model.
4. Record actual evidence in [`docs/VALIDATION_RESULTS.md`](docs/VALIDATION_RESULTS.md).

## Core idea

```text
Human session       -> RBAC
Agent-active session -> RBAC ∩ RSS
```

The reference design intentionally separates three governance questions:

- **Can reach?** → Lineage
- **Can do?** → Restricted Session Scope
- **Did access?** → Query History / Access History

## Designed validation outcome

| Context | Operation | Designed outcome |
|---|---|---|
| Human | Banking READ | ALLOW |
| Human | Banking WRITE | ALLOW |
| Human | Sandbox WRITE | ALLOW |
| Agent | Banking READ | ALLOW |
| Agent | Banking WRITE | DENY |
| Agent | Sandbox WRITE | ALLOW |

These are validation targets, not claims of observed execution in this packaged reference implementation.

## Repository map

- `sql/` — setup, RBAC baseline, semantic view, RSS, custom tools, validation, cleanup
- `agent/` — Cortex Agent configuration steps
- `docs/` — architecture, validation evidence template, troubleshooting
- `linkedin/` — final post draft and publishing checklist
- `images/` — evidence-image guidance

## Defense in depth

RSS does not replace RBAC, ABAC, masking, row-access policies, tool authorization, HITL, grounding, observability, evaluation, secrets management, or audit controls. It is one enforcement boundary in an enterprise Agent governance architecture.
