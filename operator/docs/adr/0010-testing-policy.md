---
status: accepted
date: 2026-10-04
deciders: Operator engineering
---

# 0010. Testing policy: nothing stubbed

## Context and Problem Statement

Operator is delivered autonomously with CI as the only merge gate and zero human approvals. Tests are therefore the only evidence that a change works. Stubs and mocks let tests pass while the system is broken: a stubbed collaborator encodes the author's belief about behaviour, not the behaviour. What may a test substitute, and how is that enforced?

## Decision Drivers

- A green suite must mean the real system works.
- External providers (payments, SMS, WhatsApp, KYC, AI) must be exercised without making PR CI flaky, slow or costly.
- Provider drift must be detected.
- Rules must be enforced by tooling, not review.

## Considered Options

1. Conventional RSpec with doubles and WebMock stubs.
2. Real infrastructure, providers hit live in every PR.
3. Real infrastructure; providers via official sandboxes on a schedule and via recorded real traffic in PR CI; substitution forbidden by lint.

## Decision Outcome

Chosen option: **3**.

| Component | In tests |
|---|---|
| PostgreSQL 16 with pgvector, Redis, Sidekiq, ActionCable, ActiveStorage (disk), browser | Real. Redis is real via `OPERATOR_REAL_REDIS` (OT-005) because core hard-wires `MockRedis` in test |
| External providers, PR CI | VCR cassettes of real sandbox traffic, `record: :none` |
| External providers, scheduled | Official sandboxes live (Paystack test keys, Stripe test mode, Africa's Talking sandbox, Smile ID sandbox, Meta test numbers, AI Gateway under budget) |
| Fault injection | WebMock only in tagged chaos groups: timeouts, connection refused, 429, 5xx against provider hosts |

Cassette rules:

| Rule | Detail |
|---|---|
| Record only via rake task | Cassettes are created by a dedicated record task against the real sandbox; specs never record |
| Checksummed | Every cassette's hash in `cassettes.lock`; a hand edit fails the checksum |
| Fresh | Re-recorded weekly; no cassette older than 21 days |
| Body-matched | Matching on method, host, path and normalised body; a changed outgoing request misses and fails |
| Secrets filtered | Keys, tokens and PII replaced with placeholders at record time |
| Inbound webhooks | Captured from real sandbox deliveries with original signature headers |

Why cassettes are not hand-written stubs: a stub's response is authored by the test writer; a cassette's every byte was produced by the provider's real system in response to a request our code actually issued. The checksum makes the recording tamper-evident, body matching makes it fail closed when our request changes, and weekly re-recording plus the daily live suite catch provider-side drift. A stub can silently agree with a bug; a cassette cannot be edited to agree with one.

Forbidden constructs (custom RuboCop cops on `operator/spec`):

| Construct | Scope |
|---|---|
| `allow(...).to receive` | everywhere |
| `instance_double`, `class_double` | everywhere |
| `allow_any_instance_of` | everywhere |
| `stub_const` | on Operator or core constants |
| `stub_request` | outside tagged chaos groups |
| Rails fixtures | everywhere (FactoryBot only) |
| `vi.mock` of Operator modules | Vitest, via `lint-js` |

Allowed: `travel_to`, `with_modified_env`.

Approved test dependencies: `vcr`, `prosopite`, `strong_migrations`, Playwright. Any other test dependency needs an ADR.

### Consequences

- Good: green means working against real infrastructure and real provider behaviour.
- Good: provider drift surfaces within a week (re-record) or a day (live suite).
- Bad: slower suites; mitigated by sharding (core 16, Operator 8) and the 20-minute CI budget.
- Bad: sandbox credentials are a prerequisite for each integration (human-created accounts).
- Bad: some edge cases (rare provider errors) are only reachable through chaos groups.

## Confirmation

| Check | CI job |
|---|---|
| Forbidden-construct cops | `lint-ruby`, `lint-js` |
| `cassettes.lock` checksums match; no cassette older than 21 days | `registries` |
| Cassette replay with `record: :none` | `operator-specs` (contracts) |
| Live sandbox suites | provider-live daily |
| Weekly re-record opens a PR | cassette re-record weekly |
| Prosopite raise mode, coverage ratchet | `operator-specs` |
| Full policy | `operator/docs/standards/testing.md` |
