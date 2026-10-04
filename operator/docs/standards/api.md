---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["operator/app/controllers/**", "operator/swagger/**", "operator/config/routes.rb"]
status: current
---

# API standard

| Area | Rule | Enforcement |
|---|---|---|
| Design order | OpenAPI first: update `operator/swagger/openapi.json` (OpenAPI 3.1) before the controller | `api-contract` |
| Contract | Request and response validated by Skooma in request specs | `operator-specs` (contracts) |
| Breaking changes | Detected by `oasdiff`; a breaking change needs a new version path | `api-contract` |
| Paths | Under `/operator`; account-scoped resources under `/operator/api/v1/accounts/:account_id/...` | route guard spec |
| Pagination | Cursor-based (opaque cursor, `limit`); no offset pagination on Operator endpoints | `api-contract` lint, review |
| Errors | RFC 9457 problem responses (`application/problem+json` with `type`, `title`, `status`, `detail`, plus an Operator error code) | Skooma, review |
| Idempotency | `Idempotency-Key` required on money-moving and message-creating endpoints; stored in `operator_idempotency_keys` (account, key, request hash, response, 24 hour expiry); same key with a different body is rejected | `operator-specs` |
| Rate limits | Per token and per account, in all environments | `operator-specs` |
| Authorisation | Pundit on every action, `verify_authorized` and `verify_policy_scoped` | authz route spec |
| Tenancy | Account resolved from path and the user's `AccountUser`; another tenant's ids return 404 or 403 and leak no ids | cross-tenant matrix |
| Audit | Every token API call logged to `operator_api_audit_logs`; every console mutation to `operator_console_audit_logs` | `operator-specs` |
| Webhooks out | Event names accepted by the `Webhook` seam (`record_created`, `record_updated`, `record_stage_changed`, `payment_succeeded`, `approval_requested`); payloads documented in the event catalogue | registry spec |
| Reference | Rendered API reference generated from the bundled OpenAPI file | `docs` |
