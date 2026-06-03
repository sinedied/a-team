---
name: playtest-harness
description: "Engine-agnostic playtest orchestration. Coordinates launching the game build, capturing screenshots and performance metrics, and writing structured playtest logs to docs/playtest/. Delegates engine-specific launch/capture to engine-godot, engine-web-2d, or engine-web-3d skills based on the project."
---

# Playtest Harness

> **Run as the playtester agent.** If you are not the `playtester` (Lynch), the harness is not for you. Engine-specific skills (`engine-godot`, `engine-web-2d`, `engine-web-3d`) may be invoked by the coder for tooling, but the orchestrated playtest flow belongs to Lynch.

This skill is the engine-agnostic conductor for a playtest session. It detects the project's engine, delegates launch and capture to the matching engine skill, and writes structured logs the team can act on.

## When to use

- The orchestrator routed a feature to the playtester and a runnable build exists
- The playtester needs to re-run a previously logged scenario for regression
- The playtester needs to capture performance metrics or screenshots for a report

## Source of truth

- `docs/playtest/<feature>_log.md` — durable log of scenarios tested, failure modes probed, balance observations, and issues per feature. Persists across sessions.
- `docs/playtest/screenshots/` — optional, for captured screenshots referenced from logs.
- `docs/playtest/traces/` — optional, for performance traces and profiling data.

## Engine detection

Detect the project's engine before launching. Check in order:

1. `project.godot` at the repo root → **Godot** → use `engine-godot` skill
2. `package.json` with `phaser`, `pixi.js`, `kaboomjs`, or 2D canvas dependencies → **Web 2D** → use `engine-web-2d` skill
3. `package.json` with `three`, `@babylonjs/core`, or WebGL/WebGPU 3D dependencies → **Web 3D** → use `engine-web-3d` skill
4. Unknown engine → ask the user how to launch the build (command, URL, executable path), proceed with manual launch and best-effort capture

If multiple engines are present (e.g. a Godot project with a Three.js web preview), ask the user which surface to playtest.

## Process

### 1. Pre-flight

Before launching:

- Read the relevant spec in `docs/specs/` (focus on Game Design, Visual Design, Audio Design, Acceptance Scenarios, Playtest Hooks sections).
- Read `docs/playtest/<feature>_log.md` if it exists — note scenarios already covered.
- Read `docs/GAME.md` to know the pillars and intended feel.
- Verify a runnable build artifact exists. If not, abort and report to orchestrator (this is a coder problem, not a playtest problem).

### 2. Launch via engine adapter

Invoke the matching engine skill to launch the build with the right scene / URL / save state. The engine skill returns:

- A live handle (process / page / window) the harness can interact with
- Any startup errors / warnings (parse failures, missing assets, missing scenes)

If launch fails, that's a **critical** finding — log it and stop. There is nothing to playtest against a broken build.

### 3. Run acceptance scenarios

For each scenario from the spec:

1. Set up the scenario state (load save, start at scene X, seed RNG if available)
2. Execute the steps in order
3. Observe the result
4. Capture evidence (screenshot via engine adapter; for native engines, the engine skill handles capture; for web, use `chrome-devtools` via the web engine skills)
5. Record pass / fail in the log

### 4. Probe failure modes

Use the spec's Failure Modes table as the starting line, then go further (soft-locks, exploits, edge inputs, state corruption, resource exhaustion). For each probe:

1. Describe what you're attempting
2. Execute
3. Record whether the mitigation held or the failure mode reproduced
4. Note repro rate (always / sometimes / once)

### 5. Performance capture

Through the engine adapter, capture:

- FPS at rest and FPS under load (run a stress scenario from the spec if provided, otherwise spawn a generic load)
- Frame pacing (consistent vs spiky)
- Load times (initial load, scene transition, save/load if applicable)
- Memory trend over a long session (rough leak check)
- Build size if it has changed materially

Compare against the spec's performance targets in the Constraints section. Flag anything below target.

### 6. Visual & audio capture

Through the engine adapter:

- Capture screenshots at key game states; verify visual consistency with `DESIGN.md`
- Verify required audio cues fire (per spec Audio Design section) and don't fire when they shouldn't
- Test at minimum and recommended resolutions / aspect ratios per the project's targets

### 7. Write the log

Append (or create) `docs/playtest/<feature>_log.md` using the format from the `playtester` agent's Output Format. Cross-reference screenshots / traces under `docs/playtest/screenshots/` and `docs/playtest/traces/` with relative paths.

The log is durable: future playtest sessions read it first to re-run prior scenarios for regression. Do not delete entries; append.

### 8. Report

Hand the verdict back to the orchestrator. Pass = ship. Issues = back to coder with the log location and specific finding references.

## Rules

- **DO NOT skip engine detection.** Wrong engine adapter = wrong launch command = wasted session.
- **DO NOT playtest a broken build.** Missing build artifact or failed launch is a critical finding routed to coder, not a playtest cycle.
- **DO NOT delete prior log entries.** Append. History matters for regression hunting.
- **DO NOT report subjective feel as a bug.** Use the Balance & Feel observations section in the log; the game-designer decides what to tune.
- **DO NOT capture screenshots / traces without referencing them from the log.** Orphan artifacts are noise.
- **DO NOT make assumptions about performance targets.** Pull them from the spec's Constraints section; if absent, flag as Open Question and capture metrics anyway for baseline.
