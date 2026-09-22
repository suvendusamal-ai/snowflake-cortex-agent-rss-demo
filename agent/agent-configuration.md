# Cortex Agent Configuration

Configure a named Cortex Agent `RSS_AGENT_DEMO_DB.AGENT.BANKING_RSS_AGENT` in Snowsight.

## Tools

1. **BANKING_ANALYST** — Cortex Analyst backed by `RSS_AGENT_DEMO_DB.BANKING.BANKING_RSS_DEMO_SV`.
2. **UPDATE_BANKING_STATUS** — custom stored-procedure tool backed by `RSS_AGENT_DEMO_DB.TOOLS.UPDATE_BANKING_STATUS`; use `RSS_AGENT_DEMO_WH`.
3. **ADD_AGENT_NOTE** — custom stored-procedure tool backed by `RSS_AGENT_DEMO_DB.TOOLS.ADD_AGENT_NOTE`; use `RSS_AGENT_DEMO_WH`.

Both procedures are intentionally `EXECUTE AS CALLER`.

## Validation prompts

**READ:** Show all transactions for customer CUST-1001, including transaction ID, amount, transaction type and status.

**GOVERNED WRITE:** Change transaction TXN-9002 status to MANUAL_REVIEW using the transaction status update tool.

**CONTROLLED WRITE:** Create investigation note 401 for customer CUST-1001 with the text "Transaction reviewed by banking investigation agent" using the investigation-note tool.

Do not treat a natural-language refusal as RSS proof. Inspect the actual tool invocation and database state.
