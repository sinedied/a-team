---
name: playtest-harness
description: "Engine-agnostic playtest orchestration. Launches the game build via the spec's Run Target, captures screenshots and performance metrics, and writes structured playtest logs to docs/playtest/. Uses any engine-specific helper skill or MCP server available in the project; works without one by invoking the Run Target's commands directly."
---

# Playtest Harness

> **Run as the playtester agent.** If you are not the `playtester` (Lynch), the harness is not for you.

This skill is the engine-agnostic conductor for a playtest session. It launches the build using the spec's `## Run Target` section, performs capture and observation, and writes a structured log the team can act on.

## When to use

- The orchestrator routed a feature to the playtester and a passing Run Target smoke check exists
- The playtester needs to re-run a previously logged scenario for regression
- The playtester needs to capture performance metrics or screenshots for a report

## Source of truth

- `docs/playtest/<feature>_log.md` — durable log of scenarios tested, failure modes probed, balance observations, and issues per feature. Persists across sessions.
- `docs/playtest/screenshots/` — optional, for captured screenshots referenced from logs.
- `docs/playtest/traces/` — optional, for performance traces and profiling data.

## Capability discovery

This harness is engine-agnostic by design. It does **not** depend on any specific helper skill — engine-specific helpers are optional and may be added, removed, or replaced by the user. Before each session, discover what's available in the project, in this preference order:

1. **A project-provided engine-helper skill.** If the project ships one (any skill whose purpose is to launch / capture / probe a specific engine — naming and scope are project-defined), use it. Read its `SKILL.md` to learn its capabilities and invocation surface.
2. **An MCP server matching the runtime** (e.g. browser automation for web games). Use it via its standard tool surface.
3. **Direct invocation of the spec's `Run Target` commands** via the shell. This is always available because the spec must define a Run Target — no helper skill is required.

The harness must work in case 3 alone. Helper skills only add convenience (faster screenshots, structured perf probes, framework-aware state inspection).

## Process

### 1. Pre-flight

Before launching:

- Read the relevant spec in `docs/specs/` (focus on Game Design, Visual Design, Audio Design, Acceptance Scenarios, Playtest Hooks, **Run Target** sections).
- Read `docs/playtest/<feature>_log.md` if it exists — note scenarios already covered.
- Read `docs/GAME.md` to know the pillars and intended feel.
- Verify the spec's `## Run Target` section is complete (dev command, expected URL/executable, smoke check). If it's missing or incomplete, abort and report to the orchestrator — this is a planner gap, not a playtest gap.
- Run the capability-discovery pass above and note which path will be used.

### 2. Launch

Execute the Run Target's dev command. Wait for the expected URL / executable / window to be ready. Run the Run Target's smoke check — if it fails, abort and report a **critical** finding (the build cannot be played).

If a helper skill or MCP server is available, use it for launch instrumentation. Otherwise, drive the launch directly from the shell.

### 3. Run acceptance scenarios

For each scenario from the spec:

1. Set up the scenario state (load save, start at scene X, seed RNG if available)
2. Execute the steps in order
3. Observe the result
4. Capture evidence (screenshot — via helper skill or MCP if available, otherwise the OS screenshot tool against the running window/page)
5. Record pass / fail in the log

### 4. Probe failure modes

Use the spec's Failure Modes table as the starting line, then go further (soft-locks, exploits, edge inputs, state corruption, resource exhaustion). For each probe:

1. Describe what you're attempting
2. Execute (drive input via helper skill / MCP if available, otherwise via the runtime's native input surface)
3. Record whether the mitigation held or the failure mode reproduced
4. Note repro rate (always / sometimes / once)

### 5. Performance capture

Capture (via helper skill / MCP if available, otherwise via the project's exposed debug APIs or runtime profiling tools):

- FPS at rest and FPS under load (run a stress scenario from the spec if provided, otherwise spawn a generic load)
- Frame pacing (consistent vs spiky)
- Load times (initial load, scene transition, save/load if applicable)
- Memory trend over a long session (rough leak check)
- Build size if it has changed materially

Compare against the spec's performance targets in the Constraints section. Flag anything below target. If the runtime exposes no debug API and no helper is available, capture what you can manually and note the limitation in the log — partial data is better than no data.

### 6. Visual & audio capture

- Capture screenshots at key game states; verify visual consistency with `DESIGN.md`
- Verify required audio cues fire (per spec Audio Design section) and don't fire when they shouldn't
- Test at minimum and recommended resolutions / aspect ratios per the project's targets

### 7. Write the log

Append (or create) `docs/playtest/<feature>_log.md` using the format from the `playtester` agent's Output Format. Cross-reference screenshots / traces under `docs/playtest/screenshots/` and `docs/playtest/traces/` with relative paths.

The log is durable: future playtest sessions read it first to re-run prior scenarios for regression. Do not delete entries; append.

### 8. Report

Hand the verdict back to the orchestrator. Pass = ship. Issues = back to coder/game-designer/art-director/planner per each finding's `Suggested owner` field, with the log location and specific finding references.

## Rules

- **DO NOT depend on any specific helper skill being present.** Discover capabilities at runtime; fall back to direct Run Target invocation when no helper is available.
- **DO NOT playtest without a passing Run Target smoke check.** Missing Run Target = planner gap. Failing smoke check = coder gap. Either way, this is a critical finding routed to the orchestrator, not a playtest cycle.
- **DO NOT delete prior log entries.** Append. History matters for regression hunting.
- **DO NOT report subjective feel as a bug.** Use the Balance & Feel observations section in the log; routing is decided per finding's `Suggested owner`.
- **DO NOT capture screenshots / traces without referencing them from the log.** Orphan artifacts are noise.
- **DO NOT make assumptions about performance targets.** Pull them from the spec's Constraints section; if absent, flag as Open Question and capture metrics anyway for baseline.
- When the runtime exposes no debug API and no helper skill is available, capture what you can manually and document the gap. Recommend the coder expose a minimal debug surface (e.g. `window.__debug`) once, rather than blocking the playtest indefinitely.

