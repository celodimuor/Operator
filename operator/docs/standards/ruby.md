---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["operator/app/**/*.rb", "operator/lib/**/*.rb", "operator/db/**/*.rb", "operator/spec/**/*.rb"]
status: current
---

# Ruby standard

## Structure

| Rule | Enforcement |
|---|---|
| Bounded contexts: `kernel`, `platform`, `packs`. Dependency direction packs -> platform -> kernel -> core; never the reverse | Prism-based boundary spec, `architecture` |
| Namespaces `Operator::<Module>::<Name>`; core constants fully qualified (`::Account`) inside `module Operator` | `lint-ruby`, review |
| No abstraction (base class, module, port) without two concrete implementations | review |
| Class at most 200 lines; method at most 15 lines | RuboCop metrics, `lint-ruby` |
| Seam modules `Operator::Seams::<CoreClass>Ext`, at most 30 lines, delegate only, call `super` on non-Operator paths; registered only in `operator/lib/operator/seams.rb` (ADR 0001) | custom cop, seam guard specs |

## Services, commands, queries

| Rule | Enforcement |
|---|---|
| Service objects named `VerbNoun`, one public method `call`, keyword arguments only, at most 100 lines | custom cop, `lint-ruby` |
| Commands return `Operator::Result` (success or failure with an error code) | review |
| Queries never write | review |
| Expected outcomes (validation failure, declined payment, not found) are results; bugs raise | review |
| No bare `rescue` and no `rescue Exception`; rescue named errors only | RuboCop, `lint-ruby` |

## Jobs

| Rule | Enforcement |
|---|---|
| Queue name `operator_*` | job catalogue, `registries` |
| Idempotent with a declared idempotency key | job catalogue generator requires the declaration, `registries` |
| Bounded retries declared explicitly | job catalogue, `registries` |
| Large work chunked and resumable (cursor persisted) | review, `sidekiq-cable-real` |
| `account_id` passed explicitly; mismatched account raises | cross-tenant matrix |

## Webhooks (inbound)

| Rule | Enforcement |
|---|---|
| Verify signature over the raw body before parsing | contract specs on captured real deliveries |
| Persist to `operator_inbound_events(provider, event_id)` (unique) before processing | `operator-specs` |
| Acknowledge in under one second; process asynchronously | `operator-specs`, review |
| Duplicate delivery produces one effect | `sidekiq-cable-real` |

## Transactions and concurrency

| Rule | Enforcement |
|---|---|
| A transaction never spans external I/O (HTTP, provider SDK, AI call) | review |
| Enqueue jobs after commit (`after_commit` or equivalent) | review |
| Locks acquired in a deterministic order | review |
| Prosopite in raise mode in specs (no N+1) | `operator-specs` |

## Migrations and data

| Rule | Enforcement |
|---|---|
| `strong_migrations` on every migration | `migrations` |
| Expand and contract only; no destructive change in the same release as the code that stops using it | `migrations`, review |
| Every new column has a comment carrying its data class | `migrations` (comments check) |
| New `operator_*` tables: `account_id NOT NULL`, indexes lead with `account_id` (ADR 0006) | migration lint |
| Money as integer minor units plus ISO currency, never float, never jsonb | migration lint |
| Up-down-up reversible | `migrations` |
| Data migrations are idempotent batched jobs, not migration bodies | review |
| Migrations live in `operator/db/migrate` | engine initializer, review |

## Style

| Rule | Enforcement |
|---|---|
| Core `.rubocop.yml` plus Operator cops (no-stub, seam size, service shape) | `lint-ruby` |
| Duplication below 1 percent | jscpd, `architecture` |
