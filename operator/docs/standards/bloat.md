---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["operator/**", "app/javascript/operator/**", "Gemfile.lock", "package.json", "pnpm-lock.yaml"]
status: current
---

# Bloat standard

| Rule | Enforcement |
|---|---|
| New dependency (gem, npm package, external service) requires an ADR and a licence check | dependency guard in `architecture` |
| Generated dependency list links each dependency to its ADR | `docs` |
| Duplication threshold 1 percent | jscpd in `architecture` |
| Delete what you replace in the same PR | review |
| No speculative abstraction: a base class, port or module needs two implementations | review |
| No dead code: unused classes, methods, routes, i18n keys, flags removed | monthly hygiene (knip, debride, unused keys, routes, flags) |
| Stale docs flagged and fixed or deleted | freshness check, monthly report |
| Core touch budget: 12 non-mechanical files, one line each | touch audit in `architecture` |
| Frontend size budget per entrypoint and for the widget | size-limit in `build` |
| Seams at most 30 lines; services at most 100; classes 200; methods 15; SFC 250 | `lint-ruby`, `lint-js` |
| Never weaken a check to make CI pass | `review-gate` |
