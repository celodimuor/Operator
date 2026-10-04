---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["operator/config/flags.yml", "operator/app/**", "app/javascript/operator/**"]
status: current
---

# Flags standard

Storage and rationale: ADR 0004.

| Rule | Enforcement |
|---|---|
| Every flag declared in `operator/config/flags.yml` with `type` (`release` \| `ops` \| `experiment`), `owner`, `created`, `remove_by` | `registries` |
| Key format `op_<module>_<name>` | `registries` |
| Values stored in `operator_account_flags(account_id, key, enabled, updated_by)` | schema |
| Flags reach core gating through the `Account#all_features` seam; never add Operator keys to core `config/features.yml` | touch audit, review |
| A flag past `remove_by` fails CI | `registries` |
| Every key referenced in code exists in the registry; every registry key is referenced | `registries` |
| Release flags guard dark launches; removal of the flag and its dead branch happens in one PR | review |
| Flags never grant paid capability; plan features are entitlements (`operator_entitlements`) | review |
| Every Operator Vue route checks its flag in `beforeEnter` | route spec |
| Flag changes record `updated_by`; console flips are audited | `operator-specs` |
| Generated flag registry doc lists core and Operator flags | `docs` |
| Monthly hygiene sweep lists unused flags | monthly hygiene |
