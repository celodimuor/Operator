---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["operator/spec/**", "operator/lib/tasks/**", "app/javascript/operator/**/*.spec.js", "tests/**"]
status: current
---

# Testing standard

Decision and rationale: ADR 0010. Every test runs real Operator code against real PostgreSQL 16 with pgvector, Redis, Sidekiq, ActionCable, ActiveStorage (disk) and, for E2E, the Vue app in a real browser. The only substitutes are recordings of real provider traffic and tagged chaos fault injection at the HTTP boundary. Harness entry point: `operator/spec/operator_helper.rb` (foundation PR).

## Layers

| Layer | What is real | Notes |
|---|---|---|
| Model, service, query | database, Redis (`OPERATOR_REAL_REDIS`, OT-005), callbacks, constraints, encryption | |
| Job | synchronous `perform` | `:sidekiq_real` groups run a real Sidekiq process for retries, dead set, duplicate delivery, concurrency |
| Request and contract | full Rack stack, token auth, Pundit, Skooma request and response validation against `operator/swagger/openapi.json` | |
| Cable | Rails test adapter for broadcasts | `:cable_redis` groups boot Puma with the Redis adapter and a real WebSocket client |
| Frontend unit | Vitest with real components and real Pinia | `vi.mock` of Operator modules forbidden by lint |
| E2E | Compose stack with production Vite assets, Sidekiq, Mailpit; Playwright headless | per-test account isolation; axe on every page |
| Provider contract (PR CI) | adapters against VCR cassettes of real sandbox traffic | `record: :none` |
| Provider live (scheduled) | Paystack test keys, Stripe test mode, Africa's Talking sandbox, Smile ID sandbox, Meta test numbers, AI Gateway under budget | daily |
| Chaos | WebMock for timeouts, connection refused, 429, 5xx against provider hosts | tagged groups only |
| Seams | guard specs driving core entry points | one per `seams.rb` entry |
| Architecture and docs | boundaries, references, registries | |

## Cassettes

| Rule | Enforcement |
|---|---|
| Recorded only by the record rake task against the real sandbox; specs replay with `record: :none` | VCR config |
| Request matching on method, host, path and normalised body | VCR config |
| Secrets and PII filtered at record time | VCR filters, gitleaks |
| Checksums in `cassettes.lock`; hand edits fail | `registries` |
| No cassette older than 21 days; weekly re-record job opens a PR | `registries`, cassette re-record weekly |
| Inbound webhook fixtures captured from real sandbox deliveries with original signature headers | review |

Why this is not stubbing: every byte came from the provider's real system for a request our code issued; edits fail the checksum; body matching fails closed when our request changes; weekly re-recording and the daily live suite detect provider drift.

## Forbidden constructs

| Construct | Scope | Enforcement |
|---|---|---|
| `allow(...).to receive` | `operator/spec` | custom RuboCop cop |
| `instance_double`, `class_double` | `operator/spec` | custom RuboCop cop |
| `allow_any_instance_of` | `operator/spec` | custom RuboCop cop |
| `stub_const` on Operator or core constants | `operator/spec` | custom RuboCop cop |
| `stub_request` | outside tagged chaos groups | custom RuboCop cop |
| Rails fixtures | `operator/spec` | custom RuboCop cop |
| `vi.mock` of Operator modules | Vitest | `lint-js` |

Allowed: `travel_to`, `with_modified_env`. Approved test dependencies: `vcr`, `prosopite`, `strong_migrations`, Playwright.

## AI testing

| Item | Rule |
|---|---|
| Golden suites | Per pack, 30 or more cases at launch, replayed from cassettes in PR CI |
| Live evals | Nightly under a 20 dollar cap; scorecards written |
| Judge | LLM judge from a different model family than the model under test; 10 percent spot-checked monthly by the lead |
| Red team | Injection, exfiltration, cross-tenant requests, tool abuse, harmful content in local languages |
| Thresholds | Golden pass rate at least max(90 percent, baseline minus 2 points); judge mean at least 4.0; zero critical red-team failures |

## Coverage

| Scope | Line | Branch |
|---|---|---|
| Default | 90 | 80 |
| Billing, identity, tenancy, webhooks, authz | 95 | 90 |
| Vitest | 80 | |
| Ratchet | +0.3 points per PR, never down | |

## Flakiness

| Rule | Detail |
|---|---|
| RSpec | No retries |
| Playwright | One retry; a retried pass is recorded as flaky |
| Quarantine | Seven-day cap, at most three tests quarantined at once |

## Data

| Rule | Detail |
|---|---|
| Factories | FactoryBot only; tenant-consistent graphs (all records in one graph share an account) |
| Lint | `FactoryBot.lint` in CI |
| Large shape | Seed of 500 accounts, 2 million conversations, 20 million messages, 1 million records for nightly runs |

## Performance

| Check | Cadence |
|---|---|
| Prosopite raise mode | every spec run |
| k6 against large shape | nightly |
| EXPLAIN checks on hot queries | nightly |

## Migrations

| Check | Cadence |
|---|---|
| Up-down-up, `strong_migrations`, schema drift, column comments | every PR (`migrations`) |
| Migrations against large shape | nightly |

## Upstream merge gate

Every upstream merge PR runs: full core and Operator specs, schema dump without drift, routes snapshot, seam guards, size-limit, Playwright smoke, touch audit, clean-room guard.

## Cross-tenant matrix

| Surface | Assertion |
|---|---|
| HTTP | Generated from the OpenAPI file: every path and method tried with another tenant's ids and account path returns 404 or 403 and leaks no ids |
| Jobs | A job whose record's account differs from its `account_id` argument raises |
| Cable | Subscriptions to another account's stream are rejected |
| Vector search | Queries pre-filtered by account, asserted by EXPLAIN |
