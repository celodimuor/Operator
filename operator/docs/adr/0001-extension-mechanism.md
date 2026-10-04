---
status: accepted
date: 2026-10-04
deciders: Operator engineering
---

# 0001. Extension mechanism: isolated Rails engine with an explicit seam registry

## Context and Problem Statement

Operator adds tenancy, billing, AI, records, industry packs, Africa integrations and clean-room enterprise parity on top of Chatwoot's MIT core. Chatwoot ships a minor release every month. A previous fork without isolation hit 67 conflicted files on one release; with an overlay it hit zero. We need a way to add a large amount of code and change a small number of core behaviours while keeping upstream merges near conflict-free and every dependency on core visible in one place.

How should Operator code be loaded, routed and wired into core behaviour?

## Decision Drivers

- Upstream merges within 7 days of a minor release and 48 hours of a security release.
- Core touch budget of 12 non-mechanical files, each change one line (`operator/docs/upstream-touches.yml`).
- One source of truth for every core class Operator depends on, so the Seam Register is generated and guarded.
- Coverage of core classes that have no injector hook (`AgentBotListener`, `Channel::Sms`, `DashboardController`, `HookListener`, `Llm::Config`).
- The `Operator::` namespace stays free for product models.
- Clean room: no reliance on `enterprise/` conventions (ADR 0003).

## Considered Options

1. `ChatwootApp.extensions` and `prepend_mod_with` with a `custom/` directory.
2. Patch `config/application.rb` (or a `boot.rb` hook) to add Operator load paths and initializers.
3. Isolated Rails engine plus an explicit seam registry applied in `config.to_prepare`.

## Decision Outcome

Chosen option: **3, isolated Rails engine plus explicit seam registry**.

| Aspect | Decision |
|---|---|
| Engine | `Operator::Engine < ::Rails::Engine` with `isolate_namespace Operator`, in `operator/lib/operator/engine.rb`, required by `operator/lib/operator.rb` |
| Loading | `Gemfile` gains one line, `eval_gemfile 'operator/Gemfile'` (OT-001), whose `gemspec` directive exposes `operator/` as a path gem. `config/application.rb` already calls `Bundler.require(*Rails.groups)`, so the engine loads in every environment |
| Zeitwerk | `operator/lib` is not a Zeitwerk root; engine `app/` dirs autoload normally. Inside `module Operator` core constants are always fully qualified (`::Account`, `::Conversation`, `::Channel`) |
| Routes | An engine initializer calls `Rails.application.routes.append` to mount `Operator::Engine` at `/operator`. `config/routes.rb` is not edited. Precedence in ADR 0005 |
| Migrations | Engine initializer appends `operator/db/migrate` to the app migration paths so `db:migrate` and `db:chatwoot_prepare` pick them up |
| Views | Engine initializer unshifts `operator/app/views` ahead of core view paths (*verify at boot*) |
| Schedules | `operator/config/schedule.yml` loaded into sidekiq-cron with `source: 'operator'` (mandatory: the core loader deletes jobs of the same source that are missing from its own hash) |
| Core behaviour changes | Only through `prepend` entries declared in `operator/lib/operator/seams.rb` and applied in `config.to_prepare`, so they re-apply on every reload |
| Seam DSL | `seam ::SendReplyJob, with: Operator::Seams::SendReplyJobExt, methods: [:perform], guard: 'send_reply_job_spec'` |
| Seam module rules | Named `Operator::Seams::<CoreClass>Ext`; at most 30 lines; delegates to an Operator service; calls `super` on every path it does not own |
| Edits a prepend cannot make | Enum re-declaration raises `detect_enum_conflict!`, so those are one-line core touches (OT-003, OT-004), marked and logged |
| Docker | Own `operator/docker/Dockerfile` (a copy, not a patch) that copies `operator/` before `bundle install` and sets `CW_EDITION=ce` |
| Frontend | `app/javascript/operator/` behind a Vite alias (OT-002); all routes lazy |

Why not `ChatwootApp.extensions` / `prepend_mod_with`:

| Reason | Detail |
|---|---|
| Coverage | The injector is called from roughly 80 core classes. Several required seams (`AgentBotListener`, `Channel::Sms`, `DashboardController`, `HookListener`, `Llm::Config`) have no hook |
| Name collision | The injector resolves `<Extension>::<CoreName>`. Registering `Operator` as an extension would make `Operator::Conversation`, `Operator::Account` and similar names mean "patch of a core class" and block them for product models |
| Single registry | Seams spread across injector-resolved files cannot be enumerated reliably; one `seams.rb` generates the Seam Register and drives guard specs |
| Provenance | The injector exists mainly to serve `enterprise/`; Operator does not mirror that layout (ADR 0003) |

Why not a `config/application.rb` or `boot.rb` patch: a multi-line edit in the most merge-sensitive core file that still provides no routing, migration or asset isolation.

### Consequences

- Good: loading costs one Gemfile line; every other core dependency is a seam row or a logged touch.
- Good: `isolate_namespace` gives `operator_` table names, engine-scoped route helpers and isolated controllers.
- Good: the Seam Register is generated from code and cannot drift from it.
- Good: removing Operator means deleting `operator/` and reverting the touch list.
- Bad: prepending private methods couples to core internals; mitigated by guard specs that snapshot signatures and fail loudly on upstream renames.
- Bad: seams on singletons (`BaseListener` subclasses, `ChatwootHub`) affect the live instance and need explicit tests.
- Bad: contributors must remember the `::` prefix for core constants inside `module Operator`.

## Confirmation

| Check | CI job |
|---|---|
| Every seam has a guard spec: target method exists with snapshotted signature, the `Ext` module precedes the core class in `ancestors`, a core entry point produces the Operator effect | `operator-specs` (seams group) |
| Seam modules at most 30 lines | custom RuboCop cop in `lint-ruby` |
| Seam Register regenerated from `seams.rb` with no diff | `docs` |
| No `prepend` of a core constant outside `seams.rb`; no `ChatwootApp.extensions` registration under `operator/` | `architecture` |
| Core diff limited to entries in `upstream-touches.yml` | touch audit in `architecture` |
| Boot with zero `Enterprise` constants | boot check in `core-specs` |
