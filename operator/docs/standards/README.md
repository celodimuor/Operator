---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["operator/**", "app/javascript/operator/**"]
status: current
---

# Operator engineering standards

Rules here are binding for every change under `operator/` and `app/javascript/operator/`. Each rule names its enforcement. "Review" means the reviewer-agent checklist; everything else is a CI job in `op-ci.yml` (planned). Where a standard and an ADR disagree, the ADR wins and the standard is fixed in the same PR.

| Standard | Covers |
|---|---|
| [ruby.md](ruby.md) | bounded contexts, services, results, jobs, webhooks, transactions, migrations, seams |
| [vue.md](vue.md) | components, state, styling, routes, accessibility, i18n |
| [api.md](api.md) | OpenAPI first, pagination, errors, idempotency, rate limits, authorisation |
| [security.md](security.md) | secrets, encryption, webhook signatures, tenancy, review gates |
| [performance.md](performance.md) | N+1, query plans, SLOs, load tests, bundle size |
| [observability.md](observability.md) | logs, spans, metrics, dashboards, alerts, cost |
| [flags.md](flags.md) | flag registry, lifecycle, gating |
| [bloat.md](bloat.md) | dependencies, duplication, deletion, hygiene |
| [testing.md](testing.md) | full testing policy (ADR 0010) |

## Definition of Done

A PR merges only when every item holds. The review-gate job checks the PR body checklist; the other jobs check the substance.

| # | Item | Enforcement |
|---|---|---|
| 1 | Spec or ADR referenced in the PR body | `pr-hygiene` |
| 2 | Red-green-refactor with nothing stubbed | `lint-ruby` / `lint-js` no-stub cops, review |
| 3 | OpenAPI updated and Skooma-validated | `api-contract`, `operator-specs` (contracts) |
| 4 | Cross-tenant matrix passes | `operator-specs` (tenancy) |
| 5 | Pundit policy and policy spec for every new action | authz route spec in `operator-specs` |
| 6 | Reversible migration with column comments (data class) | `migrations` |
| 7 | Idempotent jobs and webhooks | `sidekiq-cable-real`, review |
| 8 | Logs, spans, metrics, dashboard and alert for new behaviour | review, `docs` (job and event catalogues) |
| 9 | Flag registered with a removal date | `registries` |
| 10 | Generated docs regenerated; hand-written docs bumped | `docs` (generate diff, docs impact, references) |
| 11 | No new dependency without an ADR | dependency guard in `architecture` |
| 12 | Seam register and touch register updated | `docs`, touch audit in `architecture` |
| 13 | Conventional-commit title | `pr-hygiene` |
| 14 | Reviewer-agent approval on the head SHA (plus security reviewer for auth, identity, billing, webhooks, encryption, PII columns, safe HTTP client, policies) | `review-gate` |
| 15 | All checks green | branch protection, merge queue |
