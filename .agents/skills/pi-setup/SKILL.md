---
name: pi-setup
description: Use whenever the user mentions "pi" in this repo. Covers the pi coding agent configuration managed through home-manager — including editing extensions, settings, skills, prompt templates, themes, deploying and testing config changes, troubleshooting pi behavior, and general pi-related questions. Also covers settings.json, packages, extensions, and the deploy/test loop.
---

# Pi Setup

This repo manages the pi coding agent configuration through home-manager.

## Where pi config lives

This is the **global** pi config, managed through home-manager. All files live under `config/modules/hereafter/hm/.pi/agent/` and get symlinked to `~/.pi/agent`. Do not put things in `.pi/` at repo root — pi won't find them unless you're working inside a different project directory.

| Type | Path (under `config/modules/hereafter/hm/.pi/agent/`) | Notes |
|------|-----------|-------|
| **Extensions** (TypeScript) | `extensions/` | Can be standalone `.ts` files or symlinks to nix store sources (like kilo.ts) |
| **Settings** | `settings.json` | `/settings` in pi or `docs/settings.md` for options |
| **Skills** | `skills/<name>/SKILL.md` | Must match Agent Skills standard |
| **Prompt templates** | `prompts/<name>.md` | Expanded via `/name` in pi |
| **Themes** | `themes/<name>.json` | Hot-reload on save |

## Deploy and test cycle

There are two levels of changes, and they determine how you iterate:

### Quick changes (no rebuild needed)
**Extensions, skills, prompt templates, themes** — these files are just read by pi at runtime. You can test them without rebuilding:

1. Edit the file in `config/modules/hereafter/hm/.pi/agent/`
2. **If `~/.pi/agent` is a valid symlink** (home-manager already ran at least once), the change is already live on disk.
3. Restart pi, or type `/reload` in an existing session (works for extensions in auto-discovered locations).

### Full rebuild needed
**`settings.json`**, **adding new files** (new skill directory, new extension file), or **changes to `ai-packages.nix`** — these require home-manager to relink things:

1. Edit the file
2. Deploy: `task deploy` from repo root (runs `nh os switch ./config --ask -H <hostname>`)
3. Restart pi

If you're iterating quickly, you can make temporary changes directly in `~/.pi/agent/` for testing, then copy the working version back into the repo. `task deploy` will overwrite `~/.pi/agent` with whatever's in the repo, so don't leave permanent work only on disk.

## Common workflows

### Adding a new extension
1. Create the `.ts` file in `config/modules/hereafter/hm/.pi/agent/extensions/`
2. If it depends on npm packages, you'll need to either:
   - Bundle it (e.g., with esbuild or tsup) and check in the output, or
   - Add it to `ai-packages.nix` as a derivation that handles dependencies
3. Deploy or restart pi
4. Test with `/reload` or a fresh pi session

Extensions export a default function receiving `pi: ExtensionAPI`. See the pi docs for the full API.

### Changing pi settings
1. Edit `config/modules/hereafter/hm/.pi/agent/settings.json`
2. Deploy with `task deploy`
3. Restart pi

### Adding a skill
1. Create directory: `config/modules/hereafter/hm/.pi/agent/skills/<name>/`
2. Write `SKILL.md` with YAML frontmatter (`name` and `description` required)
3. Add `scripts/`, `references/`, or `assets/` as needed
4. Deploy with `task deploy` to create the new directory under `~/.pi/agent`, then restart pi

### Adding a prompt template
1. Create `config/modules/hereafter/hm/.pi/agent/prompts/<name>.md`
2. Use `{{variable}}` for template parameters
3. Deploy with `task deploy`, then restart pi or `/reload`


