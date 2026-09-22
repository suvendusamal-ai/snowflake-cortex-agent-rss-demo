# Sequence Diagrams

GitHub renders the following Mermaid diagrams directly.

## 1. Human-session RBAC baseline

```mermaid
sequenceDiagram
    actor User
    participant Session as Normal Snowflake Session
    participant RBAC as RBAC
    participant Bank as Banking Database
    User->>Session: UPDATE TXN-9002
    Session->>RBAC: Check UPDATE privilege
    RBAC-->>Session: ALLOW
    Session->>Bank: UPDATE status
    Bank-->>User: Success
```

This establishes that the user's underlying RBAC role can write to the banking table.

## 2. Agent governed read

```mermaid
sequenceDiagram
    actor User
    participant Agent as Cortex Agent
    participant RSS as Restricted Session Scope
    participant Analyst as Cortex Analyst
    participant SV as Banking Semantic View
    participant Bank as Banking Tables
    User->>Agent: Show CUST-1001 transactions
    Agent->>RSS: Agent-active execution
    RSS->>Analyst: Data read allowed
    Analyst->>SV: Query semantic view
    SV->>Bank: Read governed data
    Bank-->>Agent: TXN-9001, TXN-9002
    Agent-->>User: Grounded result
```

## 3. Agent production write — target DENY path

```mermaid
sequenceDiagram
    actor User
    participant Agent as Cortex Agent
    participant Tool as UPDATE_BANKING_STATUS
    participant RSS as Restricted Session Scope
    participant Bank as Banking Database
    User->>Agent: Set TXN-9002 to MANUAL_REVIEW
    Agent->>Tool: Invoke custom procedure
    Tool->>RSS: Execute as caller
    RSS->>RSS: Evaluate RBAC ∩ RSS
    Note over RSS: RBAC permits write<br/>RSS does not permit Banking write
    RSS-->>Tool: DENY
    Tool-->>Agent: Authorization failure
    Agent-->>User: Update not executed
```

This diagram is a **target validation path** until runtime evidence confirms it.

## 4. Agent sandbox write — target ALLOW path

```mermaid
sequenceDiagram
    actor User
    participant Agent as Cortex Agent
    participant Tool as ADD_AGENT_NOTE
    participant RSS as Restricted Session Scope
    participant Sandbox as Agent Sandbox
    User->>Agent: Add investigation note 401
    Agent->>Tool: Invoke custom procedure
    Tool->>RSS: Execute as caller
    RSS->>RSS: Evaluate RBAC ∩ RSS
    Note over RSS: RBAC permits write<br/>RSS permits Sandbox write
    RSS->>Sandbox: INSERT note
    Sandbox-->>Tool: Success
    Tool-->>Agent: Note created
    Agent-->>User: Success
```

## 5. Evidence chain

```mermaid
flowchart LR
    A[RBAC Baseline] --> B[Agent Tool Invocation]
    B --> C[RSS Enforcement]
    C --> D[Object State]
    D --> E[Query / Access History]
    E --> F[Lineage]
```

The evidence chain separates three governance questions: **Can reach? → Lineage**, **Can do? → RSS**, **Did access? → Access History**.
