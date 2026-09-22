-- Restricted Session Scope syntax/capabilities are version-sensitive. Validate against current Snowflake documentation.
USE ROLE ACCOUNTADMIN;
CREATE OR ALTER RESTRICTED SESSION SCOPE RSS_AGENT_DEMO_DB.GOVERNANCE.AGENT_GOVERNED_SCOPE AS $$
privilege_scopes:
  allowed_privileges:
    - privileges: [data read, program usage]
      account: [all]
    - privileges: [data write]
      databases: [RSS_AGENT_SANDBOX_DB]
role_scopes:
  blocked_roles: [ACCOUNTADMIN, SYSADMIN, SECURITYADMIN]
  allow_role_switching: false
$$;

CREATE OR REPLACE SESSION POLICY RSS_AGENT_DEMO_DB.GOVERNANCE.AGENT_GOVERNED_SESSION_POLICY
  AGENT_RESTRICTED_SESSION_SCOPE = 'RSS_AGENT_DEMO_DB.GOVERNANCE.AGENT_GOVERNED_SCOPE';

-- Attach the session policy to the dedicated demo user used to run the Agent.
-- Replace <DEMO_USER> before executing:
-- ALTER USER <DEMO_USER> SET SESSION POLICY RSS_AGENT_DEMO_DB.GOVERNANCE.AGENT_GOVERNED_SESSION_POLICY;
