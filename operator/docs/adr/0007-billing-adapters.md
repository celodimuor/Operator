---
status: accepted
date: 2026-10-04
deciders: Operator engineering
---

# 0007. Billing adapters

## Context and Problem Statement

Operator launches in Nigeria (NGN), then Africa, then global markets (USD). No single payment provider covers all of them well, and provider-hosted plan catalogues differ in features and cannot express Operator's limits (agents, inboxes, conversations per month, AI credits, WhatsApp conversations). How are plans, entitlements and payments modelled across providers?

## Decision Drivers

- NGN first-class at launch, with a fallback provider.
- USD for non-African tenants.
- Entitlements drive core limits (`usage_limits`) and must not depend on provider availability.
- Exact money arithmetic.
- Webhooks are retried and duplicated by providers; processing must be exactly-once in effect.
- Hosted checkout only; Operator never handles card data.

## Considered Options

1. One provider (Stripe) for everything, with its product catalogue as source of truth.
2. Provider-specific billing code per market, provider catalogues as source of truth.
3. A port with one adapter per provider; Operator database as source of truth for plans and entitlements.

## Decision Outcome

Chosen option: **3**.

| Element | Decision |
|---|---|
| Port | `Operator::Billing::Gateway`: initialise checkout, charge authorisation, verify webhook, parse event, refund. Gateways only move money |
| Adapters | Paystack (NGN, primary), Flutterwave (NGN, fallback), Stripe (USD) |
| Plans | Defined in `operator/config/plans.yml`, synced to `operator_plans` (code, currency, interval, price in minor units, features, limits, add-ons) |
| Entitlements | `operator_entitlements` materialised from plan plus add-ons plus manual overrides by `Operator::Entitlements::Reconcile`; the `Account` seam reads `usage_limits` from them so core agent and inbox limits enforce themselves |
| Money | Integer minor units plus ISO 4217 currency code on every amount column; never floats, never jsonb |
| Ledger | `operator_invoices`, `operator_invoice_lines`, `operator_payments`, `operator_billing_customers`; authorisation codes encrypted |
| Webhooks | Raw body signature verified, persisted to `operator_inbound_events(provider, event_id)` with a UNIQUE index, acknowledged under one second, processed asynchronously; duplicates hit the unique index and are no-ops |
| Idempotency | Money-moving API calls require an idempotency key (`operator_idempotency_keys`) |
| Dunning | Retries on days 3, 5, 7; `past_due` banner; suspension on day 14 via core `suspended` status; cancellation and erasure ticket on day 60 |
| Subscription state | `trialing`, `active`, `past_due`, `suspended`, `cancelled`, owned by Operator, not the provider |

Option 1 is rejected because Stripe's NGN coverage and local payment methods are insufficient for launch. Option 2 duplicates logic and lets provider catalogues drift from the entitlements that gate the product.

### Consequences

- Good: adding a provider (M-Pesa, MTN MoMo) is a new adapter.
- Good: entitlements and limits work during a provider outage.
- Good: webhook duplicates are harmless by construction.
- Bad: Operator owns proration, dunning and invoicing logic that a single-provider billing product would supply.
- Bad: each adapter needs live sandbox credentials and recorded cassettes (ADR 0010).

## Confirmation

| Check | CI job |
|---|---|
| Each adapter passes the shared gateway contract suite against VCR cassettes of real sandbox traffic | `operator-specs` (contracts) |
| Live sandbox suites (Paystack test keys, Stripe test mode, Flutterwave test mode) | provider-live daily |
| Duplicate webhook delivery produces one effect | `sidekiq-cable-real` |
| Money columns are integer with a sibling currency column; no amount keys in jsonb | `migrations` lint |
| Coverage for billing at 95 line, 90 branch | `operator-specs` coverage ratchet |
| Generated plans table matches `plans.yml` | `docs` |
