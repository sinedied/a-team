---
name: roadmap
description: "Create or iterate on the project roadmap at docs/specs/roadmap.md. Use when starting a new project, scoping an MVP, or adjusting priorities based on progress, playtest findings, or new requirements. Runs an interview-style discovery, validates an intermediate summary with the user, then locks the roadmap."
---

# Create Roadmap

> **Run as the product-manager agent.** If you are not the `product-manager` (Stockwell), delegate the entire roadmap work to it via the task/agent tool before proceeding. The PM owns `docs/specs/roadmap.md` end-to-end; running roadmap work from another agent splits ownership and risks inconsistent product direction.

This skill guides the creation or iteration of the project roadmap. For games, the roadmap is **milestone-driven** (vertical slice → alpha → beta → 1.0 → post-launch) rather than feature-sprint-driven — milestones are how games actually ship.

A roadmap without a clear milestone cut, dependencies, and rationale produces scope creep and rework. This skill enforces a structured discovery, then locks decisions into `docs/specs/roadmap.md`.

## When to use

- The project has no `docs/specs/roadmap.md` and a high-level idea or vision exists
- The user explicitly asks to create a roadmap
- The user asks to evolve / reprioritize an existing roadmap (after shipped features, playtest findings, or pivots)

## Source of truth

`docs/specs/roadmap.md`. Product-level only — features grouped by milestone, with value, dependencies, ordering, scope boundaries. **No implementation details** — those live in per-feature specs at `docs/specs/<yyyy-mm-dd>_<feature>.md`.

## Milestone shape (games)

Games ship through different production models. Pick one early — milestones differ dramatically between a 48-hour jam and a commercial 1.0 release:

- **Commercial premium (default)**: Vertical Slice → Alpha → Beta → 1.0 → Post-launch. Use this for projects targeting paid release on Steam / itch / consoles.
- **Game jam / prototype**: One milestone (`Submission` or `Prototype`), tightly scoped to the deadline. No alpha/beta phases. Post-jam polish is its own optional milestone.
- **Live service / ongoing**: Soft Launch → Launch → Season N (recurring). "1.0" is the start, not the end. Each season is its own milestone with its own scope.
- **Tool / mod / editor**: Functional → Documented → Released → Community (optional). Less about content density, more about API stability and docs.
- **Educational / sandbox toy**: Playable → Polished → Distributed. Often no "post-launch" — once it's good, it's done.

For non-game projects, fall back to the generic Iteration 1 (MVP) / Iteration 2+ shape.

The delivery model is locked in step 2 of the framing interview; milestone templates flow from it.

## Process

### 1. Preconditions check

Before asking the user anything:
- Read `docs/specs/roadmap.md` if it exists.
  - If present **and** populated → enter **Iteration mode** (skip to the bottom of this skill).
  - If missing or placeholder → enter **Initial creation mode** (continue below).
- Read `docs/memory/decisions.md` for any prior product-level decisions.
- If `DESIGN.md` exists, read its Positioning section for audience/differentiation context (don't ask the user twice).
- Search the codebase briefly to see what already exists (don't assume greenfield if there is shipped code).

### 2. Framing interview (one question at a time)

For new roadmaps, ask the user **one question at a time** and wait for each answer before asking the next. Sequential pacing produces clearer answers than a wall of questions.

In order:

1. **Idea & vision** — What are we building? For games, prompt: pitch, genre, reference games, target platform(s). Mention they can paste from a file if they prefer.
2. **Delivery model** — What's the production model? Pick one:
   - **Commercial premium** (paid release, full alpha/beta/1.0 arc)
   - **Game jam / prototype** (deadline-driven, single milestone)
   - **Live service / ongoing** (post-launch is the main phase, recurring seasons)
   - **Tool / mod / editor** (functional → documented → released)
   - **Educational / sandbox toy** (playable → polished → done)
   - **Non-game** (generic Iteration 1 / 2+ shape)
   The delivery model drives the milestone template in step 3. Default to commercial premium if the user is unsure but the project is clearly a paid release; ask explicitly otherwise.
3. **Audience** — Who is this for? If not obvious from the idea. Skip if already covered.
4. **Constraints** — Any specific constraints? Engine choice, tech stack restrictions, deadlines (Steam Next Fest? game jam? release window?), compliance, accessibility targets, libraries to use/avoid. If none, assume defaults.
5. **First milestone intent** — For commercial: what does the **vertical slice** look like? One scene / level demonstrating every pillar. For jam: what does the submission build contain? For live-service: what does the soft launch include? If the user can't answer, propose a candidate based on the idea and delivery model.

If the project is well-defined from a pitch the user pasted in step 1, you may skip later questions when the answer is already covered. Don't ask redundant questions.

If the project is well-defined from a pitch the user paste in step 1, you may skip later questions when the answer is already covered. Don't ask redundant questions.

### 3. Decompose & propose (propose-and-iterate)

This phase is faster when the AI proposes and the user refines. Don't ask the user to enumerate every feature — derive them from the framing.

1. Break the idea into discrete features. For each:
   - Name and one-line description
   - User value: what problem does it solve
   - UI flag: yes/no — whether the feature has user-facing UI (triggers art-director involvement during planning)
   - Dependencies: which features must come first
   - Scope: what's included, what's explicitly excluded
2. Group features into **milestones** based on the delivery model picked in step 2:

   - **Commercial premium**: Vertical Slice → Alpha → Beta → 1.0 → Post-launch
   - **Game jam / prototype**: Submission (single milestone) → optional Post-jam polish
   - **Live service**: Soft Launch → Launch → Season 1, Season 2, ...
   - **Tool / mod / editor**: Functional → Documented → Released → Community (optional)
   - **Educational / sandbox toy**: Playable → Polished → Distributed
   - **Non-game**: Iteration 1 (MVP) → Iteration 2+

   Each milestone follows the same column structure. Use only the milestones that exist for this delivery model.
   - **Deferred**: explicitly out of scope for now, with rationale
3. Identify **potential challenges** for the riskiest features, each with a **mitigation strategy**.
4. List any **open decisions** the user hasn't committed to (e.g., monetization model, auth provider, hosting choice). Don't block the roadmap on these — surface them so the planner can resolve them later.

### 4. Intermediate summary → user validation

Before writing the final file, present an intermediate summary using the template below and ask the user:

> "Does this match what you want to build? Any features to add, remove, reorder, or move between iterations?"

Loop until the user is satisfied. Make concrete edits between rounds, not abstract acknowledgments.

```md
# Roadmap Proposal: <Project Name>

## Goal
<One-line vision>

## Audience
<Target players (for games) or users>

## Vertical Slice
<!-- For games. Use "Iteration 1 (MVP)" for non-game projects. -->
| # | Feature | Value | UI | Depends on |
|---|---------|-------|----|------------|
| 1 | <Name> | <Why it matters / which pillar it serves> | ✓ / – | – |

## Alpha
| # | Feature | Value | UI | Depends on |
|---|---------|-------|----|------------|

## Beta
| # | Feature | Value | UI | Depends on |
|---|---------|-------|----|------------|

## 1.0
| # | Feature | Value | UI | Depends on |
|---|---------|-------|----|------------|

## Post-launch (planned)
| # | Feature | Value | Depends on |
|---|---------|-------|------------|

## Deferred
- <Feature> — <Why deferred>

## Challenges & Mitigation
| Challenge | Mitigation |
|-----------|------------|

## Open Decisions
- <Decision> — <Why it's open, when it needs to be resolved>
```

### 5. Adversarial review

Once the user accepts the intermediate summary, the PM agent delegates the proposed roadmap to the `reviewer` agent for adversarial review (orchestrator runs the standard 2-parallel + consolidation protocol if available; otherwise self-review).

The reviewer challenges:
- Is the first milestone (vertical slice / MVP) truly minimal? Could it be smaller?
- For games: does the vertical slice actually demonstrate **every** pillar in `docs/GAME.md`? A vertical slice that skips a pillar doesn't prove the game's identity.
- Are dependencies correct? Are any features blocked by missing prerequisites?
- Are there features that overlap and should be merged or split?
- Are challenges adequately covered, or are there missing risks?
- Are open decisions specific enough to be resolvable later?
- For games: is the milestone progression (slice → alpha → beta → 1.0) realistic, or is the scope quietly impossible?

Resolve all findings autonomously, documenting rationale.

### 6. Lock the roadmap

Write `docs/specs/roadmap.md` using the final format below. Update `docs/memory/decisions.md` with any product-level decisions made (palette of audience, MVP scope rationale, deferred-feature reasoning).

```md
# Roadmap: <Project Name>

## Goal
<High-level project vision>

## Audience
<Target players or users>

## Vertical Slice
<!-- For games. Use "Iteration 1 (MVP)" for non-game projects. -->
| # | Feature | Description | UI | Dependencies | Status |
|---|---------|-------------|----|--------------|--------|
| 1 | <Name> | <One-line description> | ✓ / – | – | ⬜ |

## Alpha
| # | Feature | Description | UI | Dependencies | Status |
|---|---------|-------------|----|--------------|--------|

## Beta
| # | Feature | Description | UI | Dependencies | Status |
|---|---------|-------------|----|--------------|--------|

## 1.0
| # | Feature | Description | UI | Dependencies | Status |
|---|---------|-------------|----|--------------|--------|

## Post-launch (planned)
| # | Feature | Description | Dependencies | Status |
|---|---------|-------------|--------------|--------|

## Deferred
| Feature | Rationale |
|---------|-----------|

## Challenges & Mitigation
| Challenge | Mitigation |
|-----------|------------|

## Open Decisions
| Decision | Resolve by |
|----------|------------|

## Product Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
```

Status markers: ⬜ (not started), 🔄 (in progress), ✅ (complete).

## Iteration mode

When invoked with an existing populated `docs/specs/roadmap.md`:

1. Read the current roadmap in full.
2. Read recent specs in `docs/specs/` and playtest logs in `docs/playtest/` to understand what shipped and what surfaced.
3. Ask the user **what triggered the iteration**:
   - A pivot in direction (genre shift, mechanic cut)?
   - Playtest / production findings?
   - New requirements or platform target?
   - Reprioritization based on player feedback?
   - Milestone slip (slice → alpha taking longer than planned)?
4. Propose specific changes (don't rewrite from scratch). For each change, state the rationale.
5. **Mark completed features as `✅` — do NOT remove them.** History matters.
6. Show the diff (added, removed, reordered, status-updated) and ask for confirmation.
7. Send the updated roadmap through adversarial review.
8. Apply the changes and update `docs/memory/decisions.md` with any new product-level decisions.

## Rules

- **DO NOT include implementation details** — that's the planner's job. Features are scoped at the product level (what + why), not the code level (how).
- **DO NOT ask the user to enumerate every feature.** Derive them from the framing, then iterate with them.
- **DO NOT batch the framing questions.** One at a time, in order.
- **DO NOT skip the intermediate summary step.** User must validate before the file is locked.
- **DO NOT skip the adversarial review.**
- **DO NOT leave features vaguely scoped** — each needs clear boundaries (in / out / dependencies).
- **DO NOT create features that overlap in scope** — split or merge them.
- **DO NOT remove completed features** during iteration. Mark them as ✅.
- **DO NOT bloat the first milestone.** Push back when the user includes "nice-to-haves" in the vertical slice / MVP. The first milestone cut is the most valuable decision in the document.
- Keep iterations small and deliverable. Prefer shipping often over shipping big.
- When the user has no opinion, make a clear recommendation with rationale. A locked decision beats infinite optionality.
