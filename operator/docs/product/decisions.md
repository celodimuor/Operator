---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["operator/docs/product/**"]
status: current
---

# Product decisions

Append-only log of product scope decisions (technical decisions live in [ADRs](../adr/README.md)). Rules:

- Entries are numbered `PD-NNN` in order and never deleted or rewritten. Only the `Status` line may change.
- To change a decision, append a new entry that supersedes it and set the old entry's status to `superseded by PD-NNN`.
- A product scope change is a human decision (see PD-012); record it here and in `operator/STATUS.md`.
- Status values: `accepted`, `superseded by PD-NNN`, `withdrawn`.

## PD-001 Build on a Chatwoot fork named Operator

- Date: 2026-10-03
- Decision: Build the product as a fork of Chatwoot's MIT core, named Operator, with all product code in a Rails engine under `operator/`.
- Rationale: Chatwoot supplies a healthy omnichannel core (WhatsApp Cloud API, email, widget, automation, help centre, mobile app) and a monthly release cadence. Building from scratch would spend months on commodity inbox features. The fork precedent shows isolation in an overlay keeps upstream merges small.
- Consequences: Operator inherits upstream's release cadence and must merge it (see the [upstream merge runbook](../runbooks/upstream-merge.md)); core edits are one-line logged touches ([ADR 0001](../adr/0001-extension-mechanism.md)); Chatwoot's trademark is not used for the product.
- Status: accepted

## PD-002 No Chatwoot enterprise licence, ever; rebuild parity clean-room

- Date: 2026-10-03
- Decision: Operator never buys, uses or depends on a Chatwoot enterprise licence, for SaaS or self-hosted deployments. Enterprise-equivalent features (audit logs, roles, SLA, capacity, SSO and others) are rebuilt from public sources only.
- Rationale: The enterprise licence needs a paid subscription for production use and claims modifications, which is incompatible with reselling the product. Functionality is not protected by the licence; independent expression written from public descriptions is.
- Consequences: `enterprise/` and `spec/enterprise/` are deleted and re-deleted on every upstream merge; every parity feature starts from a public-source spec in `operator/docs/cleanroom/`; parity takes longer than porting. Policy: [ADR 0003](../adr/0003-clean-room-policy.md); template: [clean-room README](../cleanroom/README.md). Legal review of the policy is open (see Open decisions).
- Status: accepted

## PD-003 Resell commercially, Africa first, then similar markets globally

- Date: 2026-10-03
- Decision: Operator is a commercial, resellable product, not only HEYCH's internal tool. Go to market in Africa first, then similar markets globally.
- Rationale: Chatwoot lacks everything vertical and everything African: local SMS providers, USSD, mobile money, local languages, KYC. That gap is the product opportunity, and similar markets share the same needs.
- Consequences: First-party Africa integrations (SMS aggregators, USSD, mobile money, KYC) and local locales are in scope; tenant billing, plans, white-label and a super-admin console are required; HEYCH is one tenant among many.
- Status: accepted

## PD-004 SaaS first, self-hosted licensing later

- Date: 2026-10-03
- Decision: Ship a hosted SaaS first. Self-hosted licensing is deferred to v2.
- Rationale: SaaS lets us control the environment, billing, upgrades and data residency, and avoids building licence enforcement before there is a customer base.
- Consequences: No licence-key or offline-activation work in v1; the Operator Docker image and migrations still must work outside our infrastructure so the later option stays open.
- Status: accepted

## PD-005 Launch market Nigeria, hosted in AWS af-south-1

- Date: 2026-10-03
- Decision: Nigeria is the launch market. Production is hosted in AWS af-south-1 (Cape Town).
- Rationale: Nigeria is a large, WhatsApp-heavy market with a clear fit for the first vertical; af-south-1 is the closest AWS region and keeps latency and data residency defensible for NDPA obligations.
- Consequences: NGN billing first (Paystack, Flutterwave fallback), Nigerian languages (Pidgin, Hausa, Yoruba, Igbo), NDPA compliance register and data-region tagging; Terraform targets af-south-1; a second region is v2.
- Status: accepted

## PD-006 Industry pack order: real estate, hospitality, travel

- Date: 2026-10-03
- Decision: Build vertical packs in this order: real estate first, hospitality second, travel third, then others.
- Rationale: Real estate is the design-partner vertical and exercises the most reusable primitives (listings, viewings, payments, documents, KYC); hospitality and travel reuse them with different invariants.
- Consequences: The records engine is shaped by real estate first; hospitality arrives in v1.x and travel in v2; no work on later packs competes with the first.
- Status: accepted

## PD-007 LLMs through Vercel AI Gateway with per-task model routing

- Date: 2026-10-03
- Decision: All LLM calls go through Vercel AI Gateway, routed per task (customer turns, extraction, copilot, translation, judge, embeddings) from configuration with tenant overrides.
- Rationale: One endpoint gives provider portability, failover and cost tracking without provider branching in code; routing per task keeps cost and quality balanced.
- Consequences: Spend caps and per-run cost are persisted; model ids are confirmed against the gateway catalogue; AI spend above 150 percent of budget is an escalation. Design: [ADR 0008](../adr/0008-ai-runtime.md).
- Status: accepted

## PD-008 Multi-tenancy from day one

- Date: 2026-10-03
- Decision: Every feature is multi-tenant from the first line. Core `Account` is the tenant and every Operator table carries `account_id NOT NULL`.
- Rationale: Retrofitting tenancy into a resold product is slower and riskier than starting with it, and cross-tenant leakage is the worst failure a reseller can have.
- Consequences: Pundit scoping on every endpoint, a generated cross-tenant test matrix in CI, and no features that assume a single customer. Design: [ADR 0006](../adr/0006-tenancy-model.md).
- Status: accepted

## PD-009 Autonomous delivery: CI is the only merge gate

- Date: 2026-10-03
- Decision: Work is delivered autonomously by agents. CI is the only merge gate: required checks plus an automated reviewer-agent check on the head SHA. No human approves merges, including upstream merges.
- Rationale: The owner is a single human lead; human approval would be the bottleneck and a rubber stamp. Quality is enforced by tests, architecture guards, budgets and the independent reviewer agent rather than by a person reading diffs.
- Consequences: CI must be strict and never weakened to pass; docs, specs and runbooks are mandatory so the system is operable without tribal knowledge; the human is pulled in only by the escalation list (PD-012).
- Status: accepted

## PD-010 Nothing-stubbed testing

- Date: 2026-10-03
- Decision: Tests run real Operator code against real PostgreSQL, Redis, Sidekiq, ActionCable, ActiveStorage and browsers. External providers are exercised through official sandboxes or recorded real traffic; mocks and stubs of Operator or core code are forbidden.
- Rationale: With no human reviewer, tests must prove the product works in its real shape; stubbed tests prove only that the stubs agree with the code.
- Consequences: Slower, heavier CI, custom lint cops for the policy, checksummed cassettes re-recorded weekly. Policy: [ADR 0010](../adr/0010-testing-policy.md).
- Status: accepted

## PD-011 Living documentation

- Date: 2026-10-04
- Decision: Documentation is a deliverable kept live by tooling: generated docs regenerated in CI, frontmatter with owners and review windows, docs-impact checks on PRs, references checks, and runbook drills.
- Rationale: Agents and the single human lead rely on docs as the system of record; stale docs cause wrong changes.
- Consequences: Every change updates the docs whose `applies_to` globs it touches and bumps `last_verified`; stale docs fail PRs touching their globs. Mechanism: [docs README](../README.md).
- Status: accepted

## PD-012 Escalation list for human decisions

- Date: 2026-10-04
- Decision: Agents stop and ask the human only for: legal or licence questions; terms or privacy text; any new paid service; AI spend above 150 percent of budget or infrastructure cost up more than 15 percent in a month; destructive production data operations; creating external accounts or OAuth grants; customer-visible pricing; a Sev1 incident; an upstream licence change; a fix that needs core touches beyond budget; a product scope change.
- Rationale: Everything else is covered by CI and the charter; these items are irreversible, financial, legal or reputational.
- Consequences: Each escalation is an issue labelled `needs-human` plus a line in `operator/STATUS.md`; the work continues on everything not blocked. Source: `operator/AGENTS.md`.
- Status: accepted

## Open decisions

Pending human decisions. When one is made, append a `PD-NNN` entry and set its row to `decided (PD-NNN)`.

| ID | Decision | Options | Recommendation | Blocks | Raised | Status |
|---|---|---|---|---|---|---|
| OD-1 | Public fork versus private repository | Keep the public fork; or a fresh private repository with all refs pushed and `upstream` kept as a remote (GitHub cannot make a fork private) | Private, decided before product code lands | Operator product code landing in the repository | 2026-10-04 | open |
| OD-2 | Brand assets | Operator logo (light, dark, thumbnail) and brand URLs; until provided the installation and brand name read "Operator" and the logo files are still Chatwoot's defaults | Provide the assets before any tenant sees the product | Branded dashboard, widget and emails for design partners | 2026-10-04 | open |
| OD-3 | Provider accounts | Create: AWS, Meta Business (WhatsApp test numbers), Paystack and Flutterwave test mode, Termii and Africa's Talking sandboxes, Smile ID and Dojah sandboxes, Vercel AI Gateway key and budget, Resend domain, Sentry, Langfuse | Open in the order the roadmap needs them; each is a paid or external account, so human only | Staging environment, provider contract tests, live sandbox suites | 2026-10-04 | open |
| OD-4 | Legal review | Review the clean-room policy ([ADR 0003](../adr/0003-clean-room-policy.md)), NDPA disclosures, and terms and privacy text | Engage counsel before the first paying tenant and before the policy is relied on commercially | Customer-facing terms, general availability | 2026-10-04 | open |
