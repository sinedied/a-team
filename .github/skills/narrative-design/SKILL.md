---
name: narrative-design
description: "Establish or evolve a game's narrative contract in docs/NARRATIVE.md. Use only for games with story / lore / dialogue ambition. Runs an interview-style discovery on setting, characters, voice, dialogue conventions, and branching policy, locking decisions as they're made."
---

# Create Narrative Design

> **Run as the narrative-designer agent.** If you are not the `narrative-designer` (Tawnia), delegate the entire narrative work to it via the task/agent tool before proceeding. The narrative-designer owns `docs/NARRATIVE.md` end-to-end; running this work from another agent splits canon ownership and risks inconsistent voice.

This skill guides the creation or evolution of a game's narrative contract, captured in `docs/NARRATIVE.md`. **Use only when narrative is actually in scope** — many games ship without one.

## When to use

- `docs/NARRATIVE.md` does not exist and the user explicitly asks for narrative work
- `docs/GAME.md` lists story / lore / dialogue as a pillar and a narrative-bearing feature is on the roadmap
- An existing `docs/NARRATIVE.md` needs to be evolved (new character, new faction, branching policy change, voice refresh)

If none of these apply, push back: a game without narrative ambition does not need this skill.

## Source of truth

`docs/NARRATIVE.md`. Markdown prose. Canonical sections (in this order):

1. **Status** (`defined` / `undefined` / `WIP`) + date
2. **Pitch** (one paragraph — what's the story, in plain language)
3. **Setting** (world, time, place; physical and social rules; what's possible and what isn't)
4. **Lore Foundations** (5-10 durable facts about the world that everything else builds on; not exhaustive history)
5. **Characters** (protagonist, antagonist(s), 3-5 key supporting roles; voice notes per character)
6. **Voice & Tone** (overall narrative voice; pulled from `DESIGN.md`'s voice section with narrative-specific deltas)
7. **Dialogue Conventions** (line length budgets, formatting, parser conventions, second-person vs third-person, localization stance)
8. **Branching Policy** (linear / branching / multi-ending; if branching, how many branches max, when they converge, what determines them)
9. **Spoiler Boundaries** (what's safe for marketing copy; what's plot-critical and must stay hidden)
10. **References** (2-3 narrative reference works — games, books, films — whose tone or structure anchors the direction)
11. **Out of Scope** (e.g. VO if not budgeted; localization if deferred; meta-narrative if rejected)
12. **Open Questions** (must be empty when locked)

## Process

### 1. Confirm narrative is in scope

Before doing anything, verify one of the engagement triggers actually fired. If the user asks for narrative work but the project is clearly mechanic-driven with no story ambition, ask:

> "Is narrative actually a pillar of this game? `docs/GAME.md` doesn't list it. If you want a story layer, we should add it as a pillar there first. Otherwise, this skill isn't the right fit — light flavor text can stay inline in feature specs."

Proceed only if narrative is confirmed in scope.

### 2. Gather context

- Read `docs/GAME.md` in full — narrative must align with pillars and core loop. A game about minute-to-minute combat density rarely supports long expository cutscenes.
- Read `DESIGN.md` — voice section is the starting point for narrative voice. Don't redefine it; build on it.
- Read `docs/specs/roadmap.md` — what features carry narrative weight?
- Read the current `docs/NARRATIVE.md` if it exists.

### 3. Find narrative references

Ask the user for 2-3 reference works (games, books, films) whose tone or structure anchors the direction. Push for specificity:
- Not "fantasy" but "Disco Elysium-style monologue density"
- Not "sci-fi" but "Outer Wilds-style discovery-through-observation"
- Not "noir" but "Pentiment-style historical specificity"

If the user can't name any, propose candidates and confirm.

### 4. Interview the user (small batches, in order)

Ask focused questions **3-5 at a time**, not a wall of 20. Wait for each batch before the next.

**a. Setting & lore foundations**
- World, time, place. Physical and social rules. What's possible / impossible.
- 5-10 lore facts everything else builds on. Not exhaustive history — foundations.
- What's explicitly NOT in this world (no magic? no FTL? no gods? no nation-states?)

**b. Characters & voice**
- Protagonist: who, what they want, what stands in their way.
- Antagonist(s): who, what they want, why it conflicts with the protagonist.
- 3-5 supporting roles, each with one-line voice notes (e.g. "terse, deflects with jokes, hides expertise").
- Overall narrative voice: pull from `DESIGN.md`'s voice section. Document deltas only if there's a clear reason narrative voice should differ.

**c. Dialogue conventions**
- Length budget: max line length (in words), typical exchange length.
- Formatting: scripted lines, barks, ambient overhears. Different conventions per category.
- Person: second-person ("You see...") vs third-person ("She sees..."). Stick to one.
- Localization stance: is this game shipping localized? If yes, push for translatable phrasing (avoid puns, idioms, culture-specific references); if no, write to the project's native voice.

**d. Branching policy**
- Linear / branching / multi-ending. Pick one shape and commit; trying to be all three produces incoherent canon.
- If branching: how many branches max? When do they converge? What determines the branch (choice / state / hidden flag)?
- If multi-ending: how many? What determines the ending (final choice / accumulated state)?
- Critical: branching cost is exponential. Lean toward linear unless the project explicitly wants and can afford branching.

**e. Spoilers & out of scope**
- Which story beats are safe for marketing (Steam page, trailer, devlog)? Which are strict spoilers?
- VO, localization, meta-narrative: in or out for this project? Flag explicitly.

### 5. Iterate on each batch (propose-and-iterate)

Propose **concrete choices, not menus**. Single recommended option per slot with rationale, plus 1-2 alternatives. User accepts, swaps, refines. Loop until the batch is locked.

When the user has no opinion, make a clear recommendation. A locked decision is better than infinite optionality.

### 6. Lock each section as decided

Write into `docs/NARRATIVE.md` as soon as a batch is confirmed. Don't wait until the end. The user can interrupt and resume across sessions.

After each lock, sanity-check the section against `docs/GAME.md` pillars: does it serve them, or does it contradict them? If it contradicts, either revise the section or surface the pillar conflict to the game-designer.

### 7. Voice sample (after structure is locked)

Once Setting / Characters / Voice / Dialogue Conventions are locked, write 3-5 sample dialogue exchanges (one per main character) to validate the voice in practice. Show them to the user; refine until the voice rings true. These samples become the canonical reference for future narrative writing in feature specs.

### 8. Record decisions

Append the meaningful narrative decisions (branching shape rationale, voice direction, key spoiler boundaries) to `docs/memory/decisions.md`. Detail lives in `docs/NARRATIVE.md`; the *why* lives in `docs/memory/decisions.md`.

## Iteration mode

When called to update an existing narrative (rather than create one):

1. Read `docs/NARRATIVE.md` in full.
2. Confirm with the user which sections are in scope.
3. Preserve untouched sections verbatim.
4. Update only in-scope sections; lock each as decided.
5. **Canon check**: if the change contradicts established lore or character voice, surface it. Retconning is allowed but must be intentional and documented in `docs/memory/decisions.md`.
6. Append the change rationale to `docs/memory/decisions.md`.

## Rules

- **DO NOT engage unless narrative is in scope.** This is the most-overused agent if you let it engage on light flavor text. Push back, defer, decline.
- **DO NOT ask 20 questions at once.** Batches of 3-5, in order: setting → characters → dialogue conventions → branching → spoilers.
- **DO NOT propose more than 3 reference works.** Constraint creates voice.
- **DO NOT pick "branching + linear + multi-ending".** One shape, committed. Branching cost is exponential and most projects can't afford it.
- **DO NOT redefine voice from scratch.** Build on `DESIGN.md`'s voice; document only narrative-specific deltas with rationale.
- **DO NOT use generic tropes** ("Chosen One", "ancient evil awakens", "dark forces rise") unless the project explicitly wants pastiche. Push for specificity tied to the project's pillars and references.
- **DO NOT leave `docs/NARRATIVE.md` half-filled with TODOs.** Open Questions section must be empty when locked.
- **DO NOT write VO without flagging localization and recording cost.** Flag VO as out-of-scope if the project hasn't decided on it.
- **DO NOT contradict `docs/GAME.md` pillars.** If pillars don't support a narrative direction, surface the conflict; don't paper over it.
- When the user gives no opinion, make a clear recommendation with rationale. A locked decision beats infinite optionality.
