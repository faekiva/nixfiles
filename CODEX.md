# CODEX.md — Codex Agent Entrypoint

This is a Codex agent entrypoint. See [AGENTS.md](AGENTS.md) for the universal agent contract that applies to all agents including Codex.

## Quick Reference

All Codex agents must follow the rules defined in `AGENTS.md`. Key points:

- **MUST** use `.decapod/workspaces/*` for isolated work (never main/master)
- **MUST** call `decapod validate` before claiming done
- **MUST** access `.decapod/*` files only via CLI surfaces

## Initialization

```bash
# Follow the standard initialization in AGENTS.md
decapod rpc --op agent.init
```

## Router

- `core/DECAPOD.md` - Router and navigation charter
- `AGENTS.md` - Universal agent contract (this file delegates to it)
