---
name: game-godot
description: "Complete guide and toolkit for developing games with the Godot 4 engine (GDScript, 2D and 3D). Covers the recommended stack, project structure, core architecture patterns, performance, testing, dev/export workflows, and ships stdlib-only Python tooling for launch/smoke-check, headless testing, performance summarization, and project validation. Use when the project contains a project.godot file or you are building a Godot game."
---

# Godot Game Development

An opinionated guide and toolkit for building games in **Godot 4** with **GDScript**, covering **2D and 3D**. This file is a lean hub: read the focused reference in `references/` for the area you're working on, and use the stdlib-only Python tools in `tools/`.

This skill is **optional and self-contained**. Other agents (planner, coder, playtester) may use it when the project is a Godot game, but nothing in the squad depends on it — remove, replace, or extend it freely. It satisfies a spec's `## Run Target` and the playtester's launch/capture/perf needs without coupling the rest of the squad to Godot.

## When to use

- The project contains a `project.godot` file at the repo root
- You are scaffolding, implementing, testing, or playtesting a Godot 4 game
- The coder needs build/run/test commands; the playtester needs launch + capture + perf

## The stack

Opinionated, current as of Godot 4.4 (use the latest stable 4.x):

| Concern | Choice | Why |
|---------|--------|-----|
| Engine | Godot 4.x latest stable (4.4+) | Forward+ renderer, mature 2D/3D, single small binary |
| Language | **Typed GDScript** | Native, fast iteration, tight scene/editor integration, no build step, exports everywhere (incl. web/mobile) |
| Testing | **GdUnit4** (primary) | Headless CLI, JUnit XML, mocks, parameterized tests. `GUT` is a lighter GDScript-only alternative |
| Format / lint | **gdtoolkit** (`gdformat`, `gdlint`) | Deterministic formatting + static checks. `pipx install gdtoolkit` |
| Version control | git + `.gitignore` (`.godot/`) + **Git LFS** for binary assets | Keeps the repo lean; `.godot/` is a regenerable cache |
| CI | GitHub Actions: `chickensoft-games/setup-godot` + headless test + export | Reproducible builds/tests on every push |
| Distribution | `export_presets.cfg` + **butler** (itch.io) | Scriptable export + one-command publish |

Install the editor from <https://godotengine.org/download>. Verify: `godot --version`.

## Reference map

Read the relevant file for the task at hand — don't load all of them at once.

| When you're… | Read |
|--------------|------|
| Scaffolding, organizing files, designing nodes/scenes/data/state | `references/architecture.md` (project structure, naming, composition, signals, autoloads, Resources, state machines, input) |
| Building a 2D game | `references/rendering-2d.md` (rendering, physics, tilemaps, camera, animation) |
| Building a 3D game | `references/rendering-3d.md` (rendering, physics, gridmap, navigation, materials/shaders) |
| Hitting frame-rate issues / setting a perf budget | `references/performance.md` (profiler, monitors, optimization) |
| Setting up the dev loop, tests, CI, or export | `references/workflows.md` (dev/test/export/CI, version control) |
| Adding perf logging, screenshots, or debug/cheat hooks | `references/templates.md` (GDScript: PerfLogger, screenshot, debug overlay) |

## Tooling

Python 3 **stdlib-only** (no pip installs). Run any with `-h`. Human-readable by default; `--json` for machine output (playtester/CI). Every tool accepts `--godot <path>` (default `$GODOT_BIN` or `godot`).

> Paths below (`tools/…`) are relative to this skill's directory (`.github/skills/game-godot/tools/`). Run them from there, or copy `tools/` into your game project and run them from the project root.

| Tool | Purpose |
|------|---------|
| `tools/godot_run.py` | Launch (headless / windowed / specific scene), smoke check, scan stderr for `SCRIPT ERROR` / missing resources / parse errors (exit code alone is unreliable), timeout, JSON result |
| `tools/godot_test.py` | Run GdUnit4 (or GUT) headless, surface pass/fail + report path; auto-detects the runner entry point |
| `tools/perf_summarize.py` | Parse a perf CSV (from the `PerfLogger` template) → min / median / p95 FPS + frame-time, with frame-pacing flags |
| `tools/project_check.py` | Validate project structure, naming, autoload references, `.gitignore`, export presets |

## Playtest integration

When the project is a Godot game, this skill satisfies a spec's `## Run Target`:

- **Dev command**: `python tools/godot_run.py --scene <main scene>` (windowed) or `--headless` for CI
- **Smoke check**: `godot_run.py` exits non-zero and reports offending lines on any `SCRIPT ERROR` / missing-resource / parse error, or if the process crashes before the timeout
- **Capture**: `references/templates.md` screenshot helper for deterministic shots; `PerfLogger` + `perf_summarize.py` for performance tables

The `playtest-harness` discovers this skill (or not) at runtime; nothing breaks if it's absent — the harness falls back to invoking the Run Target commands directly.

## References (external)

- Best practices: <https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html>
- Command line: <https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html>
- Debug & profiling: <https://docs.godotengine.org/en/stable/tutorials/debug/index.html>
- GDScript style guide: <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html>
- GdUnit4: <https://github.com/MikeSchulze/gdUnit4> · GUT: <https://github.com/bitwes/Gut>
- gdtoolkit: <https://github.com/Scony/godot-gdscript-toolkit> · setup-godot: <https://github.com/chickensoft-games/setup-godot> · godot-ci: <https://github.com/abarichello/godot-ci> · butler: <https://itch.io/docs/butler/>

## Rules

- **DO NOT** require pip dependencies for the Python tools. Stdlib only.
- **DO NOT** trust Godot's exit code alone — it can return 0 while logging `SCRIPT ERROR`. Always scan output (`godot_run.py` does this).
- **DO NOT** run windowed launches in CI / headless environments — use `--headless`.
- **DO NOT** commit the `.godot/` cache or exported builds.
- **DO NOT** hard-code input keycodes — define actions in the Input Map and read them by name.
- **DO NOT** invent magic numbers in code — model tunable values as exported vars or `Resource` data mapped from `docs/GAME.md`.
- **DO NOT** over-use autoloads or a global event bus; prefer local signals where the relationship is local.
- Pin the Godot version in CI and document it in the project README; engine upgrades are project-level decisions.
- Prefer composition (small reusable sub-scenes/components) over deep inheritance.
- Seed RNG for any test or screenshot that depends on randomness — reproducibility matters for regression.
