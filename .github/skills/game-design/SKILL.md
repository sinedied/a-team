---
name: game-design
description: "Establish or evolve a game's design contract in docs/GAME.md. Use when docs/GAME.md is undefined or when the user wants to redefine pillars, core loop, mechanics, economy, progression, or controls. Runs an interview-style discovery, locks decisions into docs/GAME.md as they're made, and produces a coherent game-design contract."
---

# Create Game Design

> **Run as the game-designer agent.** If you are not the `game-designer` (Murdock), delegate the entire game-design work to it via the task/agent tool before proceeding. The game-designer owns `docs/GAME.md` end-to-end; running this work from another agent splits ownership and risks incoherent systems decisions.

This skill guides the creation or evolution of a game's design contract, captured in `docs/GAME.md`. A game without defined pillars and a core loop converges on a bag of disconnected mechanics. Decisions made up front by this skill eliminate that.

## When to use

- `docs/GAME.md` does not exist, or shows `Status: undefined` and the project needs gameplay work
- The user explicitly asks to establish a game design
- The user asks to evolve / iterate on an existing design (new mechanic, balance pass, pillar refinement)
- A feature spec surfaces a systems gap (e.g. new resource type, new progression hook) that must be added to the contract before implementation

## Source of truth

`docs/GAME.md`. Markdown prose. No mandated lint tool (unlike DESIGN.md); the canonical sections enforce consistency.

Canonical sections (in this order):

1. **Status** (`defined` / `undefined` / `WIP`) + date
2. **Pillars** (3-5 max — the things the game must be; non-negotiable)
3. **Target Player** (who this is for, what they expect, what they don't expect)
4. **References** (2-3 named games whose energy / mechanics anchor the direction)
5. **Core Loop** (the 30-second loop the player repeats; the 5-minute loop above it; the session loop above that)
6. **Mechanics** (verbs the player has; inputs that produce them)
7. **Systems** (the durable systems: economy, progression, combat, AI, etc.)
8. **Numbers & Curves** (starting values, ranges, named tuning knobs; rationale per value)
9. **Controls** (input mappings per platform / scheme)
10. **Win / Loss / Progression** (what success looks like; failure handling; metaprogression if any)
11. **Monetization** (if applicable; otherwise explicit "out of scope")
12. **Out of Scope** (what this game is explicitly NOT, to resist scope creep)
13. **Open Questions** (must be empty when locked)

## Process

### 1. Gather context

Before asking the user anything:

- Read the current `docs/GAME.md` to detect new vs. iteration.
- Read `docs/memory/decisions.md`, `docs/specs/roadmap.md` (if present), `README.md` to understand domain and tonal cues already implied.
- If `DESIGN.md` exists, read its Positioning / References sections — visual references often imply tonal expectations for game design (a retro pixel game vs. a moody atmospheric one have different mechanic vocabularies).

### 2. Find reference games

For new game designs, prompt the user for 2-3 reference games whose energy / mechanics anchor the direction. If the user can't name any, propose candidates based on the idea pitch and ask them to confirm.

How to use references:
- Pull concrete elements: core loop shape, control feel, progression cadence, failure handling.
- Same energy, different domain — not the same game.
- Document the references in `docs/GAME.md` so future agents understand the intent.
- Never copy a reference wholesale. Use it to anchor the conversation.

### 3. Interview the user (small batches)

Ask focused questions in **small batches of 3-5 at a time**, never a wall of 20. Do not move to the next batch until the current one is answered. Cover in this order:

**a. Pillars & target player**
- What's the game in 1-2 sentences (idea pitch)?
- 3-5 pillars: the things this game MUST be (e.g. "tight controls", "permadeath has weight", "minute-to-minute decision density", "no narrative gates"). Pillars are non-negotiable; future features must serve them.
- Who is this for? What's a reference player profile?
- What is this game explicitly **NOT** (to resist scope creep)?

**b. Core loop**
- The **30-second loop**: what does the player repeat moment-to-moment (e.g. "see enemy → choose stance → resolve combat → loot")?
- The **5-minute loop** above it: what does each short session segment look like (e.g. "clear a room → spend gold → choose path")?
- The **session loop**: what does a full play session look like (e.g. "run a dungeon → meta-upgrade → start next run")?
- Where does the player meaningfully **choose** (not just react)?

**c. Mechanics & systems**
- Player verbs: 3-7 max. The fewer, the deeper.
- Durable systems: economy? progression? combat? AI? crafting? Pick only what serves the pillars.
- Numbers philosophy: are values discoverable to the player or hidden? Are systems readable at a glance?

**d. Controls & platform**
- Target platform(s) and input schemes (KBM, controller, touch).
- Input mappings per scheme.
- Accessibility considerations (remapping, hold-vs-toggle, input timing windows).

**e. Win / loss / progression / monetization**
- Win condition (per session and overall, if applicable).
- Loss handling (game over, soft-fail, retry, permadeath).
- Metaprogression (what carries between sessions, if anything).
- Monetization (premium / F2P / ads / DLC / none). If undecided, mark Open Question; don't force a choice.

### 4. Iterate on each batch (propose-and-iterate)

Propose **concrete choices, not menus**. Give the user a single recommended option per question with rationale, plus 1-2 alternatives. The user accepts, swaps, or refines. Loop until the batch is locked.

When the user has no opinion, make a clear recommendation. A locked decision is better than infinite optionality.

### 5. Lock each section as decided

Once a batch is decided, write it into `docs/GAME.md` immediately. Do not wait until the end. The user can interrupt and resume across sessions.

After each lock, sanity-check the section against the pillars: does the new content serve them, or contradict them? If it contradicts, either revise the section or revisit the pillar.

### 6. Numbers pass (after structure is locked)

Once Pillars / Core Loop / Mechanics / Systems are stable, fill in starting numbers for tuning knobs (health, damage, costs, rewards, durations). Every number has a rationale, even if the rationale is "starting point for playtesting; expected to tune". The playtester will report observations; you tune accordingly.

### 7. Record decisions

Append the meaningful game-design decisions (pillar choice rationale, core loop shape, reference games and why) to `docs/memory/decisions.md` using the project's decision format. The detailed values live in `docs/GAME.md`; the *why* lives in `docs/memory/decisions.md`.

## Iteration mode

When called to update an existing design (rather than create one):

1. Read the current `docs/GAME.md` in full.
2. Confirm with the user which sections are in scope to change.
3. Preserve untouched sections verbatim. Update only what is in scope.
4. **Sanity-check the change against pillars.** If it breaks one, surface the conflict and either revise the change or revisit the pillar.
5. For balance / numbers changes, route the diff through `reviewer` (the orchestrator applies the standard 2-parallel + consolidation protocol). Balance changes can be subtle; an outside eye catches dominant strategies and economy holes.
6. Append the change rationale to `docs/memory/decisions.md`.

## Rules

- **DO NOT ask 20 questions at once.** Batches of 3-5, in order: pillars → core loop → mechanics → controls → win/loss/monetization.
- **DO NOT propose more than 5 pillars or more than 7 player verbs.** Constraint creates identity. A game that tries to be everything ends up being nothing.
- **DO NOT leave `docs/GAME.md` half-filled with TODOs** after a session. Anything unresolved goes under `## Open Questions` so the next agent knows it's unresolved.
- **DO NOT skip writing to `docs/GAME.md` until the end.** Lock each section as soon as it's decided.
- **DO NOT skip the pillar sanity check.** Every locked section must serve the pillars.
- **DO NOT invent numbers without rationale.** "Starting point for playtesting" is a valid rationale; "felt right" is not.
- **DO NOT design mechanics in a vacuum.** Every mechanic must trace to a pillar and contribute to a loop.
- **DO NOT skip the adversarial review on balance changes.** Numbers compound; a 10% damage change can break the entire progression curve.
- When the user gives no opinion, make a clear recommendation with rationale. A locked decision beats infinite optionality.
