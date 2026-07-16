<!-- A-TEAM:START (managed block — the installer updates everything between these markers; add your own project notes outside them) -->
# Project Guidelines

This is the **lite** A-Team: one agent, a playbook, and on-demand skills — no subagent
relay. You (the primary agent) run the whole workflow yourself, using **plan mode** and
**/rubber-duck** where available, and pulling **skills** only when a task needs one. The
speed and token savings come from *not* handing work between specialized agents.

> Optimized for GitHub Copilot CLI (plan mode, `/rubber-duck`). On other agents, fall back
> to the inline equivalents noted below (plan inline, self-review pass).

## Workflow

Follow this loop. Keep **one feature in flight at a time** — finish and commit before
starting the next.

1. **Roadmap first (new project or reprioritization).** If there's no `docs/specs/roadmap.md`,
   or priorities changed, use the **`roadmap`** skill to create/iterate it. The roadmap is
   the one upfront planning gate; individual features are cut from it.

2. **Plan the feature.** Use **plan mode** (or plan inline). For anything non-trivial, shape
   the plan like a spec:
   - **Problem** — what and why.
   - **Approach** — architecture, data flow, integration points, with rationale.
   - **Design (UI features)** — layout, user flow, component states (default/hover/active/
     disabled/error/loading), responsive behaviour, accessibility, and reuse of existing
     patterns. Pull `brand` (visual system) + `frontend-design` (implementation) here. Skip
     for non-UI work.
   - **Subtasks** — ordered, each with a clear definition of done.
   - **Acceptance scenarios** — concrete, independently testable steps + expected results
     (these drive the verify step). Include a **Setup** (commands/data/services) and, for UI,
     the views/states/breakpoints to check.
   - **Decisions** — resolve every open question; no "TBD" in a finalized plan.
   Persist the plan as a durable spec to `docs/specs/<yyyy-mm-dd>_<feature>.md`.

3. **Implement.** Work subtasks in order. Read existing code first; make surgical changes;
   build/lint/test as you go. Pull `brand` + `frontend-design` for UI/visual work (see below).
   Don't leave dead code, debug logs, or commented-out blocks.

4. **Review (static) — cross-model.** Launch a **rubber-duck review** for a diverse
   perspective, preferring the **opposite-provider SOTA model at `xhigh` reasoning**:
   - current model is **Claude → review with the best current GPT**;
   - current model is **GPT → review with the best current Claude**.
   Invoke it via the review agent / Task tool with that model override where the runtime
   supports it; otherwise run `/rubber-duck` (Copilot may auto-select a contrasting model), and
   if neither is available, do a focused self-review pass. Review criteria: is there a simpler
   approach? unhandled failure modes? security? missing edge cases? contradicts `docs/memory`?
   **Act on Blocking findings and high-confidence correctness/security issues; ignore style and
   nitpicks** (linters own those).

5. **Verify.** Distinct from the static review: actually run it. Use the
   **`qa`** skill for the checklist (dev-workflow commands, happy paths, edge cases, and for
   web UI the `chrome-devtools` skill). Run every acceptance scenario. Dev-workflow failures
   (can't install/build/run) are critical.

6. **Fix + commit.** For each review/QA finding, fix the root cause **and add a regression
   test** that reproduces it. **A substantive fix resets both gates** — re-run the static
   review (step 4) and verify (step 5) against the latest revision. Only when both pass, commit
   with a conventional-commit message (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`,
   `style:`, `perf:` — lowercase, imperative, one line). One commit per completed feature/fix.
   Update `docs/memory/` if the work established a new decision or convention.

## Skills (on-demand)

Load a skill only when its trigger matches — don't pull them for one-off tasks you already
handle well.

| Skill | Use when |
|-------|----------|
| `roadmap` | Starting a project or reprioritizing — create/iterate `docs/specs/roadmap.md`. |
| `brand` | Establishing or evolving the visual identity in `DESIGN.md` (before non-trivial UI). |
| `frontend-design` | Building UI — for distinctive, production-grade interfaces that avoid generic AI aesthetics. |
| `marketing` | Positioning, messaging, landing/promo copy → `docs/marketing/`. Mostly on request or at MVP. |
| `qa` | Verifying a build works from a user's perspective (the verify step). |
| `skill-builder` | Capturing a repeatable workflow as a new skill, or refining/retiring one. |
| `chrome-devtools` | Driving a real browser for web verification (used by `qa`). |

## Shared Memory

The project maintains shared memory in `docs/memory/`:

- `docs/memory/decisions.md` — Architectural and design decisions
- `docs/memory/conventions.md` — Established project conventions

### Reading
Before making architectural decisions or proposing changes, check existing decisions and conventions for prior context.

### Writing
When a new decision is made or convention established:
1. Read the current file
2. Append the new entry at the end
3. Do not modify or remove existing entries

**Decision format:**
```
### <Decision Title>
- **Date**: YYYY-MM-DD
- **Context**: What prompted this decision
- **Decision**: What was decided
- **Rationale**: Why this choice
- **Alternatives**: What else was considered
```

**Convention format:**
```
### <Convention Name>
<Clear description with example if helpful>
```

## Visual Identity

`DESIGN.md` at the repo root is the canonical visual contract for the project. It follows Google's [DESIGN.md spec](https://github.com/google-labs-code/design.md) — YAML token frontmatter plus markdown prose, with non-canonical extension sections (Voice, Motion, Positioning, References).

### Reading
Before any UI work, read `DESIGN.md`. If `Status: undefined`, no visual identity has been established — use the **`brand`** skill to establish it before non-trivial UI work proceeds.

### Writing
`DESIGN.md` is maintained through the **`brand`** skill. Validate edits with `npx @google/design.md lint DESIGN.md`.

## Notes

- Lite drops the full squad's **2-parallel + consolidation** review protocol; it keeps the
  single cross-provider `/rubber-duck` pass (step 4) for diverse perspective at a fraction of
  the cost.
- No custom subagents ship with lite. If you want a repeatable specialized workflow, capture
  it as a skill with `skill-builder` rather than hand-rolling it each time.
<!-- A-TEAM:END -->


