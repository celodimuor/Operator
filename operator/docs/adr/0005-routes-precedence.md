---
status: accepted
date: 2026-10-04
deciders: Operator engineering
---

# 0005. Routes precedence

## Context and Problem Statement

Operator adds controllers, APIs, webhooks and console pages. Core `config/routes.rb` must not be edited (merge cost) and core routes must keep their meaning. After `enterprise/` is deleted (ADR 0003), core `config/routes.rb` still declares several routes whose controllers exist only in the enterprise tree and are not gated by `ChatwootApp.enterprise?`; a request to them would raise at request time (uninitialised constant) instead of returning a clean 404. How are Operator routes added and how are those dangling routes neutralised?

## Decision Drivers

- No edits to `config/routes.rb`.
- Core routes always win over Operator routes.
- Dangling enterprise routes must return 404, not 500.
- Route drift on upstream merge must be detected.

## Considered Options

1. Edit `config/routes.rb` to add Operator routes and remove enterprise routes.
2. `Rails.application.routes.prepend` for all Operator routes.
3. `Rails.application.routes.append` plus engine mount for Operator routes, and one documented `routes.prepend` block of tombstones.

## Decision Outcome

Chosen option: **3**.

| Rule | Detail |
|---|---|
| Operator routes | Only under `/operator`, through `Operator::Engine` mounted by `Rails.application.routes.append` from an engine initializer |
| Precedence | Core routes match first; Operator never shadows a core path |
| Exception | One `Rails.application.routes.prepend` block that maps the nine ungated enterprise-only paths below to a 404 tombstone |
| No other prepends | Any further `routes.prepend` requires a new ADR |

Tombstoned paths (in core `config/routes.rb` as of upstream `843385ff3a`):

| # | Core route | Scope |
|---|---|---|
| 1 | `namespace :captain` | Everything in the namespace except `preferences` and `tasks`, which are MIT |
| 2 | `resource :saml_settings` | Account-scoped |
| 3 | `resource :audit_logs` | Account-scoped |
| 4 | `resources :sla_policies` | Account-scoped |
| 5 | `resources :custom_roles` | Account-scoped |
| 6 | `resources :agent_capacity_policies` (and nested) | Account-scoped |
| 7 | `resources :applied_slas` (and nested) | Account-scoped |
| 8 | `post 'auth/saml_login'` | Auth |
| 9 | `get '.well-known/cf-custom-hostname-challenge/:id'` | Public |

Operator's parity features (audit logs, roles, SLA, capacity, SSO, custom domains) are served under `/operator` with their own controllers; they do not reclaim the tombstoned paths.

### Consequences

- Good: zero edits to `config/routes.rb`; upstream route changes merge cleanly.
- Good: dangling enterprise paths return 404 deterministically.
- Bad: the tombstone list must track upstream; mitigated by the route guard spec.
- Bad: the frontend's MIT screens for these features may still link to tombstoned APIs; they are gated by router metadata and stay hidden.

## Confirmation

| Check | CI job |
|---|---|
| Route guard spec snapshots core routes (verb, path, controller#action); any upstream change fails until the snapshot and tombstone list are reviewed | `operator-specs` (seams) and upstream merge gate |
| Each tombstoned path returns 404 | `operator-specs` request spec |
| No Operator route outside `/operator` except the tombstone block | route guard spec |
| Routes and permission matrix regenerated with no diff | `docs` |
