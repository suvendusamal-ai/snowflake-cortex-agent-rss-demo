# Validation Results

This file is intentionally a template. Replace expected outcomes with actual evidence only after execution.

| Test | Designed outcome | Observed result | Evidence |
|---|---|---|---|
| Human Banking WRITE | ALLOW | Not executed in packaged reference | Add screenshot/query result |
| Human Sandbox WRITE | ALLOW | Not executed in packaged reference | Add screenshot/query result |
| Agent Banking READ | ALLOW | Not executed in packaged reference | Add Agent trace |
| Agent Banking WRITE | DENY | Not executed in packaged reference | Add tool trace + unchanged row |
| Agent Sandbox WRITE | ALLOW | Not executed in packaged reference | Add tool trace + inserted row |
| Agent lineage | Agent → semantic view → tables | Not executed in packaged reference | Add GET_LINEAGE output |
| Runtime audit | Agent-attributed history | Not executed in packaged reference | Add Query/Access History output |

## Evidence standard

A natural-language Agent refusal is not sufficient evidence of RSS enforcement. Capture the tool invocation, authorization/error evidence where available, and final object state.
