# Architecture

## Privilege model

```text
Same identity / same RBAC
        |
   +----+----+
   |         |
Human       Agent-active
session     session
   |         |
 RBAC      RBAC ∩ RSS
   |         |
Banking    Banking READ  -> designed ALLOW
WRITE      Banking WRITE -> designed DENY
ALLOW      Sandbox WRITE -> designed ALLOW
```

## Governance questions

- **Can reach?** Lineage describes declared/upstream relationships.
- **Can do?** RSS constrains the active Agent execution context.
- **Did access?** Query History and Access History provide runtime evidence.

RSS is one layer in defense in depth and does not replace RBAC/ABAC, masking, row-access policies, tool authorization, HITL, grounding, observability, or audit controls.
