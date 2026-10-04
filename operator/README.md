# Operator

Operator is a multi-tenant customer-operations platform for travel,
hospitality, real estate and other service industries, built for African
markets first. It is implemented as an isolated Rails engine on top of the
Chatwoot MIT core that surrounds this directory.

- Charter for anyone changing code: [AGENTS.md](AGENTS.md)
- Architecture, decisions and standards: [docs/](docs/README.md)
- Current state and pending decisions: [STATUS.md](STATUS.md)

## How the engine loads

The root `Gemfile` evaluates `operator/Gemfile`, which exposes this directory
as a path gem. `Operator::Engine` mounts its routes under `/operator`, adds
tombstone routes for endpoints that only existed in the removed enterprise
tree, and applies every registered seam in `config.to_prepare`.

Core behaviour is changed only through `Operator::Seams`
(`lib/operator/seams.rb`), each seam being a small module prepended onto one
core class with a guard spec under `spec/seams/`.

## Running the Operator specs

```bash
OPERATOR_REAL_REDIS=1 bundle exec rspec operator/spec
```

Operator specs use a real Redis and a real PostgreSQL. The core suite keeps
its own conventions and runs separately.

## Upstream

`UPSTREAM_BASE` records the Chatwoot commit this tree is based on. Upstream
is merged tag by tag with merge commits; `bin/upstream_resolve` re-applies
the enterprise removal after each merge and `bin/touch_audit` checks that core
changes stay inside the logged budget.
