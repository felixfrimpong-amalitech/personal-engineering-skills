# scripts/install.sh

Installs engineering skills into a target project as a flat `.skills/` snapshot, plus pointer files for Claude Code, OpenAI Codex, and GitHub Copilot. Idempotent — re-run anytime to refresh.

## Quick start

```sh
# From any project root, with sensible defaults:
~/personal-engineering-skills/scripts/install.sh

# Or pin a target and tool subset:
~/personal-engineering-skills/scripts/install.sh \
  --target ~/path/to/project \
  --tool codex,copilot
```

## What it produces

```
target-project/
├── .skills/                          ← flat snapshot, one .md per skill
│   ├── using-agent-skills.md
│   ├── spec-driven-development.md
│   ├── system-design-docs.md
│   └── ... (one per skill, names from upstream)
├── CLAUDE.md                         ← if --tool claude or all
├── AGENTS.md                         ← if --tool codex or all
└── .github/
    └── copilot-instructions.md       ← if --tool copilot or all
```

The three pointer files share the same managed block: a discovery flowchart, core operating behaviors, and a catalog table linking to each `.skills/<name>.md` for the full workflow.

## Options

| Flag | Default | Meaning |
|---|---|---|
| `--target DIR` | `$PWD` | Project root to install into. |
| `--tool TOOLS` | `all` | Comma-separated subset of `claude`, `codex`, `copilot`, or `all`. |
| `--source URL` | (see below) | Additional skill source repo. Repeat for multiple. Later sources override earlier on name collision. |
| `--help` | | Show usage. |

**Default sources** when `--source` is omitted:

1. `https://github.com/addyosmani/agent-skills.git` — general lifecycle skills
2. `https://github.com/felixfrimpong-amalitech/personal-engineering-skills.git` — design-layer overlay (this repo)

Pass `--source <url>` one or more times to override the defaults entirely.

## Managed-block behavior

Each pointer file contains a single managed block bounded by:

```
<!-- BEGIN: engineering-skills (managed by install.sh — do not edit between markers) -->
...
<!-- END: engineering-skills -->
```

The script's behavior depends on what already exists:

- **File doesn't exist** → Created with a header + managed block.
- **File exists without the block** → Block appended to the end; existing content preserved.
- **File exists with the block** → Only the block is replaced; everything else is untouched.

This means you can hand-write project-specific instructions outside the markers and they survive every re-run.

## Source cache

Upstream repos are shallow-cloned to `${XDG_CACHE_HOME:-~/.cache}/eng-skills/<repo>/` and `git fetch + reset --hard` updates them on each subsequent run. No git history pollutes the target project.

## .skills/ — commit or gitignore?

Decide per project:

- **Commit** if any cloud agent (Codex cloud, Copilot Coding Agent) needs to see the skill bodies — those agents only see committed files. Cost: ~27 markdown files, ~300 KB total.
- **Gitignore** if everyone working on the project runs `install.sh` themselves (treat it like `node_modules`). Add `.skills/` to your project's `.gitignore`.

The script does not modify `.gitignore` automatically.

## Refreshing

```sh
# Just re-run. Upstream is fetched + reset, snapshot rebuilt, managed blocks replaced.
~/personal-engineering-skills/scripts/install.sh
```

To see what changed, `git diff .skills/ CLAUDE.md AGENTS.md .github/copilot-instructions.md` after a refresh.
