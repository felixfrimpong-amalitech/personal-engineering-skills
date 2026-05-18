---
name: system-design-docs
description: Authors and maintains the evergreen system-level design document — an arc42-style living architecture document that describes the system as a whole, across all phases, implementation-agnostically. Use when starting a project that will outlive its first implementation, when onboarding will outpace what specs cover, when a system spans multiple feature increments or phases and needs a shared mental model that survives reimplementation. Distinct from spec-driven-development (per-phase, implementation-tied) and feature-design-doc (point-in-time, per-feature). Pairs with architecture-diagrams for visual companions and documentation-and-adrs for the per-decision record stream.
---

# System Design Docs

## Overview

A system-level design doc answers the question that no other artifact answers cleanly: *"how is this system supposed to fit together as it grows?"* It describes layers, components, key contracts, runtime concerns, and quality attributes — at the level of *what the system is*, not *how today's code happens to spell it*. The defining property is **evergreen**: the doc lives, gets edited as the system evolves, and survives a full reimplementation. That property is what makes it different from a spec (per-phase, implementation-tied), a feature design doc (point-in-time, per-feature, archived after implementation), and an ADR (per-decision, frozen on acceptance).

The dominant template for this kind of artifact is **arc42** (Gernot Starke's 12-section architecture documentation template). The dominant vocabulary for the structural diagrams inside it is **C4** (Simon Brown's Context / Container / Component / Code levels). This skill uses arc42 as the canonical structure, names a smaller "essential 6" subset most projects actually need, and gives explicit guidance on when to split the doc into multiple files vs. keep it as one.

This skill sits between idea-refine and spec-driven-development in the lifecycle:

```
ideate (once, system-wide)
   └─→ design (this skill — once + maintained, system-wide, all phases visible)
          ├─→ feature-design-doc (per-sub-feature, only when warranted)
          └─→ spec (per-phase implementation contract)
                 └─→ plan → tasks → build → test → ship
```

## When to Use

- Starting a project that will outlive its first implementation
- A system will be built across multiple phases or capability tracks, and the matured shape needs to be visible from day one
- Onboarding a new engineer or agent will need more than the per-phase spec offers
- Multiple specs are accumulating and there is no central description of how the parts fit
- A reimplementation, platform migration, or major refactor is being considered — the design doc is the artifact that makes the work tractable rather than a guess
- Reviewers keep asking "where does X live?" or "what's the difference between Y and Z?" and the spec doesn't answer

**When NOT to use:** Single-feature additions to an existing system (use `spec-driven-development`), point-in-time design proposals for a sub-feature within an existing phase (use `feature-design-doc`), throwaway prototypes, internal scripts, isolated services with one responsibility and no roadmap.

## The Canonical Structure (arc42)

arc42 prescribes 12 sections. Most systems do not need all 12. Mark the first six as **essential** and treat 7–12 as opt-in based on the system's needs.

| # | Section | Purpose | Essential? |
|---|---|---|---|
| 1 | Introduction and Goals | Why does this system exist? Who are the stakeholders? What are the top quality goals? | Yes |
| 2 | Architecture Constraints | What constraints (technical, organizational, regulatory) are non-negotiable? | Yes |
| 3 | System Scope and Context | What is in vs. out; how does the system interact with humans and external systems? | Yes |
| 4 | Solution Strategy | The handful of fundamental decisions that shape everything else. | Yes |
| 5 | Building Block View | The static decomposition: layers, components, their responsibilities and interfaces. C4 Container and Component levels live here. | Yes |
| 6 | Runtime View | How key scenarios flow through the building blocks. Sequence diagrams live here. | Yes |
| 7 | Deployment View | Where the system runs and what crosses a process boundary. | If multi-process |
| 8 | Crosscutting Concepts | Concerns that span multiple components: error handling, authn/authz, observability, internationalization, persistence patterns. | If non-trivial |
| 9 | Architecture Decisions | Either inline summary of key decisions or links to ADRs. Prefer the link form. | If using ADRs |
| 10 | Quality Requirements | Quality scenarios and tree (performance, scalability, availability, security targets). | If targets exist |
| 11 | Risks and Technical Debt | Known weaknesses and deferred work. | If tracking |
| 12 | Glossary | Domain terms used throughout the doc. | If ≥5 ambiguous terms |

**Start with the essential 6. Add later sections only when there is content to put in them** — empty sections are noise and signal a doc that's been started but not lived in.

## Single-Doc vs Split-Doc

arc42 itself ships as both: one large `architecture.md` and a `arc42/` directory of one-file-per-section. Both are correct. Choose by size, not by taste:

- **Single doc** (`docs/design/architecture.md`) — default for most systems. Easier to read end-to-end, easier to grep, no cross-file linking overhead. Aim for under ~30 pages / ~2000 lines; beyond that, split.
- **Split doc** (`docs/design/<section>.md` with `README.md` as index) — when one section becomes substantially larger than the rest (typically the Building Block View or Crosscutting Concepts), or when sections are owned by different reviewers. Keep the section names recognizable as arc42 sections; do not invent novel names that obscure the structure.

A common, honest split is three files when the domain itself is rich enough to warrant its own document:

```
docs/design/
├── README.md           ← index, glossary, reading order
├── architecture.md     ← arc42 §1-6 (and §7-11 if present): structural design
└── domain-model.md     ← deep entity semantics (large arc42 §8.x or its own concept doc)
```

If the project ships across capability phases, a third file documenting the roadmap shape is also reasonable:

```
└── extension-phases.md  ← phase tracks, dependencies, what each phase delivers
```

This split is one accepted variant, not the canonical form. Pick it when the content forces it; default to single-doc otherwise.

## Implementation-Agnostic Discipline

The single load-bearing property is **implementation-agnosticism**. Without it, the doc is a slow-aging spec. With it, the doc survives platform migrations and reimplementations. Six rules keep design docs honest:

1. **No file paths.** Refer to components by domain name (`engine`, `consent gate`, `dispatch worker`), not by `packages/api/src/...`.
2. **No command names.** `npm run build` belongs in the spec, not in design.
3. **No package or framework names in prose** unless the framework choice is itself the architectural point being made.
4. **No spec-style acceptance criteria.** Design has quality scenarios (arc42 §10), not implementation checklists.
5. **Schema and code blocks are pseudo-code or contract sketches**, not actual TypeScript imports. The shape is the point; the syntax is illustrative.
6. **Today's simplifications are described as today's choice**, not as the system's truth. "v1 collapses durable queue + workers into in-process synchronous fan-out" is correct; "the system uses in-process synchronous fan-out" lies about the design.

A useful test: take any sentence and ask, *would this still be true if we threw away the current implementation and started over from the design?* If no, the sentence is misplaced — it belongs in the spec.

## Forward-Looking Annotations

When the design covers a system that ships in capability phases or tracks (and v1 deliberately simplifies the matured shape), tag forward-looking components and fields with the phase that introduces them:

```markdown
### Components

- **Dispatch worker** *(reliability)* — pulls intents from the queue, calls
  the channel adapter, classifies the result.
- **Policy gate** *(policy)* — applied after consent; evaluates frequency
  caps, quiet hours, suppression.
```

Pair this with a short *"What v1 deliberately collapses"* table near the end of the Building Block View that maps each matured component to its v1 simplification. This pattern is not arc42-canonical — it's a useful technique borrowed from product roadmap documentation, applied to the Building Block View. Use it whenever the design describes a shape the system has not yet fully implemented.

## Distinguishing From Adjacent Artifacts

| Artifact | Question | Time | Implementation-tied? | Lifecycle |
|---|---|---|---|---|
| **System design doc** *(this skill)* | How is the system supposed to fit together as it grows? | Evergreen | No — survives reimplementation | Lives. Updated when the matured shape changes. |
| **Feature design doc** | Should we build this sub-feature, and how? | Point-in-time | Sometimes — names current dependencies | Drafted → Reviewed → Approved → Implemented → archived |
| **Spec** *(per-phase)* | What are we building this phase, and how do we know it's done? | Per-phase | Yes — file paths, commands, acceptance criteria | One per phase; rewritten or replaced when implementation is replaced |
| **ADR** | Why was *this one* decision made? | Decision time | Sometimes | Frozen on acceptance; superseded but not deleted |

The most common failure mode is conflating the system design doc with the per-phase spec. A design doc that drifts into "in v1 we use Drizzle and Fastify" has become a spec with the wrong filename. Hold the line: if a sentence references the current build, it belongs in the spec.

## Workflow

When starting a project that warrants a system design doc:

```
1. SCOPE — confirm the project trips a When-to-Use trigger. If it doesn't, skip.
2. AUTHOR essential 6 — Introduction & Goals, Constraints, Scope & Context,
   Solution Strategy, Building Block View, Runtime View
3. ADD §7–12 only if there is genuine content (Deployment, Crosscutting,
   Decisions, Quality, Risks, Glossary)
4. WIRE diagrams via architecture-diagrams skill — link from Building Block
   and Runtime sections; never inline diagram source
5. TAG forward-looking components if the system ships in phases
6. CROSS-REFERENCE — root README and the Phase 1 spec link to the design doc;
   the design doc links back to ADRs and to the diagram index
7. VERIFY against the checklist
```

When the matured design itself changes (rare; usually accompanied by an ADR):

```
1. WRITE the ADR first — design follows decisions, not the other way around
2. UPDATE the affected sections of the design doc end-to-end
3. UPDATE diagrams (handoff to architecture-diagrams)
4. UPDATE the glossary if terms shifted
5. NOTE the change at the top of the doc with a date
```

When a phase ships and lifts a v1 simplification:

```
1. UPDATE the "v1 collapses" table — remove or downgrade the lifted row
2. REMOVE or downgrade the phase tag on components that have shipped
3. VERIFY no stale "in v1, X is collapsed" prose remains in the doc body
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The spec covers this" | Specs are implementation-tied. The first time someone asks "how is this supposed to fit together long-term?" the spec can't answer without lying or going stale. |
| "ADRs cover this" | ADRs are per-decision. Reading every ADR is not a substitute for one coherent picture of the system. |
| "We'll write design docs later, once the system stabilizes" | Stabilization is exactly when design docs are cheapest — you've already paid the thinking cost. Three months later you'll have to reconstruct it from code. |
| "This is too small for arc42" | Then start with the essential 6 sections, half a page each. arc42 scales down. The structure is the point, not the length. |
| "Implementation-agnostic is too academic" | It's the load-bearing property. Without it, the doc is a spec with a different filename and decays at the same rate. |
| "The design might change" | It will. That's why design docs are versioned in the repo and updated when it does. Outdated with a clear changelog beats nonexistent. |
| "Every architectural decision should be inline in the doc" | Inline rationale bloats the design doc and conflates decisions with structure. Use ADRs for decisions; link from arc42 §9. |

## Red Flags

- A design doc that references `packages/`, `src/`, or any actual file path
- A "design doc" that turns out to be a fancy spec — describes the current build, not the matured shape
- v1 simplifications described as the canonical behavior, with no phase tag and no "v1 collapses" table or equivalent
- arc42 sections present but empty (signal of a doc started but not lived in)
- Architectural decisions inlined as long rationale paragraphs instead of links to ADRs (§9 should be slim)
- A glossary scattered across multiple sub-docs with subtly different definitions of the same term
- Components in code that don't appear in the Building Block View, or components in the doc that don't exist anywhere and aren't phase-tagged
- A design doc untouched since v1 shipped, even though the system has acquired new capabilities since
- "Quality requirements" expressed as wishes ("the system should be fast") instead of scenarios ("p95 latency under 200ms at 1000 rps")
- A split doc with no `README.md` index, or with cross-references that point at deleted sections

## Verification

Before the design doc is sent for review:

- [ ] The essential 6 arc42 sections are present and have substantive content (Introduction & Goals, Constraints, Scope & Context, Solution Strategy, Building Block View, Runtime View)
- [ ] Sections 7–12 are present *only* if they have content; empty sections deleted
- [ ] No file path, package name, command name, or framework name appears in prose (unless framework choice *is* the architectural point)
- [ ] No spec-style acceptance criteria embedded; quality requirements are scenarios in §10
- [ ] Building Block View references at least one component diagram (handoff to `architecture-diagrams`)
- [ ] Runtime View references at least one sequence diagram for a representative scenario
- [ ] Forward-looking components are phase-tagged; an explicit "what's deliberately not built today" section exists if the system ships in phases
- [ ] §9 (Architectural Decisions) is a slim list of links to ADRs, not inlined rationale paragraphs
- [ ] Glossary covers every term used ambiguously across sections
- [ ] Root README and per-phase specs link to the design doc; the design doc links back to ADRs and the diagram index
- [ ] The single-doc / split-doc choice matches the system's size; no split unless one section is genuinely heavier than the rest

When the matured design changes:

- [ ] An ADR exists for the change
- [ ] All affected sections re-read end-to-end and updated
- [ ] No stale phase tag remains for a capability that has shipped
- [ ] No "we plan to do X" prose remains for an X that has shipped or been abandoned
