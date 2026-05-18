# Changelog

All notable changes to this skills overlay are recorded here. Versions follow [Semantic Versioning](https://semver.org/): MAJOR bumps for breaking changes to a skill's contract or directory layout, MINOR for new skills, PATCH for clarifications and edits inside existing skills.

## [0.2.0] — 2026-05-18

### Added

- **`scripts/install.sh`** — portable installer that snapshots skills from one or more source repos (Addy Osmani's `agent-skills` + this overlay by default) into a target project's `.skills/` directory, plus pointer files for Claude Code (`CLAUDE.md`), OpenAI Codex (`AGENTS.md`), and GitHub Copilot (`.github/copilot-instructions.md`). Idempotent via a managed-block pattern.
- **`scripts/README.md`** documenting installer options and managed-block behavior.

### Documentation

- Main README updated to point at the cross-tool installer as the recommended path for Codex / Copilot.

## [0.1.0] — 2026-05-18

Initial release. Four design-layer skills covering the ideate → design → spec lifecycle, intended to compose on top of general-purpose skill libraries like [`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills).

### Added

- **`system-design-docs`** — arc42-style evergreen system-level design documentation, implementation-agnostic, all phases visible.
- **`architecture-diagrams`** — diagrams as code via a viewpoint-based menu (C4 Container/Component, sequence, state, deployment), with PlantUML as the recommended default.
- **`feature-design-doc`** — Google-style point-in-time design doc (1–10 pages, seven canonical sections) for non-trivial sub-features that warrant design review before implementation.
- **`poc-production-fidelity`** — walking-skeleton / tracer-bullet pattern: keep architectural boundaries and data ownership intact while deliberately simplifying runtime, durability, and operational depth.
