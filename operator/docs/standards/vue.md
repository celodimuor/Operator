---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["app/javascript/operator/**", "app/javascript/entrypoints/operator_console.js"]
status: current
---

# Vue standard

| Area | Rule | Enforcement |
|---|---|---|
| Location | Source under `app/javascript/operator/`, imported through the `operator/` alias (OT-002) | `lint-js` |
| API style | Composition API with `<script setup>`; no Options API | `lint-js` |
| Components | Build on core `components-next`; reuse before creating | review, jscpd |
| Size | Single-file component at most 250 lines | `lint-js` |
| State | Pinia through the thin Operator store helper; per-account bootstrap from `/operator/api/v1/accounts/:id/bootstrap`; install config from `window.globalConfig` | review |
| Styling | Tailwind only; no scoped CSS or inline styles beyond dynamic values. Tailwind content glob covers `app/javascript/operator/**` (OT-002) | `lint-js`, `build` |
| Routes | Every route lazy (`() => import(...)`); spread into core route files (OT-007) | `lint-js`, size-limit in `build` |
| Route guards | Every route declares `meta.permissions` and a `beforeEnter` that checks its `op_*` flag; core `routeHelpers.js` enforces only permissions | route spec, review |
| Sidebar | Added through one composable spread (OT-008); no other edits to `Sidebar.vue` | touch audit |
| Core insertion points | One tag or entry per site (OT-010); editor insertion via `BUS_EVENTS.INSERT_INTO_RICH_EDITOR` | touch audit |
| i18n | All strings under `OPERATOR.*`, English source in Operator locale files spread into the dashboard locale (OT-009); no hard-coded copy | `lint-js` |
| Accessibility | WCAG 2.2 AA; axe runs on every page in E2E | `e2e-smoke` |
| Testing | Vitest with real components and real Pinia; `vi.mock` of Operator modules forbidden | `lint-js`, `frontend-unit` (80 percent coverage) |
| Bundle | Lazy chunks; widget size budget enforced | size-limit in `build` |
| Console | Operator Console uses its own entrypoint `entrypoints/operator_console.js` (auto-discovered by Vite); `superadmin_pages.js` untouched | touch audit |
