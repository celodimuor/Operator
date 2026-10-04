---
status: accepted
date: 2026-10-04
deciders: Operator engineering
---

# 0006. Tenancy model

## Context and Problem Statement

Operator is a multi-tenant, resellable SaaS from day one. Core Chatwoot is already multi-account: `Account` owns inboxes, conversations, contacts and users (through `AccountUser`), and core controllers scope by `Current.account` with Pundit. Operator adds dozens of tables (billing, AI, records, parity features). What is the tenant, how is isolation enforced, and how is it proven?

## Decision Drivers

- Consistency with core so seams and core joins stay simple.
- A cross-tenant leak is the worst-case defect; isolation must be proven by tests, not assumed.
- Query performance at the large shape (500 accounts, 2 million conversations, 20 million messages, 1 million records).
- Operational simplicity for v1 (single region, single database).

## Considered Options

1. Core `Account` as tenant, application-level scoping, proven by a generated test matrix.
2. Same, plus PostgreSQL row-level security (RLS).
3. Schema-per-tenant or database-per-tenant.

## Decision Outcome

Chosen option: **1**. RLS is deferred, not rejected.

| Rule | Detail |
|---|---|
| Tenant | Core `::Account` |
| Foreign key | Every `operator_*` table has `account_id NOT NULL` with a foreign key to `accounts`, except global reference tables (for example `operator_regions`, `operator_plans`, AI model prices), which are explicitly listed as global in the data dictionary |
| Indexes | Every composite index leads with `account_id` |
| Access | Controllers resolve `Current.account` from the path and the authenticated user's `AccountUser`; queries go through Pundit `policy_scope` |
| Jobs | Jobs take `account_id` explicitly; a job whose record's `account_id` differs from its argument raises |
| Cable | Subscriptions to another account's stream are rejected |
| Vector search | Similarity queries are pre-filtered by `account_id` before the HNSW scan |
| Uniqueness | Uniqueness is per account, e.g. `Channel::Sms` phone number unique on `(account_id, phone_number)` |
| RLS | Not in v1. Revisit when self-hosted multi-tenant resale or regulatory requirements demand defence in depth |

Why not RLS in v1: core does not use it; every core query and seam would need session variables set per connection, which interacts with connection pooling, Sidekiq and ActionCable and multiplies upstream merge risk. Schema- or database-per-tenant breaks core joins and migrations and is rejected.

### Consequences

- Good: same model as core; seams join core and Operator tables directly.
- Good: leading `account_id` indexes keep tenant queries index-bounded.
- Good: isolation is proven on every PR for every API path.
- Bad: isolation depends on application code; a missing scope is a leak. Mitigated by the matrix, Pundit verification on every action and a review checklist item.
- Bad: global reference tables must be explicitly classified.

## Confirmation

| Check | CI job |
|---|---|
| Cross-tenant matrix generated from `operator/swagger/openapi.json`: every path and method tried with another tenant's ids and account path returns 404 or 403 and leaks no ids | `operator-specs` (tenancy) |
| Jobs with mismatched account raise; cable subscriptions across accounts rejected | `operator-specs` (tenancy), `sidekiq-cable-real` |
| Vector queries pre-filtered by account, asserted by EXPLAIN | `operator-specs` |
| Migration lint: new `operator_*` table has `account_id NOT NULL` and indexes lead with it, unless allow-listed as global | `migrations` |
| Pundit `verify_authorized` / `verify_policy_scoped` on every Operator action | authz route spec in `operator-specs` |
