---
name: feature-design-doc
description: Authors a Google-style point-in-time design doc (1–10 pages) for a non-trivial feature or sub-system that warrants design review before implementation begins. Use mid-phase when a proposed sub-feature is too large to fit cleanly in a spec section but too small to warrant its own phase, when a meaningful architectural change is being introduced inside an existing phase, when multiple stakeholders need to agree on an approach before code starts. Distinct from system-design-docs (evergreen, system-wide) and spec-driven-development (per-phase implementation contract). Pairs with both — a feature design doc references the system design for context and feeds into the phase spec for implementation.
---

# Feature Design Doc

## Overview

A feature design doc is the canonical reviewable design artifact in modern engineering practice (most strongly associated with Google, widely adopted at Meta, Stripe, and others). It is **point-in-time**, **focused on one feature or sub-system**, **between one and ten pages**, structured around a small number of well-known sections, and **reviewed in a design review** before implementation begins. Once the work it describes is implemented, the doc becomes a historical record — it is not maintained as a living artifact.

This is the third design-layer skill in the lifecycle:

```
ideate (idea-refine, system-wide, once)
   └─→ design (system-design-docs, system-wide, evergreen, all phases visible)
          ├─→ feature-design-doc (this skill — per-sub-feature, point-in-time, when warranted)
          └─→ spec (spec-driven-development, per-phase implementation contract)
                 └─→ plan → tasks → build → test → ship
```

The trigger is specific and the bar is intentionally high. Most work does not need a feature design doc — it fits in a spec section, or is small enough that incremental implementation handles it. This skill exists for the case that *does* warrant a design review meeting: a sub-feature inside an existing phase that is non-trivial enough that a brief written proposal, reviewed by named stakeholders before code starts, is cheaper than the rework cost of getting the design wrong.

## When to Use

Trigger when *all* of these are true:

- The proposed feature is too large or architecturally distinct to fit cleanly in a spec section
- Multiple stakeholders (engineers, product, security, ops) need to agree on an approach before implementation
- Getting the design wrong would cost meaningfully more than the time to write and review a 1–10 page doc
- The feature lands inside an existing phase (the phase spec already exists and will be updated to reference this design)

Strong concrete signals:

- Adding a new core component to an existing system
- Changing a public API in a non-additive way
- Introducing a new external dependency or third-party integration
- Designing a non-trivial migration path
- Picking a new internal protocol or data format
- Designing for cross-cutting concerns (auth, multi-tenancy, observability) that touch many components
- A proposal that has stalled in chat or PR-comment back-and-forth and needs a single coherent written form to converge on

**When NOT to use:** Bug fixes, small additive features that fit in a spec section, refactors with no externally observable design change, work that warrants a full new phase (write the phase spec instead), proposals where the current `system-design-docs` already prescribes the answer (just implement it).

## The Canonical Structure

A feature design doc has seven sections. Stay close to this list — the value of the format is partly that reviewers know exactly what to expect.

```markdown
# <Feature Name> — Design Doc

**Authors:** <names>
**Status:** Draft | In Review | Approved | Implemented | Obsolete | Superseded by <link>
**Last updated:** <YYYY-MM-DD>
**Related:**
- System design: <link to docs/design/...>
- Phase spec: <link to docs/specs/...>
- ADRs: <link, link>
- Diagrams: <link to docs/diagrams/...>

## 1. Context and Scope

[Two to four paragraphs. What is the existing landscape? What problem does this
proposal address? What is in scope vs. explicitly out of scope? Why is this
proposal being raised now?]

## 2. Goals

[A short bulleted list — usually 3–6 items. Each is a concrete outcome that
this design must deliver, written so that "did we achieve this?" has a clear
yes/no answer.]

## 3. Non-Goals

[A short bulleted list of things this design deliberately does NOT address.
This section is as load-bearing as Goals — it bounds the review and prevents
scope creep in the design discussion.]

## 4. Design

[The meat of the doc. Subsections as the design demands; a typical shape:

  ### 4.1 Overview
  [One or two paragraphs naming the chosen approach.]

  ### 4.2 <First major component or aspect>
  [Detail.]

  ### 4.3 <Second major component or aspect>
  [Detail.]

  ### 4.4 Data model changes
  [Pseudo-schema, not actual migration SQL. Migration plan if relevant.]

  ### 4.5 API changes
  [New/changed endpoints or function signatures. Request/response shapes.]

  ### 4.6 Diagrams
  [Link to docs/diagrams/*.puml — a Container or Sequence view if structural.]

This section is where most of the doc's length lives. 2–6 pages is normal.]

## 5. Alternatives Considered

[At least two alternatives, ideally three. For each:

  ### Alternative: <name>
  - **Approach:** <one-paragraph description>
  - **Pros:** <bullets>
  - **Cons:** <bullets>
  - **Verdict:** Rejected because <one-line reason>

If you wrote this section after deciding the answer, redo it: the value is in
the genuine comparison. "Do nothing" is a legitimate alternative when the cost
of the proposed change is non-trivial.]

## 6. Cross-Cutting Concerns

[A checklist-style section covering concerns that span the whole design:

  - **Security:** [auth, authz, threat model deltas]
  - **Privacy:** [PII, consent, data retention impact]
  - **Observability:** [metrics, logs, traces, alerts the change introduces]
  - **Scalability:** [load characteristics, hot paths, capacity]
  - **Reliability:** [failure modes, retry semantics, degradation behavior]
  - **Migration:** [rollout plan, backward compatibility, rollback path]
  - **Testing:** [how this will be verified, including any new test categories]
  - **Internationalization / accessibility:** [if user-visible]

Skip a bullet only if it genuinely doesn't apply — but be explicit ("N/A: no
new user-facing surface") rather than omitting the line silently.]

## 7. Open Questions

[Anything unresolved that needs reviewer input. Empty is acceptable; most
docs reach review with at least 1–3 open questions.]
```

## Length Discipline

**1 to 10 pages, with 4–6 pages as the typical sweet spot.** The widely-cited Google rule of thumb: anything longer than about 10 pages stops being read in full, which defeats the purpose of writing it.

When a feature design doc is reaching for 15+ pages, one of three things is happening:

1. **The scope is too large** — this is really a phase, not a feature. Split it: write a phase spec instead, with the design split across multiple feature design docs as needed.
2. **Implementation detail is leaking in** — that belongs in the phase spec, not the design doc. Extract it.
3. **Alternatives Considered is bloated** — name the top three; do not exhaustively catalog every option you considered.

Length is a feature. Reviewers who can read the doc in 20 minutes give better feedback than reviewers who can't finish it.

## Lifecycle and Status

A feature design doc moves through explicit states:

```
Draft  →  In Review  →  Approved  →  Implemented  →  (Obsolete | Superseded)
```

- **Draft** — author is still iterating; not yet shared for formal review.
- **In Review** — circulated to named reviewers; design review meeting scheduled or in flight.
- **Approved** — reviewers have signed off; implementation can begin.
- **Implemented** — the work this doc proposed has shipped. The doc becomes a historical record. Update the status line, add a link to the phase spec section that implements it, do not edit the design content further.
- **Obsolete** — the feature was abandoned or the approach was replaced before implementation. Keep the doc; add a note explaining what happened.
- **Superseded by `<link>`** — a later design doc replaced this one. Keep both; future readers should be able to trace the history.

**Do not edit an Approved or Implemented doc to reflect what actually shipped.** The doc captures what was decided at review time. If the actual implementation diverged in important ways, write a new design doc (or an ADR) recording the divergence.

## Where It Lives

Feature design docs live separately from the evergreen `docs/design/`:

```
docs/design-reviews/
├── README.md                          ← index of all feature designs by status
├── 2026-04-15-rate-limiting-strategy.md
├── 2026-05-02-tenant-isolation-model.md
└── 2026-05-20-webhook-retry-protocol.md
```

- **Date-prefixed filenames** so they sort chronologically.
- **`README.md` index** with one row per doc: date, title, status, link.
- **Distinct directory from `docs/design/`** so the evergreen system design and the point-in-time feature designs don't visually mix.

## Distinguishing From Adjacent Artifacts

| Artifact | Question | Time | Lifecycle | Length |
|---|---|---|---|---|
| **System design doc** | How is the system supposed to fit together as it grows? | Evergreen | Lives; updated as matured shape changes | Whole-system; can be 30+ pages split across files |
| **Feature design doc** *(this skill)* | Should we build this sub-feature, and how? | Point-in-time | Drafted → Reviewed → Approved → Implemented → archived | 1–10 pages |
| **Spec** *(per-phase)* | What are we building this phase, and how do we know it's done? | Per-phase | One per phase; rewritten or replaced when implementation is replaced | Whole-phase; tied to current implementation |
| **ADR** | Why was *this one* decision made? | Decision time | Frozen on acceptance; superseded but not deleted | 1–2 pages |

The cleanest mental model: **the system design says how the system grows; the spec says what we build this phase; a feature design fills in a gap between them when a sub-feature inside a phase needs its own review pass.**

A feature design doc that has been sitting in "Draft" status for three months is a smell — the work either shouldn't happen, or it should be promoted to a phase, or someone needs to schedule the review.

## Workflow

When trigger conditions are met:

```
1. CONFIRM the trigger — re-read the When-to-Use criteria. If any of the four
   "all of these are true" conditions don't hold, skip this skill.
2. DRAFT the seven sections, in order. Status: Draft.
3. SHARE for asynchronous review. Status: In Review. Schedule a design
   review meeting if stakeholders need synchronous discussion.
4. ITERATE on Open Questions; resolve them inline as the doc converges.
5. APPROVE — explicit sign-off from named reviewers. Status: Approved.
6. UPDATE the phase spec to reference the approved design. The spec is what
   the implementation follows; the design doc is the rationale.
7. IMPLEMENT against the spec.
8. ARCHIVE — once shipped, set Status: Implemented, add a link to the phase
   spec section that implements it, freeze the design content.
```

When a previously-approved design needs to change before implementation:

```
1. NOTE the change at the top of the doc with a date, or
2. WRITE a successor design doc and mark this one Superseded by <link>
   (preferred when the change is structural)
```

When a previously-implemented design's reality diverges from what was approved:

```
1. DO NOT edit the implemented design doc — it captures what was decided.
2. WRITE an ADR or a new feature design doc recording the divergence and
   why. The original remains as historical truth.
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "We can just iterate in PR review" | PR review is too late and too narrow. By the time code is in review, half the design space is already foreclosed. |
| "A 4-pager is overhead for a small feature" | If a 4-pager is overhead, the feature isn't trigger-worthy. The trigger filters this out — re-read the When-to-Use list. |
| "I'll write it after I implement it, as documentation" | That's an ADR, not a design doc. The value of a design doc is in forcing the design before code, not after. |
| "We don't need Alternatives Considered, the answer is obvious" | If the answer is genuinely obvious, you don't need a design doc. If you do need a design doc, the answer is not obvious and Alternatives Considered is the section reviewers will read most carefully. |
| "10 pages is too short, this is a complex feature" | Then it's probably a phase, not a feature. Split the design across multiple docs or escalate to a phase spec. |
| "This should live in the system design doc instead" | The system design doc is evergreen and high-level. A point-in-time proposal that names current dependencies and trades off alternatives is the wrong shape for it. Put it here; update the system design only after the work ships and the matured shape has actually shifted. |
| "We approved it verbally in a meeting, no need for a written record" | Six months later, no one remembers the trade-offs that justified the choice. The written doc *is* the record. |

## Red Flags

- A feature design doc longer than 10 pages
- A feature design doc that has been in "Draft" status for more than a month
- A feature design doc that has been in "Approved" but not "Implemented" for more than a quarter (the proposal has gone stale; revisit before building)
- An implemented design doc edited to match what shipped (lost the historical record)
- Alternatives Considered section with one alternative or with alternatives obviously written to lose
- No Non-Goals section, or a Non-Goals section that is empty (scope is unbounded)
- Cross-cutting concerns section with every bullet either skipped or marked "N/A" (the author hasn't actually thought through impact)
- A feature design doc that duplicates content from the system design doc instead of linking to it
- A feature design doc that should have been a phase spec (covers a multi-month effort with multiple components)
- A feature design doc that should have been an ADR (proposes one decision, no real design)

## Verification

Before circulating for review:

- [ ] All seven sections are present (Context & Scope, Goals, Non-Goals, Design, Alternatives Considered, Cross-Cutting Concerns, Open Questions)
- [ ] Status, authors, last-updated, and related-doc links are filled in at the top
- [ ] Doc length is between 1 and 10 pages (~250–2500 lines including code/pseudo-schema blocks)
- [ ] At least 2 alternatives in Alternatives Considered, with genuine pros/cons each
- [ ] Cross-Cutting Concerns covers security, privacy, observability, scalability, reliability, migration, testing — each either addressed or explicitly marked N/A with a reason
- [ ] If structural, a Container or Sequence diagram is linked from §4 (handoff to `architecture-diagrams`)
- [ ] Goals are written so each has a clear yes/no answer at implementation time
- [ ] Non-Goals explicitly bounds scope (not empty, not vague)
- [ ] Stored under `docs/design-reviews/` with a date-prefixed filename
- [ ] Listed in `docs/design-reviews/README.md` with current status

After approval:

- [ ] Status set to Approved with sign-off names recorded
- [ ] The phase spec has been updated to reference this design
- [ ] Implementation tasks have been added to the phase plan

After implementation:

- [ ] Status set to Implemented with a link to the phase spec section that delivered it
- [ ] Design content is no longer being edited (frozen as historical record)
- [ ] If reality diverged from the approved design, a follow-up ADR or new design doc captures the divergence
