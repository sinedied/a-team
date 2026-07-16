<!-- a-team-lite:start -->
# A-Team Lite Workflow

This block is managed by A-Team Lite. Keep project-specific instructions outside
the markers so installer updates can preserve them.

## Core Workflow

1. **Classify**
   - Bug fixes, maintenance, and small isolated changes can proceed directly.
   - Before planning a new product feature, read `docs/specs/roadmap.md`.
   - If the roadmap is missing or the request changes product scope, run the
     `roadmap` skill first. Do not roadmap-gate routine fixes.
2. **Plan**
   - Use Copilot CLI plan mode (`/plan` or Shift+Tab) for non-trivial,
     architectural, or cross-file work.
   - A useful plan states the architecture, ordered changes, validation, and
     acceptance scenarios for user-facing behavior.
   - Keep trivial, well-understood edits out of plan mode.
3. **Critique**
   - Before implementing a non-trivial plan, run the `adversarial-review` skill
     once. It uses Copilot's built-in rubber duck, which selects a contrasting
     GPT/Claude model automatically.
   - Resolve blocking findings before coding. Skip this step for small fixes.
4. **Implement**
   - The main session owns the task. Use built-in explore, task, or coding
     subagents only when they reduce context or execution time.
   - Load specialist skills only when their trigger matches. Do not recreate
     persistent role pipelines.
   - Work on one feature at a time and keep changes scoped to the request.
5. **Validate**
   - For non-trivial or user-facing changes, run the `qa` skill in the main
     session.
   - Run the smallest existing tests, lint, build, and type checks that cover
     the change. Execute acceptance scenarios and browser checks when relevant.
   - Use `/review` for complex diffs and `/security-review` for
     security-sensitive work. Re-run rubber duck only after material plan
     changes, repeated failures, or remaining high risk.
6. **Finish**
   - Update directly affected documentation and shared memory.
   - Commit only when requested or required by the repository workflow.

If a slash command is unavailable, perform the equivalent planning or review
step directly instead of blocking.

## On-Demand Skills

- `roadmap` — product scope, MVP cuts, dependencies, and reprioritization
- `adversarial-review` — high-signal critique through the built-in rubber duck
- `qa` — developer workflows, acceptance, edge-case, browser, and UX testing
- `brand` — establish or evolve `DESIGN.md`
- `frontend-design` — design or implement user-facing interfaces
- `chrome-devtools` — inspect and test a live web application
- `marketing` — positioning, messaging, launch plans, and promo content
- `skill-builder` — create, refine, or retire repeatable project skills

## Shared Memory

The project maintains shared memory in `docs/memory/`:

- `docs/memory/decisions.md` — architectural, product, and design decisions
- `docs/memory/conventions.md` — established implementation conventions

Read both files before making architectural decisions. Append new entries;
never rewrite or remove existing history.

**Decision format:**

```md
### <Decision Title>
- **Date**: YYYY-MM-DD
- **Context**: What prompted this decision
- **Decision**: What was decided
- **Rationale**: Why this choice
- **Alternatives**: What else was considered
```

**Convention format:**

```md
### <Convention Name>
<Clear description with example if helpful>
```

## Visual Identity

`DESIGN.md` is the visual contract. Before non-trivial UI work:

1. Read `DESIGN.md`.
2. If it shows `Status: undefined`, run the `brand` skill first.
3. Run `frontend-design` within the established tokens and patterns.
4. If the feature exposes a gap, update `DESIGN.md` through `brand` before
   inventing a one-off visual rule.

Validate `DESIGN.md` changes with `npx @google/design.md lint DESIGN.md`.
<!-- a-team-lite:end -->
