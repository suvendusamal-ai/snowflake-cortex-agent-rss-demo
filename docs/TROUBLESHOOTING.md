# Troubleshooting

## Semantic View creation fails
Check the current Snowflake `CREATE SEMANTIC VIEW` syntax and your account feature availability. This capability evolves quickly.

## RSS DDL fails
Validate `CREATE OR ALTER RESTRICTED SESSION SCOPE`, YAML privilege-scope names, session-policy syntax, edition/preview/GA status, and required privileges against current Snowflake documentation.

## Agent does not call the intended tool
Use explicit validation prompts that name the desired operation/tool. Confirm the tool is saved in the committed Agent version and that the execution role has procedure usage.

## Banking write is denied outside the Agent
The RBAC baseline has failed. Fix grants before claiming RSS is responsible for an Agent-side denial.

## Banking write succeeds through the Agent
Do not force the expected narrative. Capture the behavior, verify whether the Agent session actually has the intended RSS active, and review caller/owner-rights semantics and current product behavior.

## Access History is empty
Account Usage views can have latency. Wait and retry before treating missing rows as evidence of no access.
