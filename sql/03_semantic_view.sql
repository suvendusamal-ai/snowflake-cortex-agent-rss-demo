-- Semantic View syntax is version-sensitive. Validate against current Snowflake documentation.
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE SEMANTIC VIEW RSS_AGENT_DEMO_DB.BANKING.BANKING_RSS_DEMO_SV
  TABLES (
    customers AS RSS_AGENT_DEMO_DB.BANKING.CUSTOMER PRIMARY KEY (CUSTOMER_ID),
    transactions AS RSS_AGENT_DEMO_DB.BANKING.BANK_TRANSACTION PRIMARY KEY (TRANSACTION_ID)
  )
  RELATIONSHIPS (
    transactions_to_customers AS transactions(CUSTOMER_ID) REFERENCES customers(CUSTOMER_ID)
  )
  FACTS (
    transactions.amount AS AMOUNT
  )
  DIMENSIONS (
    customers.customer_id AS CUSTOMER_ID,
    customers.customer_name AS CUSTOMER_NAME,
    customers.risk_rating AS RISK_RATING,
    transactions.transaction_id AS TRANSACTION_ID,
    transactions.customer_id AS CUSTOMER_ID,
    transactions.transaction_type AS TRANSACTION_TYPE,
    transactions.status AS STATUS
  )
  METRICS (
    transactions.total_amount AS SUM(transactions.amount),
    transactions.transaction_count AS COUNT(transactions.transaction_id)
  );
GRANT USAGE ON SEMANTIC VIEW RSS_AGENT_DEMO_DB.BANKING.BANKING_RSS_DEMO_SV TO ROLE RSS_AGENT_DEMO_USER_ROLE;
