---
name: audio-design
description: "Establish or evolve a game's audio direction in docs/AUDIO.md. Use when docs/AUDIO.md is undefined or when the user wants to (re)define SFX vocabulary, music direction, audio cues, mix targets, or VO. Runs an interview-style discovery, locks decisions into docs/AUDIO.md as they're made, and escalates when audio is mechanically load-bearing."
---

# Create Audio Direction

> **Run as the art-director agent.** If you are not the `art-director` (Frankie), delegate the entire audio work to it via the task/agent tool before proceeding. The art-director owns `docs/AUDIO.md` end-to-end; running this work from another agent splits ownership and risks an incoherent soundscape.

This skill guides the creation or evolution of a game's audio direction, captured in `docs/AUDIO.md`. Audio is not decoration — cues are game feel and, in some genres, the mechanic itself. A game without a defined audio vocabulary converges on generic asset-store sound. Decisions made up front by this skill eliminate that.

## When to use

- `docs/AUDIO.md` does not exist, or shows `Status: undefined` and the project needs audio work
- The user explicitly asks to establish or evolve the audio direction
- A feature surfaces an audio gap (new SFX family, a cue with no defined sound, a music state) that must be added to the contract before implementation

## Source of truth

`docs/AUDIO.md`. Markdown prose. Canonical sections (in this order):

1. **Status** (`defined` / `undefined` / `WIP`) + date. If audio is load-bearing, append `audio is load-bearing — deeper treatment required` (see escalation below).
2. **Mood & References** (2-3 reference games/scores whose audio anchors the direction; the feeling audio reinforces — tension, wonder, momentum, dread)
3. **Music Brief** (genre, instrumentation, dynamic layers/states e.g. explore vs combat, procedural vs linear, looping strategy, reference tracks)
4. **SFX Vocabulary** (taxonomy of sound families — UI feedback, player actions, world ambience, enemy signals, impact/feedback — each with a character: punchy / soft / synthetic / organic, plus consistency rules)
5. **Audio Cues → Gameplay** (the gameplay events that MUST have audio reinforcement: low health, ability ready, stealth detection, loot quality. These are game feel, not polish — map each event to an SFX family)
6. **Mix & Accessibility** (loudness target, ducking rules e.g. duck music under dialogue, subtitle policy, and a **visual fallback for every critical audio cue** for d/Deaf players)
7. **Voice / VO** (if applicable: casting tone, recording plan, localization stance, barks vs scripted — otherwise mark out of scope)
8. **Open Questions** (must be empty when locked)

## Process

### 1. Gather context

Before asking the user anything:

- Read the current `docs/AUDIO.md` to detect new vs. iteration.
- Read `DESIGN.md` — the visual mood informs the audio mood; keep them coherent.
- Read `docs/GAME.md` — the mechanics drive which cues are required and whether audio is load-bearing (rhythm, audio-stealth, adaptive score).
- Read recent specs in `docs/specs/` and `docs/memory/decisions.md` for established direction.

### 2. Find audio references

Ask the user for 2-3 reference games/scores whose audio anchors the direction. If they can't name any, propose candidates based on `DESIGN.md` mood and `docs/GAME.md` pillars, and confirm. Pull concrete elements (instrumentation, SFX character, how music responds to state) — never copy wholesale.

### 3. Interview the user (small batches, in order)

Ask focused questions **3-5 at a time**, not a wall of 20. Wait for each batch before the next.

**a. Mood & music**
- 2-3 reference games/scores; what feeling is the audio reinforcing?
- Music genre, instrumentation, and dynamic layering (combat vs exploration); procedural vs linear; looping strategy.

**b. SFX vocabulary**
- The sound families the game needs (UI, player actions, world ambience, enemy signals, impact/feedback).
- For each: character (punchy / soft / synthetic / organic) and consistency rules (e.g. all UI sounds share a tonal family).

**c. Audio cues to gameplay**
- Which gameplay events MUST have audio reinforcement (low health, ability ready, detection, loot quality)? These are non-decorative.
- Map each to an SFX family.

**d. Mix & accessibility**
- Loudness target; ducking rules (e.g. duck music when dialogue plays).
- Subtitle policy; and a **visual fallback for every critical cue** (for d/Deaf players).

**e. Voice / VO (only if relevant)**
- Is there VO? Casting tone, recording plan, localization stance. If undecided or unbudgeted, mark out of scope — don't force it.

### 4. Iterate on each batch (propose-and-iterate)

Propose **concrete choices, not menus**. One recommended option per slot with rationale, plus 1-2 alternatives. The user accepts, swaps, or refines. Loop until the batch is locked. When the user has no opinion, make a clear recommendation.

### 5. Lock each section as decided

Write into `docs/AUDIO.md` as soon as a batch is confirmed — don't wait until the end. The user can interrupt and resume across sessions. After each lock, sanity-check against `DESIGN.md` (mood coherence) and `docs/GAME.md` (every required cue has a sound).

### 6. Load-bearing audio escalation

If audio **is** the mechanic — rhythm games, music-driven games, audio-only stealth, heavy-VO narrative, or adaptive scoring that responds to player state — the default treatment is insufficient:

1. Set the `Status` line to `audio is load-bearing — deeper treatment required`.
2. Expand `docs/AUDIO.md` with the relevant deep sections: timing windows (rhythm), beat-map/tempo authoring pipeline (music games), VO casting/recording/localization plan (VO-heavy), adaptive-layer state machine (adaptive music).
3. **Propose** any audio-mechanic constraints (timing windows, beat maps, adaptive triggers) to the `game-designer`, who updates `docs/GAME.md`; you reflect them in `docs/AUDIO.md`. Never write `docs/GAME.md` yourself.
4. Surface to the user that a sustained load-bearing audio surface may justify a dedicated audio-designer role before adding more audio-bearing features.

### 7. Record decisions

Append the meaningful audio decisions (mood, music direction, SFX vocabulary rules, accessibility approach) to `docs/memory/decisions.md`. Detail lives in `docs/AUDIO.md`; the *why* lives in `docs/memory/decisions.md`.

## Iteration mode

When called to update existing audio direction:

1. Read `docs/AUDIO.md` in full.
2. Confirm which sections are in scope.
3. Preserve untouched sections verbatim; update only what's in scope; lock each as decided.
4. Re-check coherence with `DESIGN.md` and required cues in `docs/GAME.md`.
5. Append the change rationale to `docs/memory/decisions.md`.

## Rules

- **DO NOT** treat audio as polish. Cues mapped to gameplay events are game feel; define them deliberately.
- **DO NOT** ask 20 questions at once. Batches of 3-5, in order: mood/music → SFX vocabulary → cues → mix/accessibility → VO.
- **DO NOT** ship a critical audio cue without a **visual fallback** — accessibility is not optional.
- **DO NOT** write `docs/GAME.md`. For audio-mechanic constraints, propose to the game-designer; you own `docs/AUDIO.md` only.
- **DO NOT** specify exact assets ("use this .wav"). You direct — your output is vocabularies, briefs, and rules; asset production is human/coder-led from your brief.
- **DO NOT** leave `docs/AUDIO.md` half-filled with TODOs — unresolved items go under `## Open Questions`.
- **DO NOT** copy a reference soundtrack wholesale; use references to anchor direction.
- When the user has no opinion, make a clear recommendation with rationale. A locked decision beats infinite optionality.
