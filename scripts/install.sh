#!/usr/bin/env bash
# install.sh — Install engineering skills into a target project.
#
# Clones (or updates) each source repo into a global cache, copies SKILL.md
# files into the target's .skills/ directory as a flat snapshot, and writes
# pointer files for each requested tool:
#
#   CLAUDE.md                          — Claude Code project instructions
#   AGENTS.md                          — OpenAI Codex (CLI + cloud agent)
#   .github/copilot-instructions.md    — GitHub Copilot (Chat + Coding Agent)
#
# The pointer files contain a managed block delimited by BEGIN/END markers.
# Existing files are respected — only the managed block is replaced. Skill
# bodies live in .skills/ so the pointer files stay small.
#
# Usage:
#   install.sh [--target DIR] [--tool TOOLS] [--source URL ...]
#
# Defaults:
#   --target = current working directory
#   --tool   = all  (claude,codex,copilot)
#   --source = addyosmani/agent-skills, felixfrimpong-amalitech/personal-engineering-skills

set -euo pipefail

# ---- Defaults ----
TARGET="$PWD"
TOOL="all"
DEFAULT_SOURCES=(
  "https://github.com/addyosmani/agent-skills.git"
  "https://github.com/felixfrimpong-amalitech/personal-engineering-skills.git"
)
SOURCES=()
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/eng-skills"

# ---- Helpers ----
usage() {
  cat <<EOF
Usage: $(basename "$0") [--target DIR] [--tool TOOLS] [--source URL ...]

Installs engineering skills into a target project for use with Claude Code,
OpenAI Codex, and GitHub Copilot.

Options:
  --target DIR    Project root to install into (default: cwd)
  --tool TOOLS    Comma-separated list (default: all)
                  Values: claude, codex, copilot, all
  --source URL    Additional skill source repo. Repeat for multiple.
                  When omitted, defaults to:
                    - addyosmani/agent-skills (general lifecycle skills)
                    - felixfrimpong-amalitech/personal-engineering-skills (design overlay)
  --help          Show this message.

Outputs:
  TARGET/.skills/                          flat snapshot, one .md per skill
  TARGET/CLAUDE.md                         (if --tool claude or all)
  TARGET/AGENTS.md                         (if --tool codex or all)
  TARGET/.github/copilot-instructions.md   (if --tool copilot or all)
EOF
}

log() { printf '[install] %s\n' "$*" >&2; }
err() { printf '[install] ERROR: %s\n' "$*" >&2; exit 1; }

# ---- Parse args ----
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)   TARGET="$2"; shift 2 ;;
    --tool)     TOOL="$2"; shift 2 ;;
    --source)   SOURCES+=("$2"); shift 2 ;;
    --help|-h)  usage; exit 0 ;;
    *)          err "Unknown argument: $1 (try --help)" ;;
  esac
done

if [[ ${#SOURCES[@]} -eq 0 ]]; then
  SOURCES=("${DEFAULT_SOURCES[@]}")
fi

# Validate --tool values
WANT_CLAUDE=0; WANT_CODEX=0; WANT_COPILOT=0
IFS=',' read -r -a TOOL_LIST <<< "$TOOL"
for t in "${TOOL_LIST[@]}"; do
  case "$t" in
    claude)  WANT_CLAUDE=1 ;;
    codex)   WANT_CODEX=1 ;;
    copilot) WANT_COPILOT=1 ;;
    all)     WANT_CLAUDE=1; WANT_CODEX=1; WANT_COPILOT=1 ;;
    *)       err "Unknown tool: $t (expected claude, codex, copilot, or all)" ;;
  esac
done

[[ -d "$TARGET" ]] || err "Target directory does not exist: $TARGET"
TARGET="$(cd "$TARGET" && pwd)"

# ---- Fetch or update sources ----
mkdir -p "$CACHE_DIR"

SOURCE_DIRS=()
for url in "${SOURCES[@]}"; do
  name="$(basename "$url" .git)"
  dir="$CACHE_DIR/$name"
  if [[ -d "$dir/.git" ]]; then
    log "Updating $name..."
    git -C "$dir" fetch --quiet --depth=1 origin HEAD
    git -C "$dir" reset --quiet --hard FETCH_HEAD
  else
    log "Cloning $name..."
    git clone --depth=1 --quiet "$url" "$dir"
  fi
  SOURCE_DIRS+=("$dir")
done

# ---- Snapshot SKILL.md files into target/.skills/ ----
SKILLS_DIR="$TARGET/.skills"
mkdir -p "$SKILLS_DIR"
find "$SKILLS_DIR" -maxdepth 1 -type f -name '*.md' -delete 2>/dev/null || true

COUNT=0
for src in "${SOURCE_DIRS[@]}"; do
  for skill_md in "$src"/skills/*/SKILL.md; do
    [[ -f "$skill_md" ]] || continue
    skill_name="$(basename "$(dirname "$skill_md")")"
    cp "$skill_md" "$SKILLS_DIR/$skill_name.md"
    COUNT=$((COUNT + 1))
  done
done
log "Snapshotted $COUNT skills into $SKILLS_DIR (later sources override earlier)"

# ---- Compose the managed block ----
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

compose_block() {
  cat <<'HDR'
<!-- BEGIN: engineering-skills (managed by install.sh — do not edit between markers) -->
HDR
  echo "<!-- Generated: $TIMESTAMP -->"
  cat <<'BODY'

## Engineering Skills

This project uses a layered set of engineering skills for AI coding agents.
Before doing non-trivial work, identify the relevant skill using the
discovery flowchart below, then read its full body from `.skills/<name>.md`
before proceeding.

### Skill discovery

```
Task arrives
    │
    ├── Vague idea / need refinement?         → idea-refine
    ├── Designing the matured shape?          → system-design-docs
    │     ├── Visual companions needed?       → architecture-diagrams
    │     ├── POC of a production system?     → poc-production-fidelity
    │     └── Sub-feature design review?      → feature-design-doc
    ├── New project / feature / change?       → spec-driven-development
    ├── Have a spec, need tasks?              → planning-and-task-breakdown
    ├── Implementing code?                    → incremental-implementation
    │     ├── UI work?                        → frontend-ui-engineering
    │     ├── API work?                       → api-and-interface-design
    │     ├── Need better context?            → context-engineering
    │     └── Need doc-verified code?         → source-driven-development
    ├── Writing / running tests?              → test-driven-development
    │     └── Browser-based?                  → browser-testing-with-devtools
    ├── Something broke?                      → debugging-and-error-recovery
    ├── Reviewing code?                       → code-review-and-quality
    │     ├── Security concerns?              → security-and-hardening
    │     └── Performance concerns?           → performance-optimization
    ├── Committing / branching?               → git-workflow-and-versioning
    ├── CI/CD pipeline work?                  → ci-cd-and-automation
    ├── Writing docs / ADRs?                  → documentation-and-adrs
    └── Deploying / launching?                → shipping-and-launch
```

### Core operating behaviors

These apply across every skill:

1. **Surface assumptions** before acting on ambiguity.
2. **Manage confusion actively** — stop and ask, don't guess.
3. **Push back when warranted** — explain the concrete downside, propose an alternative.
4. **Enforce simplicity** — prefer the boring, obvious solution.
5. **Maintain scope discipline** — touch only what was asked.
6. **Verify, don't assume** — every skill ends with a verification step.

### Skill catalog

When you decide a skill applies, read `.skills/<name>.md` for the full
workflow, templates, and verification checklist.

| Skill | Description |
|---|---|
BODY

  # Bash glob is already lexicographically sorted; quoting the prefix
  # ensures paths with spaces in $SKILLS_DIR are preserved per item.
  for skill_md in "$SKILLS_DIR"/*.md; do
    [[ -f "$skill_md" ]] || continue
    name="$(basename "$skill_md" .md)"
    desc="$(awk -F': ' '/^description:/ {sub(/^description: */, ""); print; exit}' "$skill_md")"
    desc_escaped="${desc//|/\\|}"
    printf "| [\`%s\`](.skills/%s.md) | %s |\n" "$name" "$name" "$desc_escaped"
  done

  cat <<'SRC'

### Sources

These skills are snapshotted from:

SRC

  for url in "${SOURCES[@]}"; do
    name="$(basename "$url" .git)"
    display_url="${url%.git}"
    printf -- "- [%s](%s)\n" "$name" "$display_url"
  done

  cat <<'FTR'

Re-run the install script to refresh the snapshot.

<!-- END: engineering-skills -->
FTR
}

BLOCK="$(compose_block)"

# ---- Write or update a pointer file ----
write_pointer() {
  local path="$1"
  local title="$2"
  mkdir -p "$(dirname "$path")"

  if [[ -f "$path" ]]; then
    if grep -q '<!-- BEGIN: engineering-skills' "$path"; then
      local tmp="$path.tmp.$$"
      local in_block=0
      local emitted=0
      while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ $in_block -eq 0 && "$line" == *'<!-- BEGIN: engineering-skills'* ]]; then
          in_block=1
          printf '%s\n' "$BLOCK"
          emitted=1
          continue
        fi
        if [[ $in_block -eq 1 && "$line" == *'<!-- END: engineering-skills -->'* ]]; then
          in_block=0
          continue
        fi
        [[ $in_block -eq 0 ]] && printf '%s\n' "$line"
      done < "$path" > "$tmp"
      mv "$tmp" "$path"
      log "Updated managed block in $path"
    else
      printf '\n%s\n' "$BLOCK" >> "$path"
      log "Appended managed block to $path"
    fi
  else
    {
      printf '# %s\n\n' "$title"
      printf '%s\n' "$BLOCK"
    } > "$path"
    log "Created $path"
  fi
}

# ---- Emit per-tool pointer files ----
[[ $WANT_CLAUDE  -eq 1 ]] && write_pointer "$TARGET/CLAUDE.md"  "Claude Code instructions"
[[ $WANT_CODEX   -eq 1 ]] && write_pointer "$TARGET/AGENTS.md"  "Agent instructions"
[[ $WANT_COPILOT -eq 1 ]] && write_pointer "$TARGET/.github/copilot-instructions.md" "GitHub Copilot instructions"

log "Done. Skills snapshot: $SKILLS_DIR ($COUNT files)"
log "Tip: decide whether to commit .skills/ (works for cloud agents) or gitignore it (per-clone install)."
