---
owner: operator-engineering
last_verified: 2026-10-04
review_every_days: 90
applies_to: ["operator/docs/**"]
status: current
---

# Operator documentation

Operator is a multi-tenant customer-operations platform built as a Rails engine (`operator/`) on a fork of Chatwoot's MIT core. Start with [architecture/overview.md](architecture/overview.md), then the [ADRs](adr/README.md) and [standards](standards/README.md).

## Map

| Path | Contents | State |
|---|---|---|
| `README.md` | this map | present |
| `glossary.md` | Chatwoot and Operator terms | present |
| `upstream-touches.yml` | every core edit (OT-NNN), source of truth for the touch audit | present |
| `architecture/` | overview and C4 diagrams (Mermaid), domain docs per module | overview present |
| `adr/` | MADR decision records and index | 0001 to 0010 present |
| `standards/` | engineering rules with enforcement, Definition of Done | present |
| `generated/` | output of `rake operator:docs:generate`: Seam Register, data dictionary, API reference, event, job, flag, route and config catalogues, dependency list | planned; never hand-edited |
| `runbooks/` | deploy, rollback, restore, upstream merge, scaling, on-call, incident | planned |
| `packs/` | pack authoring guide; one doc per pack (real estate, hospitality, travel) with ERDs and invariants | planned |
| `ai/` | model cards, routing, prompt registry, tool catalogue, guardrails, scorecards, data-processing register | planned |
| `security/` | threat model, data classification, encryption and secrets inventories, incident runbook | planned |
| `compliance/` | NDPA and POPIA register, retention schedule, DSAR runbook, subprocessors | planned |
| `integrations/` | provider guides (payments, SMS, KYC, calendar), channel adapter guide | planned |
| `cleanroom/` | public-source functional spec per parity feature (ADR 0003) | planned; one file before each parity feature starts |
| `product/` | product decisions log, tenant onboarding, plans and billing | planned |
| `postmortems/` | blameless incident reviews | planned |

## Frontmatter contract

Every hand-written doc (not ADRs, not `generated/`) starts with:

```yaml
---
owner: operator-engineering        # team or person accountable
last_verified: 2026-10-04          # ISO date someone confirmed it matches reality
review_every_days: 90              # freshness window
applies_to: ["operator/app/**"]    # globs whose changes may invalidate this doc
status: current                    # current | draft | deprecated
---
```

ADRs use MADR frontmatter (`status`, `date`, `deciders`); see [adr/README.md](adr/README.md).

## How docs stay live

| Mechanism | Behaviour | State |
|---|---|---|
| Generators | `rake operator:docs:generate` writes `generated/`; CI fails on any diff | planned (foundation) |
| References spec | Fails when a doc names a path, constant, rake task, env var or ADR that does not exist, or when a Mermaid block fails to parse. Paths not yet built are written with "(planned)" | planned (foundation) |
| Docs impact | `operator/bin/docs_impact` fails a PR whose diff matches a doc's `applies_to` globs without updating that doc, unless the PR body declares "no docs impact" with a reason | planned (foundation) |
| Freshness | A doc past `last_verified + review_every_days` fails PRs touching its globs; a monthly report opens an issue | planned (foundation) |
| Drills | Runbook drills bump `last_verified` | planned |
| Site | VitePress site built from `operator/docs`, deployed on every merge behind deployment protection; only the public developer portal is exposed | planned (foundation) |
