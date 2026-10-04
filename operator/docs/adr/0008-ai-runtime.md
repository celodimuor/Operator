---
status: accepted
date: 2026-10-04
deciders: Operator engineering
---

# 0008. AI runtime

## Context and Problem Statement

Operator AI replaces Captain (enterprise) with a first-party agentic layer: customer-facing assistants with tools, playbooks and approvals, an agent copilot, translation, memory, retrieval and evaluation. Chatwoot's MIT core already ships the `ai-agents` gem on RubyLLM and an `Llm::Config` used by MIT Captain tasks. We need provider portability (Claude, GPT and others), per-task model routing, tenant overrides with bring-your-own-key, cost accounting and tracing, without provider-specific branches in code.

## Decision Drivers

- Zero provider branching in Operator code.
- Model choice per task, changeable by config.
- Per-run cost and token accounting for metering and spend caps.
- Tracing compatible with OpenTelemetry GenAI conventions.
- Reuse MIT core dependencies; no new SDKs without an ADR.
- Testability with recorded real traffic (ADR 0010).

## Considered Options

1. Direct provider SDKs (Anthropic, OpenAI) per task.
2. `ai-agents` on RubyLLM with one provider entry per vendor.
3. `ai-agents` on RubyLLM behind a facade, with a single OpenAI-compatible provider configuration pointed at Vercel AI Gateway.

## Decision Outcome

Chosen option: **3**.

| Element | Decision |
|---|---|
| Facade | `Operator::AI::Runtime.call(task:, input:, account:)`; nothing outside `Operator::AI` touches the gem |
| Engine | `ai-agents` gem (MIT, already in core) on RubyLLM |
| Provider config | One OpenAI-compatible endpoint, `https://ai-gateway.vercel.sh/v1`; chat calls pass `provider: :openai, assume_model_exists: true` (keyword names *verify against ruby_llm 1.15*) |
| Model ids | Gateway form `provider/model`; exact ids confirmed against the gateway catalogue in the phase 0 spike |
| Core seam | `Llm::Config` singleton seam appends `/v1` and defaults the provider keywords, because core's context otherwise resolves gateway ids through RubyLLM's OpenRouter registry entry |
| Routing | `operator/config/ai/routing.yml` maps task to model: customer turn with tools on Claude Sonnet, intent and slot extraction on a small GPT, copilot on Claude, translation on GPT, judge and memory extraction on a small model, embeddings `text-embedding-3-small` at 1536 dimensions |
| Tenant overrides | Per-tenant routing overrides and BYOK gateway key (encrypted in `operator_tenant_settings`) |
| Prompts | Versioned with checksums in `operator_ai_prompts`; a run records the prompt version used |
| Tools | Each tool is a service object with a JSON schema; side-effecting tools may declare `needs_approval` |
| Usage | Tokens and cost persisted per run and run step (`operator_ai_runs`, `operator_ai_run_steps`) and fed to the metering ledger |
| Tracing | OpenTelemetry `gen_ai.*` spans exported to Langfuse; PII redacted before persistence or trace |
| Streaming | Copilot only |
| Forbidden | Direct provider SDKs (`anthropic`, `openai` and similar gems) |

### Consequences

- Good: switching a task's model is a YAML change; adding a vendor needs no code.
- Good: one egress host to allow-list, one key to rotate, gateway-level budgets.
- Good: the facade isolates `ai-agents` API churn to one module.
- Bad: dependence on Vercel AI Gateway availability; mitigated by BYOK and the facade (a second OpenAI-compatible endpoint is a config change).
- Bad: provider-specific features not exposed through the OpenAI-compatible surface are unavailable.
- Bad: the `Llm::Config` seam couples to a core singleton; guarded.

## Confirmation

| Check | CI job |
|---|---|
| No provider SDK gems in `Gemfile.lock` additions from `operator/`; no `RubyLLM`/`Agents` constants referenced outside `Operator::AI` | dependency guard and boundary spec in `architecture` |
| Every task in code has a `routing.yml` entry | `registries` |
| Golden suites per pack replayed from cassettes; thresholds per ADR 0010 | `operator-specs` (AI replay) |
| Nightly live evals through the gateway under a 20 dollar cap | nightly |
| `Llm::Config` guard spec: endpoint ends in `/v1` and chat defaults the provider | `operator-specs` (seams) |
| Every run persists tokens and cost | `operator-specs` |
