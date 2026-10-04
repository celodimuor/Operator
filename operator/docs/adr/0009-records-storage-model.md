---
status: accepted
date: 2026-10-04
deciders: Operator engineering
---

# 0009. Records storage model

## Context and Problem Statement

Industry packs (real estate, hospitality, travel) need custom object types such as Property, Listing, Viewing, Reservation, Trip and Payment, with pipelines, money, dates, locations, relations to contacts, conversations, users and other records, full-text search, filters, import and export, and AI tool access. Each tenant may install several packs and extend their types. How are custom objects stored?

## Decision Drivers

- Relations between records and to core entities.
- Exact money handling.
- Filterable, sortable and searchable at 1 million records under tenant scoping.
- Schema evolution per object type without per-tenant DDL.
- Server-side validation; schemas reusable as AI tool schemas.

## Considered Options

1. Extend core `CustomAttributeDefinition` / `custom_attributes`.
2. Pure EAV (entity, attribute, value rows).
3. Per-tenant DDL (a real table per object type per tenant).
4. Hybrid: typed columns for cross-pack primitives, jsonb for the rest validated by versioned JSON Schema, side tables for indexed values and links.

## Decision Outcome

Chosen option: **4, hybrid**.

| Table | Content |
|---|---|
| `operator_object_types` | per account: key, name, current schema version, pack origin |
| `operator_object_fields` | field definitions per type, compiled to a versioned JSON Schema |
| `operator_records` | `account_id`, `object_type_id`, typed columns `title`, `stage`, `owner`, `amount_cents` plus `currency`, `due_at`, `geo`, search `tsvector`, plus `data jsonb` validated by the type's JSON Schema version |
| `operator_record_values` | denormalised typed values for fields marked indexed (filters and sorts) |
| `operator_record_links` | relations to contacts, companies, conversations, users and other records |
| Pipelines, stages, activities, files | dedicated `operator_*` tables (Workstream E) |

| Rule | Detail |
|---|---|
| Money | Always `amount_cents` integer plus ISO currency; never in jsonb |
| Validation | JSON Schema validated server-side on every write, against the version stamped on the record |
| Filters | Filter DSL compiled to SQL over typed columns and `operator_record_values` |
| Authorisation | Pundit policy per object type |
| Packs | Manifests installed idempotently and versioned |

Rejected:

| Option | Reason |
|---|---|
| Extend `CustomAttributeDefinition` | Flat scalars on contacts and conversations only; no relations, no object types, no money, no pipelines; changes would be core edits |
| Pure EAV | Every read is a pivot; no type safety; poor index use at volume |
| Per-tenant DDL | Migrations per tenant, schema-cache churn, breaks `strong_migrations` discipline and the single-schema tenancy model (ADR 0006) |

### Consequences

- Good: common primitives are indexed, typed and comparable across packs.
- Good: schema changes per type are data, not migrations.
- Good: JSON Schemas double as AI tool parameter schemas.
- Bad: indexed values are duplicated into `operator_record_values` and must stay consistent (written in the same transaction).
- Bad: schema versioning and migration of existing `data` between versions must be handled by batched jobs.

## Confirmation

| Check | CI job |
|---|---|
| No money-like keys (`amount`, `price`, `*_cents`) in object field definitions of type other than the typed money column | `operator-specs` (records) |
| Every write validated; invalid `data` rejected at model and API layers | `operator-specs` |
| Filter queries use indexes at the large shape | nightly EXPLAIN checks |
| Records tables carry `account_id` leading indexes | `migrations` |
| Generated ERD for the records module matches schema | `docs` |
