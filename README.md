# personal-engineering-skills

A small overlay of design-layer engineering skills for AI coding agents, intended to **compose with** (not replace) general-purpose skill libraries such as [`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills). Each skill is a single `SKILL.md` with YAML frontmatter — plain markdown that any LLM, tool, or human can read.

## What's in here

| Skill | One-line summary |
|---|---|
| [`system-design-docs`](./skills/system-design-docs/SKILL.md) | Authors and maintains an **arc42-style evergreen** system-level design doc — implementation-agnostic, all phases visible, survives reimplementation. |
| [`architecture-diagrams`](./skills/architecture-diagrams/SKILL.md) | Diagrams as code with a viewpoint-based menu (**C4 Container/Component, sequence, state, deployment**), PlantUML default, kept in sync with structural code changes. |
| [`feature-design-doc`](./skills/feature-design-doc/SKILL.md) | **Google-style point-in-time** design doc (1–10 pages, seven canonical sections) for non-trivial sub-features that warrant a review before implementation. |
| [`poc-production-fidelity`](./skills/poc-production-fidelity/SKILL.md) | Walking-skeleton / tracer-bullet pattern — **keep architectural boundaries, simplify runtime**. Documents every simplification with a promotion path. |

## Where this sits in the lifecycle

These four skills cover the **design layer** of the agent-skills lifecycle. They compose with the broader lifecycle as follows:

```
idea-refine                  (e.g. addyosmani/agent-skills)
   │
   ▼
system-design-docs           ◄── this overlay (evergreen, system-wide)
   │
   ├──► feature-design-doc   ◄── this overlay (point-in-time, per sub-feature)
   │       │
   │       │
   ▼       ▼
poc-production-fidelity      ◄── this overlay (when v1 is a POC)
   │
   ▼
spec-driven-development      (e.g. addyosmani/agent-skills)
   │
   ▼
planning → build → test → review → ship
```

## Install — Claude Code

```sh
/plugin marketplace add felixfrimpong-amalitech/personal-engineering-skills
/plugin install personal-engineering-skills@personal-engineering-skills
```

The skills load alongside any other installed skill libraries — no fork, no override. If a skill name ever clashes with another plugin, the last-installed wins (and you can `/plugin uninstall` and reorder).

Verify with `/plugin list` — you should see `personal-engineering-skills` and any other installed libraries (e.g. `agent-skills` from Addy Osmani).

## Use with other tools / LLMs

The canonical format is `skills/<name>/SKILL.md` — plain markdown with YAML frontmatter. Any LLM-aware tool can consume it; the integration is just a question of how the tool discovers files.

| Tool | How to use |
|---|---|
| **Claude Code** | Install as a plugin (above). Skills appear automatically. |
| **Claude Desktop / API** | `cat skills/*/SKILL.md` into your system prompt, or load and inject the relevant `SKILL.md` based on task triggers. |
| **Cursor** | Copy a SKILL.md's body into `.cursor/rules/<name>.md`, or reference via `@file` in chat. |
| **Aider** | Add the relevant SKILL.md to `--read` files, or list them in `.aider.conf.yml` under `read:`. |
| **GitHub Copilot Workspace / Codex** | Paste the relevant SKILL.md into the task or working-context window. |
| **ChatGPT / Gemini / generic chat** | Paste or attach SKILL.md when starting a task; the frontmatter `description` field tells the model when to apply it. |

The portability principle: **the markdown file is the source of truth; per-tool wiring is a thin adapter.** If a new tool emerges with its own format, write a small script that reads `skills/*/SKILL.md` and emits the tool's native format. Don't fork the skills.

## Layering with addyosmani/agent-skills

Designed as an additive overlay, not a fork:

1. Install Addy's first: `/plugin marketplace add addyosmani/agent-skills && /plugin install agent-skills@addy-agent-skills`
2. Install this overlay second (commands above).
3. Both plugins coexist. There are no name collisions in version 0.1.0; the skill discovery flowchart in `using-agent-skills` will continue to work, and these four skills register additional rows.

If Addy ships a new version of one of his skills, you `git pull` upstream — no merge conflicts, because nothing in this overlay touches his files. If you ever want to *modify* one of his skills, copy it into this overlay under `skills/` with the same name; this overlay's copy will win after install.

## Versioning

[Semantic Versioning](https://semver.org/). MAJOR bumps for breaking changes to a skill's contract or directory layout, MINOR for new skills, PATCH for clarifications and edits inside existing skills. See [`CHANGELOG.md`](./CHANGELOG.md).

## Iterating

These skills are intended to be revised as they meet contact with real projects. The pattern is:

1. Apply a skill on a real project.
2. Note where the verification checklist fails to match reality, where trigger conditions feel wrong, or where a section comes out empty.
3. Edit the relevant `SKILL.md` and bump the patch version.

The skills are short and prose-heavy on purpose; revising them is cheap.

## License

[MIT](./LICENSE). Re-use, remix, vendor into other skill libraries, propose changes upstream — all welcome.
