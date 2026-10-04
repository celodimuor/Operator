---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["operator/docs/**"]
status: current
---

# Glossary

| Term | Origin | Meaning |
|---|---|---|
| Account | Chatwoot | Core `::Account` model; the top-level workspace owning inboxes, conversations, contacts and users |
| Tenant | Operator | One customer organisation of Operator. Always exactly one core `Account` (ADR 0006) |
| Account user | Chatwoot | `AccountUser`: membership of a user in an account with a role; Operator roles attach via `operator_role_id` |
| Agent | Chatwoot | A human user who handles conversations |
| Inbox | Chatwoot | A configured entry point for messages, bound to one channel (for example one WhatsApp number) |
| Channel | Chatwoot | The transport behind an inbox (`Channel::Whatsapp`, `Channel::Sms`, `Channel::Email`, `Channel::WebWidget`, ...). Operator adds providers to `Channel::Sms` and later `Channel::OperatorUssd` |
| Conversation | Chatwoot | A thread between a contact and the account within one inbox, with status (open, pending, resolved, snoozed), assignee and messages |
| Contact | Chatwoot | An end customer known to the account |
| Agent bot | Chatwoot | `AgentBot`: an automated participant attached to an inbox. Core type `webhook`; Operator adds `operator_ai` (OT-003) for Operator AI assistants |
| Assistant | Operator | An Operator AI configuration (prompts, tools, knowledge, playbooks) exposed through an `operator_ai` agent bot |
| Copilot | Operator | The agent-side AI side panel for drafting, summarising, translating and querying |
| Playbook | Operator | A Ruby state machine (for example collect, quote, hold, pay, confirm) that drives a multi-step AI flow; the model fills slots and proposes proceed, clarify or abort |
| Approval | Operator | A human decision required before a `needs_approval` tool runs; expires to handoff after 30 minutes |
| Seam | Operator | A `prepend` of an `Operator::Seams::<CoreClass>Ext` module onto a core class, registered in `operator/lib/operator/seams.rb` and guarded by a spec (ADR 0001) |
| Seam Register | Operator | Generated table of all seams, their targets and guard specs |
| Core touch | Operator | A one-line edit to a core file that a seam cannot achieve, marked `OPERATOR-TOUCH: OT-NNN` and logged in `upstream-touches.yml`; budget 12 files |
| Tombstone route | Operator | A prepended route returning 404 for an ungated enterprise-only core path (ADR 0005) |
| Clean room | Operator | The policy that enterprise source is never read; parity features start from public-source specs in `cleanroom/` (ADR 0003) |
| Parity feature | Operator | An Operator-built equivalent of a Chatwoot enterprise capability (audit logs, roles, SLA, capacity, SSO, ...) with its own tables and screens |
| Record | Operator | An instance of a custom object type in the Records engine (`operator_records`), for example a Property or Reservation (ADR 0009) |
| Object type | Operator | The definition of a kind of record with fields compiled to a versioned JSON Schema |
| Pack | Operator | A versioned, idempotently installed manifest of object types, pipelines, playbooks, tools and integrations for an industry or market (real estate, hospitality, travel, Africa) |
| Plan | Operator | A priced subscription tier defined in `operator/config/plans.yml` |
| Entitlement | Operator | A capability or limit a tenant has paid for; materialised from plan plus add-ons plus overrides in `operator_entitlements`; drives core `usage_limits` |
| Flag | Operator | A release, ops or experiment switch per account in `operator_account_flags`, key `op_<module>_<name>`, with an expiry in `flags.yml` (ADR 0004). Not an entitlement |
| Core feature flag | Chatwoot | A bit in the account's feature bitset defined in `config/features.yml` |
| Gateway (billing) | Operator | `Operator::Billing::Gateway` port with Paystack, Flutterwave and Stripe adapters (ADR 0007) |
| AI Gateway | Vercel | The OpenAI-compatible endpoint `https://ai-gateway.vercel.sh/v1` through which all model calls go (ADR 0008) |
| BYOK | Operator | Bring your own key: a tenant-supplied gateway key, stored encrypted |
| Inbound event | Operator | A provider webhook persisted in `operator_inbound_events` with a unique `(provider, event_id)` for idempotency |
| Cassette | Testing | A VCR recording of real provider sandbox traffic, checksummed in `cassettes.lock`, re-recorded weekly; replayed in PR CI (ADR 0010) |
| Chaos group | Testing | A tagged spec group that may inject HTTP faults (timeouts, 429, 5xx) with WebMock |
| Large shape | Testing | The nightly seed: 500 accounts, 2 million conversations, 20 million messages, 1 million records |
| Upstream | Delivery | `chatwoot/chatwoot`, merged into the fork via `operator/bin/upstream_merge` |
| OT-NNN | Delivery | Identifier of a core touch |
