---
name: poc-production-fidelity
description: Builds POCs, prototypes, and demos so their architecture mirrors what production would look like — keeping interface boundaries and data ownership intact while deliberately simplifying runtime, durability, and operational depth. Use when starting a POC for a system that has a credible path to production, when building a walking skeleton or tracer-bullet implementation, when a demo will be evaluated by stakeholders who need to see the production shape. Distinct from a throwaway prototype (no productionization path) and a production build (no deliberate simplifications). Pairs with system-design-docs (which captures the matured shape this POC is a simplification of) and spec-driven-development (the per-phase implementation contract).
---

# POC Production Fidelity

## Overview

The standard failure mode of a POC is that it ships fast by collapsing the architecture into shapes that can't be productionized without a rewrite — services merged into one module, interfaces deleted because "there's only one implementation," data ownership boundaries dissolved because "we have one DB anyway." Six months later the team is staring at a successful demo that has to be redesigned from scratch to ship for real.

A production-fidelity POC takes the opposite trade. It keeps the architectural boundaries production would have — service seams, contract interfaces, data ownership, the auth model in some form — and **simplifies runtime, durability, and operational depth** instead. The result is slower to build than a maximally-collapsed prototype but faster to productionize, because every simplification has been chosen to lift independently.

The intellectual lineage is well-established: Alistair Cockburn's **walking skeleton** (a tiny end-to-end implementation that exercises every major architectural piece), the Pragmatic Programmers' **tracer bullet** (the same idea framed as iterative aim), and the broader **steel thread** pattern. C4 model adopters call it the same thing the C4 model calls it: containers and components are an architectural choice independent of deployment topology. This skill makes that pattern an explicit step inside the design and spec phases.

This skill sits between `system-design-docs` and `spec-driven-development`:

```
system-design-docs (matured shape, all phases visible)
   └─→ poc-production-fidelity (this skill — decide what v1 simplifies and how)
          └─→ spec-driven-development (Phase 1 implementation contract)
                 └─→ plan → tasks → build → test → ship
```

## When to Use

Trigger when *all* of these hold:

- The work is explicitly a POC, prototype, MVP, or demo — not a production launch
- The system has a credible path to production (not a throwaway script)
- A `system-design-docs` artifact exists or is being authored, describing the matured shape
- The team will decide *which* production properties to keep and *which* to simplify, and wants the trade-offs explicit

Concrete signals:

- A stakeholder demo where the demo's architecture will inform the production architecture
- A walking-skeleton or tracer-bullet build kicking off Phase 1 of a multi-phase plan
- A POC that has been described as "we'll productionize it later" — this is the moment to make "productionize" tractable
- A demo of a system whose value depends on production-shaped properties (multi-tenancy, identity, consent, audit) being visibly real, not faked

**When NOT to use:** Throwaway scripts, internal tools that will never leave a single team, prototypes built to invalidate an idea (where rewriting is expected and fine), spike work explicitly scoped as disposable, production launches (no deliberate simplifications — use `spec-driven-development` and `shipping-and-launch` directly).

## The Core Principle

**Architectural boundaries are independent of runtime topology.** A system with two services and a queue between them can run as one process with an in-memory queue and still be "two services with a queue between them" architecturally — provided the contract that crosses the seam is real and adapters don't reach across.

This is the load-bearing distinction. Most "POC simplifications" that cause rewrites confuse the two: they collapse the *architecture* when all they needed to collapse was the *runtime*.

| Layer | What it is | Acceptable to simplify in a POC? |
|---|---|---|
| **Interface boundaries** | Contracts between components (function signatures, API shapes, port definitions) | **No.** These are the seams you'll need at production. Keep them. |
| **Data ownership** | Which component is the source of truth for which entities | **No.** Crossed ownership is the hardest thing to untangle later. |
| **Runtime topology** | What process / host / container each component runs in; how they talk | **Yes.** Multi-process → single process, HTTP → in-process call, separate DB → shared DB-with-schema-isolation. |
| **Durability** | Queues, retries, replay, dead-letter, circuit breakers | **Yes.** First-failure-terminal is acceptable; document the gap. |
| **Operational depth** | Multi-tenancy, auth/authz, observability stack, rate limits | **Yes — to a shape, not to zero.** Single-tenant, owner-field instead of auth, console logs instead of structured tracing. |
| **Scale characteristics** | Sharding, caching, read replicas, async I/O patterns | **Yes.** Tens of records, single instance, sync I/O. |

The test for any proposed simplification: *can this be lifted independently, without restructuring the components around it?* If yes, simplify. If no, you're collapsing an architectural boundary — push back.

## The Simplification Menu

A POC almost always wants some subset of these. Pick deliberately; each row is a simplification with a documented path back to production:

| Production property | POC simplification | Promotion path |
|---|---|---|
| Multiple deployable services with HTTP/RPC between them | Single process, in-process function calls across the same interface | Promotion is a transport change behind a stable interface; component code unchanged |
| Durable queue between producer and consumer | In-memory pass-through; producer calls consumer directly | Insert the queue impl behind the same contract; producer and consumer code unchanged |
| Async event handling with at-least-once delivery | Synchronous fan-out; first-failure-terminal | Add the queue/worker layer; events emit to it instead of direct call |
| Per-tenant data isolation | Single-tenant; `tenant_id` column exists but is always the same value | Lift to row-level security or schema-per-tenant; the column is already there |
| Real authn + authz | "Owner" field on records; no auth check enforced | Replace owner-check with policy decision point; row shape unchanged |
| Versioned, snapshot-based entities | Flat entity; live reads at use time | Add version column + snapshot writer; readers move to "as of" queries |
| Structured retries, circuit breakers, DLQ | First-failure-terminal; failures land in the same execution log as successes | Promote retry handling into a coordinator; intent vs. attempt split made first-class |
| Decision/audit log separate from execution log | Execution log carries audit; no separate decision rows | Add decision-log writer at the gate; execution log narrows back to attempts |
| Observability stack (metrics, traces, structured logs) | Console logs + a single demo dashboard | Wire OTel emitters at the same boundaries the logs already use |
| Provider-grade integration (SendGrid, Twilio, etc.) | Provider sandbox or stub adapter implementing the same contract | Swap the adapter; engine code unchanged because adapter is service-shaped |

Two rules govern this menu:

1. **Every row picked must be documented** — named in the design's "v1 collapses" table (see `system-design-docs`), with its production replacement described. A simplification you didn't write down isn't a deliberate trade; it's a debt.
2. **No row should require collapsing an interface boundary or data-ownership boundary.** If a proposed simplification only works by deleting an interface or merging ownership, redesign the simplification.

## What "Service-Shaped" Means

The hardest-to-untangle production properties involve services and the contracts between them. A POC can keep "service-shaped" architecture without paying for multiple processes:

- **One interface per service.** Even if the service is one file with three functions, the interface is the surface the rest of the system depends on.
- **Adapters never read the trigger / subject / consent / tenant data directly.** They receive a typed value through the contract. This is the property that lets you promote in-process to RPC without rewriting adapter logic.
- **Each "service" owns its own state.** Even if all services share one Postgres instance, each owns its tables; no service reads or writes another's tables directly.
- **Cross-service calls go through the contract**, even when both sides live in the same process. `adapter.submit(intent)` not `internalDispatchHelper(adapter, intent)`.
- **The contract is versionable.** Adding a field to a `DeliveryIntent` is a contract change, with the same review weight it would have if the boundary were over a network.

This pattern is sometimes called the **modular monolith** (Simon Brown, Kamil Grzybek). The POC is one process; production may be many; the architecture is the same.

## Templates

### Documenting POC simplifications

In the system design doc (`docs/design/architecture.md`), include a section at or near the end:

```markdown
## What v1 (POC) deliberately collapses

The matured design includes pieces that the POC consciously simplifies.
Each is a choice documented here and (where weighty) in an ADR. None
collapses an interface boundary or data-ownership boundary.

| Matured property | POC simplification | Lifted in |
|---|---|---|
| Durable queue + workers between engine and adapters | In-process synchronous fan-out across the same `ChannelAdapter` contract | `reliability` phase |
| `DispatchIntent` + `DispatchAttempt` split | Single execution row per attempt; sealed on first terminal status | `reliability` phase |
| Retry coordinator + circuit breaker | First failure is terminal | `reliability` phase |
| Versioned consent records with provenance, jurisdiction, purpose | Boolean `granted` per `(subject, consent_string)` | `identity-depth` phase |
| Policy gate (caps, quiet hours, suppression, priority) | None — every dispatch the consent gate allows runs | `policy` phase |
| Real authn + actor model | Owner field on triggers; no auth | `policy` phase |
| Decision log (every consideration) | Execution log doubles as audit | `policy` phase |

Each collapse preserves the matured shape's contracts so that lifting is
additive, not a rewrite.
```

The **"none collapses an interface boundary or data-ownership boundary"** clause is the load-bearing claim. If you cannot write it truthfully, the POC has taken on debt it does not yet know about.

### A walking-skeleton checklist

Before writing implementation code, confirm the POC's first end-to-end slice exercises every architectural seam at least once:

- [ ] The public API surface (one endpoint is enough)
- [ ] The domain layer / engine (one operation is enough)
- [ ] Each store interface the design names (read or write, doesn't matter)
- [ ] Each adapter interface the design names (one happy-path call each)
- [ ] The realtime / output surface (one event, even a logged one)
- [ ] The persistence layer (one round-trip)

A walking skeleton with a missing seam is a partial skeleton — productionization will surface the missing seam at the worst possible moment.

## Distinguishing From Adjacent Artifacts

| Concept | What it is | Relationship |
|---|---|---|
| **POC / prototype / MVP** | The artifact being built. POC = prove the design; MVP = prove the value; prototype = explore the shape. This skill treats them similarly; the production-fidelity bar applies if there's a credible production path. | Output of this skill |
| **Walking skeleton / tracer bullet** | The implementation *pattern* this skill prescribes: thin end-to-end first, depth second | Technique inside the skill |
| **Spike** | Deliberately-disposable code to learn something specific | Skip this skill; spikes are not productionized |
| **Modular monolith** | Production-shape modules deployed as one process | The runtime simplification this skill points at |
| **Throwaway prototype** | Disposable code built to invalidate an idea | Skip this skill — productionization is not the goal |

The cleanest line: **a POC that someone will look at and say "ship that" needs production fidelity; a POC built to be thrown away does not.**

## Workflow

When starting a POC:

```
1. CONFIRM the trigger — does this POC have a credible production path?
   If no, this skill does not apply.
2. AUTHOR or LOAD the system design doc (system-design-docs skill) describing
   the matured shape across all phases.
3. PICK simplifications from the menu. For each, confirm it does not collapse
   an interface boundary or data-ownership boundary.
4. DOCUMENT every chosen simplification in the design doc's "v1 collapses"
   table, with the phase that lifts it.
5. AUTHOR a walking-skeleton checklist of seams the first end-to-end slice
   must exercise.
6. HAND OFF to spec-driven-development for the Phase 1 spec.
```

When a simplification is challenged ("can we just merge those two services?"):

```
1. IDENTIFY which layer the proposed simplification touches (use the layer
   table). Runtime/durability/operational? Probably fine. Interface or
   ownership? Push back.
2. NAME the promotion cost — what would have to change to lift this in
   the relevant phase?
3. PROPOSE the alternative simplification at the runtime layer if possible
   ("don't merge the services — run them in one process; same contract").
4. RECORD the decision (ADR if weighty; design doc note if light) regardless
   of outcome.
```

When the POC ships and Phase 2 begins:

```
1. RE-READ the "v1 collapses" table.
2. For each row whose phase is starting: lift the simplification per its
   promotion path. The interface stays; the implementation behind it changes.
3. UPDATE the design doc and the new phase's spec.
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It's just a POC, we'll productionize later" | "Later" is the problem. Without explicit fidelity rules, the POC takes on architectural debt that turns "productionize" into "rewrite." |
| "Interfaces are overkill for a single implementation" | The interface is what lets you add the second implementation (the real provider, the durable queue, the multi-tenant variant). Deleting it now is paying for speed with a future rewrite. |
| "We have one DB, so data ownership doesn't matter" | One DB is fine. Multiple owners reading each other's tables is not. The boundary is logical, not physical. |
| "Multi-tenancy can be retrofitted" | Single-tenancy with a `tenant_id` column that's always the same value can be retrofitted in an afternoon. Single-tenancy with no tenant concept anywhere requires touching every query, every cache key, every authorization check. The column costs nothing now. |
| "Auth is too much for a POC" | An owner field is not too much. Deleting the concept of identity entirely is what makes auth retrofit expensive. |
| "We need to move fast; this is too much process" | Pick three simplifications from the menu and write them down. That's the process. It's ~15 minutes and saves weeks. |
| "Service-shaped is microservices premature optimization" | Service-shaped is *interfaces*, not deployment. The POC ships as one process. The architecture stays modular. |
| "The design doc already says this is matured-shape; we don't need a v1 collapses table" | Without the table, the gap between matured and shipped is implicit. The table is what makes Phase 2 planning possible without re-reading every line of the design doc. |

## Red Flags

- A POC where two design-doc services live as one undifferentiated module with no interface between them
- An adapter or "service" that reads another component's tables directly because "we own them all"
- A POC that has no `tenant_id`, `owner_id`, or equivalent identity column anywhere — and the production design calls for multi-tenancy or auth
- A "v1 simplification" that requires changing an interface signature to lift (the simplification has collapsed the wrong layer)
- An end-to-end walking-skeleton slice that does not exercise one of the architectural seams the design names
- A POC that has accumulated three or more simplifications no one wrote down
- Stakeholders treating the POC as production-ready because it "demos like the real thing" — production fidelity has succeeded in shape, but operational depth hasn't been promoted
- A productionization estimate that involves "moving X out of Y" as a major task — that's an architectural-boundary collapse coming due
- POC code that imports concrete adapters or stores directly from engine code, bypassing the interface
- A POC with a `// TODO: this is hardcoded for v1` comment where the production design has a real abstraction — fine *once*, a smell at three or more

## Verification

Before the POC implementation begins:

- [ ] A system design doc exists and describes the matured shape (handoff to `system-design-docs`)
- [ ] Every simplification chosen for the POC is named in a "v1 collapses" table with its production replacement and the phase that lifts it
- [ ] No simplification collapses an interface boundary
- [ ] No simplification collapses a data-ownership boundary
- [ ] The walking-skeleton slice exercises every architectural seam the design names
- [ ] Multi-tenancy / identity / auth: the design's concept is *present in shape* (column, field, owner reference), even if simplified to a placeholder
- [ ] Each "service" the design names has an interface in the POC code, even if it lives in one process
- [ ] Adapter / provider integrations go through the contract; no adapter reads from a store it doesn't own
- [ ] The promotion path for each simplification is documented and additive (no rewrite required)

When the POC is reviewed for productionization:

- [ ] No new simplification has been introduced that isn't in the table
- [ ] No interface has been removed since the POC started
- [ ] No cross-component data access has crept in
- [ ] Each row in the "v1 collapses" table either is still acceptable for the next phase, or is scheduled to be lifted in this phase
- [ ] The walking-skeleton seams are all still real seams — they have not been collapsed into helper functions or merged into one mega-component
