---
status: accepted
date: 2026-10-04
deciders: Operator engineering
---

# 0002. Naming and prefixing

## Context and Problem Statement

Operator lives inside a fork that merges upstream monthly. Every Operator artefact (constant, table, route, flag, queue, translation key, env var, event, JS import, core edit) must be distinguishable from core by name alone, so one grep finds it, upstream merges never collide with it, and audits can enumerate it. What convention applies to each artefact type?

## Decision Drivers

- One grep per artefact type finds every Operator item.
- No collisions with current or future upstream names.
- Conventions checkable mechanically in CI.
- Reuse Rails engine defaults where they exist (`isolate_namespace`).

## Considered Options

1. No prefix; rely on directory location.
2. Prefix Ruby constants and tables only.
3. Prefix every artefact type with a fixed, type-specific scheme.

## Decision Outcome

Chosen option: **3, prefix every artefact type**.

| Artefact | Convention | Example | Notes |
|---|---|---|---|
| Ruby constant | `Operator::<Module>::<Name>` | `Operator::Billing::Gateway` | Core constants written `::Account` inside `module Operator` |
| Seam module | `Operator::Seams::<CoreClass>Ext` | `Operator::Seams::SendReplyJobExt` | Registered only in `operator/lib/operator/seams.rb` (ADR 0001) |
| Table | `operator_*` | `operator_account_flags` | Automatic from `isolate_namespace Operator` |
| Column added to a core table | `operator_*` | `conversations.operator_sla_policy_id` | Column comment carries a data class |
| Route | under `/operator` | `/operator/api/v1/accounts/:id/bootstrap` | Precedence in ADR 0005 |
| Feature flag key | `op_<module>_<name>` | `op_records_pipeline_board` | Registry `operator/config/flags.yml` (ADR 0004) |
| Sidekiq queue | `operator_*` | `operator_ai`, `operator_metering` | Added to `config/sidekiq.yml` (OT-006) |
| Cron source | `source: 'operator'` | | Required by the core sidekiq-cron loader |
| i18n key | `OPERATOR.*` | `OPERATOR.RECORDS.LIST.TITLE` | Namespace spread into the dashboard locale (OT-009) |
| Env var / InstallationConfig key | `OPERATOR_*` | `OPERATOR_REAL_REDIS` | Inventory generated from `Operator::Config` |
| Domain event | `operator.<module>.<past_tense_verb>` | `operator.billing.payment_succeeded` | Past tense only |
| Outbound webhook event | snake_case, accepted by the `Webhook` seam | `record_created` | Listed in the event catalogue |
| JS import alias | `operator/` | `import { useRecords } from 'operator/records/useRecords'` | Vite alias (OT-002) |
| Frontend source dir | `app/javascript/operator/` | | Lazy routes only |
| Core touch marker | `# OPERATOR-TOUCH: OT-NNN` (comment syntax of the file's language) | `# OPERATOR-TOUCH: OT-003` | Logged in `operator/docs/upstream-touches.yml` |
| ADR file | `operator/docs/adr/NNNN-kebab-title.md` | `0004-feature-flag-storage.md` | Numbers never reused |

### Consequences

- Good: one grep for `operator_`, `Operator::` or `OPERATOR` enumerates the footprint; audits and removal are mechanical.
- Good: upstream cannot introduce a colliding name without adopting the prefix.
- Bad: longer names; accepted.
- Bad: two event styles (internal dotted, external snake_case) both need documenting in the event catalogue.

## Confirmation

| Rule | CI job |
|---|---|
| Migrations in `operator/db/migrate` create only `operator_*` tables or `operator_*` columns on core tables | `migrations` |
| Flag keys match `^op_[a-z0-9]+_[a-z0-9_]+$` | `registries` |
| Operator job queues match `^operator_` | `registries` (job catalogue generator) |
| i18n keys used under `app/javascript/operator/` start with `OPERATOR.` | `lint-js` |
| Every `OPERATOR-TOUCH` marker has a matching `upstream-touches.yml` entry and vice versa | touch audit in `architecture` |
| Event names match `^operator\.[a-z_]+\.[a-z_]+$` with a past-tense verb | event registry spec in `registries` |
