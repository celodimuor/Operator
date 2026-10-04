---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["operator/**", "app/javascript/operator/**", ".claude/**"]
status: current
---

# Security standard

| Area | Rule | Enforcement |
|---|---|---|
| Clean room | No enterprise source read, copied or referenced (ADR 0003) | clean-room guard in `architecture` |
| Secrets storage | Production secrets in AWS Secrets Manager only; never in repo, env files or jsonb | gitleaks in `security-static` |
| Provider secrets | `Channel::Sms`, `Channel::Whatsapp`, `Integrations::Hook` secrets in `provider_secrets` text column (`serialize` JSON plus `encrypts`); getter injects into the same hash; `before_save` strips them back out | DB-level spec asserting no secret key lands in jsonb |
| Encryption at rest | Rails `encrypts` on string/text columns holding authorisation codes, BYOK keys, passport data, KYC results | encryption inventory (generated), review |
| Inbound signatures | Every webhook verifies its signature over the raw body; `Twilio::CallbackController` (`X-Twilio-Signature`) and `Webhooks::SmsController` (Bandwidth) gain verification seams | `operator-specs` |
| Webhook replay | `operator_inbound_events(provider, event_id)` unique | `operator-specs` |
| Outbound HTTP | Only through `Operator::Http::SafeClient` (SSRF protection, timeouts) for tenant-supplied URLs and AI HTTP tools | boundary spec, review |
| Tenancy | Cross-tenant matrix on every PR (ADR 0006) | `operator-specs` (tenancy) |
| Authorisation | Pundit on every action | authz route spec |
| Bot protection | Cloudflare Turnstile on signup, widget and portal forms | E2E, review |
| Rate limits | Per tenant in all environments | `operator-specs` |
| Identity | Super-admin MFA mandatory; MFA available as an entitlement | `operator-specs` |
| Audit | Console mutations and token API calls audited | `operator-specs` |
| PII in AI | Redacted before persistence or trace | `operator-specs` (AI), red-team suite |
| Payments and KYC | Hosted checkout only; KYC results minimal, encrypted, short retention | review, retention spec |
| Data classes | Every column comment carries a data class | `migrations` |
| Static analysis | Brakeman with baseline, bundle-audit, pnpm audit, gitleaks | `security-static` |
| Dynamic analysis | OWASP ZAP and trivy | security weekly |
| Review gate | Security reviewer agent approval for PRs touching auth, identity, billing, webhooks, encryption, PII columns, the safe HTTP client or policies | `review-gate` |
| Backups | 35-day PITR, cross-account snapshot copies, quarterly restore drill (RPO 5 min, RTO 60 min) | restore drill runbook (planned) |
| Escalation | Sev1 incidents, legal or licence questions, destructive production data operations go to the human lead | `operator/AGENTS.md` (planned) |
