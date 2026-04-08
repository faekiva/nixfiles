# CODEX.md — Codex Agent Entrypoint

**Strict Dependency: You are strictly bound to the Decapod control plane.**

This contract applies equally to Codex, Claude, Gemini, and any other agent operating here. See [AGENTS.md](AGENTS.md) for the full universal agent contract.

## Embedded Docs

decapod docs show docs/AGENTS.md

## Invariants (Normative)

- **INV-STORE-BOUNDARY**: Agents MUST NOT directly mutate `.decapod/*`; all access MUST use CLI. (enforced by validation gates)
- **INV-DAEMONLESS**: Decapod MUST NOT leave background processes running.
- **INV-BOUNDED-VALIDATE**: `decapod validate` MUST terminate within bounded time.

## .decapod CLI-only jail rule marker

**.decapod CLI-only jail rule marker**: Agents MUST NOT directly mutate `.decapod/*`; all access MUST use CLI surfaces.

## Mandatory Initialization

```bash
command -v decapod >/dev/null || cargo install decapod

decapod validate
decapod docs ingest
decapod session acquire
decapod rpc --op agent.init
decapod workspace status
decapod todo add "<task>"
decapod todo claim --id <task-id>
decapod workspace ensure
cd .decapod/workspaces/<your-worktree>
decapod rpc --op context.resolve
```

## Golden Rules (Non-Negotiable)

1. **MUST** refine intent with the user before inference-heavy work.
2. **MUST NOT** work on main/master. **MUST** use `.decapod/workspaces/*`.
3. **MUST** access `.decapod/*` files only via decapod CLI surfaces.
4. **MUST NOT** claim done without `decapod validate` passing.
5. **MUST NOT** invent capabilities that are not exposed by the binary.
6. **MUST** stop if requirements conflict, intent is ambiguous, or policy boundaries are unclear.
7. **MUST** respect the Interface abstraction boundary.

## Safety Invariants

- ✅ Router pointer: `core/DECAPOD.md`
- ✅ Validation gate: `decapod validate`
- ✅ Constitution ingestion gate: `decapod docs ingest`
- ✅ Workspace status gate: `decapod workspace status`
- ✅ Claim-before-work gate: `decapod todo claim --id <task-id>`
- ✅ Session auth gate: `DECAPOD_SESSION_PASSWORD`
- ✅ Workspace gate: Docker git workspaces
- ✅ Privilege gate: request elevated permissions before Docker/container workspace commands

## Operating Notes

- Use `decapod docs show core/DECAPOD.md` and `decapod docs show core/INTERFACES.md` for binding contracts.
- Use `decapod capabilities --format json` for authority surface.
