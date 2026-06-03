# Project Guidelines

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
Before any UI or visual work, read `DESIGN.md`. If `Status: undefined`, no visual identity has been established — the `art-director` agent (Frankie) must establish it before non-trivial visual work proceeds.

### Writing
Only the `art-director` agent writes to `DESIGN.md`. Other agents flag gaps back to the art-director instead of editing the file directly. Validate edits with `npx @google/design.md lint DESIGN.md`.

## Game Design

`docs/GAME.md` is the canonical game-design contract for the project: pillars, target player, core loop, mechanics, systems, numbers, controls, win/loss, monetization, out-of-scope.

### Reading
Before any gameplay work, read `docs/GAME.md`. If absent or `Status: undefined`, the `game-designer` agent (Murdock) must establish it before any gameplay feature is planned.

### Writing
Only the `game-designer` writes to `docs/GAME.md`. Other agents flag systems gaps back to the game-designer instead of editing the file directly.

## Audio Direction

`docs/AUDIO.md` is the canonical audio contract: SFX vocabulary, music brief, audio cues, mix targets.

### Reading / Writing
Before any audio-bearing work, read `docs/AUDIO.md`. Only the `art-director` agent writes to it.

## Narrative *(optional)*

`docs/NARRATIVE.md` is the canonical narrative contract (setting, lore, characters, voice, dialogue conventions, branching policy). It only exists for games with narrative ambition.

### Reading / Writing
If the project has a story / lore / dialogue pillar, read `docs/NARRATIVE.md` before writing any player-facing text beyond UI strings. Only the `narrative-designer` agent (Tawnia) writes to it. The agent is on-demand only — not invoked for narrative-light games.

