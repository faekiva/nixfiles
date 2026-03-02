# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a Nix system configuration repo managing macOS (nix-darwin) and NixOS hosts. There are **two flakes**:

- `/flake.nix` — Dev shell only (provides nixd, nixfmt, nh, sops, age, etc.)
- `/config/flake.nix` — The actual system configuration flake

The config flake **auto-discovers hosts** by scanning subdirectories of `config/hosts/Darwin/` and `config/hosts/NixOS/`. Adding a new host directory automatically registers it — no manual flake editing needed.

## Hosts

| Host | Type | User | Notes |
|---|---|---|---|
| `batgirl` | Darwin (aarch64) | `kiva` | Personal Mac |
| `rewardsnetwork` | Darwin (aarch64) | `kiva` (maps to `khilgenberg`) | Work Mac |
| `sachi` | NixOS (x86_64) | `kiva` | Home server — KDE, Docker, Podman, Tailscale, Immich, Jellyfin, Mattermost |

## Common Commands

Uses [go-task](https://taskfile.dev) via `Taskfile.yml`:

```bash
task deploy          # Deploy to current machine (uses nh, prompts for confirmation)
task deploy-sachi    # Remote deploy to sachi over SSH
```

Under the hood, deploy runs `nh os switch ./config --ask -H <hostname>` (Linux) or `nh darwin switch ./config --ask -H <hostname>` (Darwin).

Other useful commands:
```bash
nix flake update --flake ./config    # Update all flake inputs
nix flake lock --update-input <name> --flake ./config  # Update a single input
nixfmt .                             # Format all nix files
```

## Key Architecture Patterns

**`inputs.flakeRoot` / `inputs.repoRoot`**: The config flake injects `flakeRoot = self` (pointing to `config/`) and `repoRoot = "${self}/.."` into `specialArgs`. All cross-module imports use `${inputs.flakeRoot}/modules/...` for path resolution.

**Tiered home-manager packages** in `config/modules/hereafter/hm/`:
- `level0-packages.nix` — Minimal baseline (htop, fd, git, micro)
- `level1-packages.nix` — Imports level0 + adds ripgrep, bat, fzf, zsh, tmux, etc.
- `ai-packages.nix` — AI tools (aider-chat, claude-code, cco)

Every host imports `level1-packages.nix` and `ai-packages.nix`.

**Custom NixOS options**: Modules like `kvm.nix` define options under `hereafter.*` namespace (e.g., `hereafter.kvm.users`).

**Lix**: All hosts use `pkgs.lixPackageSets.stable.lix` instead of stock Nix.

## Secrets Management

Uses **sops-nix** with **age** keys. Config in `/.sops.yaml`. Encrypted files live in `/secrets/`. Two keys: personal machine key and sachi's SSH-derived key. The age key file path is set via `.envrc` (`SOPS_AGE_KEY_FILE=~/.ssh/nix.age`).

## Custom Packages

`config/packages/cco.nix` — Builds the `cco` Claude Code sandbox wrapper from a non-flake input.

## Container Patterns

- **NixOS containers** (`containers.<name>`): Used for Mattermost (private networking)
- **OCI/Podman containers** (`virtualisation.oci-containers`): Used for Jellyfin
- **Docker**: Enabled on sachi but used less than Podman
