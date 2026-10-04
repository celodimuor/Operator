---
status: accepted
date: 2026-10-04
deciders: Operator engineering
---

# 0004. Feature flag storage

## Context and Problem Statement

Operator needs per-account release, ops and experiment flags that core UI gating also honours. Core stores account features as bit flags defined in `config/features.yml` and exposes them through `Featurable#all_features`, `enabled_features`, `feature_enabled?` and the `_account.json.jbuilder` serialiser, which the frontend reads as `account.features[key]`. Where do Operator flags live, and how do they reach core gating?

## Decision Drivers

- Flags must be removable; every flag has an expiry.
- No collision with upstream on merge.
- Core gating (`account.features[key]`, sidebar, `usePolicy`) must work for Operator flags without core edits.
- Flags and commercial entitlements must not be conflated.
- Changes are audited (who flipped what).

## Considered Options

1. Append Operator flags to core `config/features.yml`.
2. A third-party flag service.
3. Own table plus YAML registry, merged into `all_features` by a seam.

## Decision Outcome

Chosen option: **3**.

| Element | Definition |
|---|---|
| Table | `operator_account_flags(account_id NOT NULL, key, enabled, updated_by)`, unique on `(account_id, key)` |
| Registry | `operator/config/flags.yml`: per key `type` (`release` \| `ops` \| `experiment`), `owner`, `created`, `remove_by` |
| Key format | `op_<module>_<name>` (ADR 0002) |
| Core integration | `Operator::Seams::AccountExt` overrides `all_features` to return `super` merged with the account's Operator flags; `enabled_features`, `feature_enabled?` and the account JSON derive from it with no further override |
| Unknown keys | Rows whose key is absent from `flags.yml` are ignored and reported |
| Entitlements | Plan features live in `operator_entitlements` (materialised plan plus add-ons plus overrides), never in flags. Reconciliation may set flags but flags never grant paid capability |
| Frontend gating | Every Operator route declares `permissions` and a `beforeEnter` that checks the flag, because core `routeHelpers.js` enforces only `meta.permissions` |

Why not core `features.yml`:

| Problem | Detail |
|---|---|
| Positional bits | Bit position is the list index; meaning depends on order |
| Append-only | Removing or reordering an entry shifts every later bit and corrupts stored values |
| Merge collision | Upstream appends to the same list; any Operator entry conflicts and can swap meaning with an upstream flag |
| Not removable | Expired flags cannot be deleted, violating the flag lifecycle |

A third-party service adds a paid dependency and a network hop to every gating check, with no gain over a table.

### Consequences

- Good: flags are string keys, removable, auditable (`updated_by`), tenant-scoped.
- Good: core UI gating works for Operator flags through one seam.
- Good: expiry is enforced mechanically.
- Bad: `all_features` gains one query per account load; mitigated by preloading or caching per request.
- Bad: two flag stores exist (core bits, Operator rows); the generated flag registry doc lists both.

## Confirmation

| Check | CI job |
|---|---|
| Every key used in code exists in `flags.yml` and vice versa | `registries` |
| Any flag past `remove_by` fails CI | `registries` |
| Key format and required fields validated | `registries` |
| Guard spec: `Account#all_features` includes an Operator flag row and `account.features` JSON exposes it | `operator-specs` (seams) |
| Flag registry doc regenerated with no diff | `docs` |
