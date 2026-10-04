---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["operator/app/**", "operator/db/**", "app/javascript/operator/**"]
status: current
---

# Performance standard

## Code rules

| Rule | Enforcement |
|---|---|
| No N+1 queries: Prosopite in raise mode across Operator specs | `operator-specs` |
| Composite indexes lead with `account_id` | migration lint |
| Hot queries have EXPLAIN checks against the large-shape seed | nightly |
| Vector similarity queries pre-filter by `account_id` (HNSW, `vector(1536)`) | EXPLAIN assertion in `operator-specs` |
| Cursor pagination only | `api-contract` |
| Long work in jobs, chunked and resumable; never in the request cycle | review |
| Webhooks acknowledged in under one second | `operator-specs` |
| USSD handler answers synchronously inside the five-second budget | `operator-specs` (planned with USSD) |
| Frontend routes lazy; widget size budget | size-limit in `build` |

## SLOs (production)

| Indicator | Target |
|---|---|
| Availability | 99.9 percent |
| Ingestion availability | 99.95 percent |
| API p95, read | 250 ms |
| API p95, write | 400 ms |
| Job lag, critical queues | 5 s |
| AI first token | 2.5 s |
| AI full reply | 8 s |
| 5xx rate | under 0.1 percent |
| Cost per resolved conversation | within pack budget |

Alerts use multi-window burn rates (observability.md).

## Load and scale testing

| Test | Shape | Cadence |
|---|---|---|
| k6 load | 500 accounts, 2 million conversations, 20 million messages, 1 million records | nightly |
| Migrations against large shape | same seed | nightly |
| Canary gate | rollback on 5xx above 0.5 percent or p95 above 1.5 times baseline over 20 minutes | every release |
