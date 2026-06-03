---
name: engine-godot
description: "Launch and inspect a Godot project for playtesting and dev workflows. Headless or windowed runs, scene-specific launches, screenshot capture, FPS / frame-time logging, export builds. Use when the project contains a project.godot file."
---

# Godot Engine Adapter

This skill provides the launch / capture primitives for Godot projects. It is invoked by the `playtest-harness` skill (for playtester sessions) and can be used directly by the coder for build / lint / export tasks.

## Prerequisites

- A `godot` executable on `PATH`, or the project specifies a path in its README. Verify with:

  ```sh
  godot --version
  ```

  If absent, instruct the user to install Godot from <https://godotengine.org/download> matching the project's required version (read `project.godot`'s `config_version` and the project's README for the Godot version).

- A `project.godot` at the repo root. If absent, this skill is not applicable.

## Common operations

### Import the project (first run)

Godot must import assets before the project can run headlessly. Do this once after fresh clone or after large asset changes:

```sh
godot --headless --import
```

Wait for completion. Errors here indicate broken resource references and must be surfaced to the coder.

### Launch the full game (windowed, default scene)

```sh
godot --path .
```

### Launch a specific scene (windowed)

```sh
godot --path . scenes/<scene_name>.tscn
```

Useful for jumping straight into a feature's scene rather than navigating menus.

### Headless run (CI / capture)

```sh
godot --headless --path . --main-pack <pack> --quit-after <frames>
```

Headless mode is required in environments without a display server. Use `--quit-after N` to run for N frames then exit cleanly (useful for smoke-launch tests in CI).

### Screenshot capture

Godot does not have a one-liner screenshot CLI. Use one of:

1. **In-engine debug hotkey**: if the project includes a debug screenshot script bound to a key, trigger it via the engine console. Document the binding in the playtest log.
2. **Programmatic capture**: invoke `get_viewport().get_texture().get_image().save_png(path)` via the GDScript console or a debug overlay node. If the project doesn't expose this, request the coder add a debug overlay (one-time tooling).
3. **External**: on a windowed run, use the OS screenshot tool (`screencapture` on macOS, `import` on Linux, `nircmd savescreenshot` on Windows) targeting the Godot window.

Save screenshots to `docs/playtest/screenshots/<feature>_<scene>_<state>.png` and reference from the playtest log.

### Performance capture

Enable Godot's built-in performance monitor via the editor (`Debugger → Monitors`) for windowed runs, or via the `Performance` singleton in script for headless runs:

```gdscript
print("FPS:", Performance.get_monitor(Performance.TIME_FPS))
print("Frame ms:", Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
print("Draw calls:", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
print("Mem:", Performance.get_monitor(Performance.MEMORY_STATIC))
```

For continuous capture, recommend the coder add a `PerfLogger` autoload that writes a CSV per session under `docs/playtest/traces/<yyyy-mm-dd>_<feature>.csv`. The playtest-harness reads this CSV to produce the Performance table in the log.

### Export builds

```sh
godot --headless --export-release "<preset name>" <output path>
```

Preset name must match an entry in `export_presets.cfg`. If absent, the project does not have export configured yet; route to coder to set this up before any release-quality playtest.

### Run unit tests (GUT)

If the project uses the [GUT](https://github.com/bitwes/Gut) test framework:

```sh
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test
```

If a different framework is configured (WAT, etc.), check the project's README. If no framework is installed, the project has no Godot-side unit tests — flag to coder.

## Health checks the playtester runs

Before a playtest session, the harness invokes this skill to verify:

1. `godot --version` works → engine installed
2. `godot --headless --import` completes without errors → assets clean
3. Launching the default scene reaches the title screen / game start without parse errors → smoke pass

Failure at any step = critical playtest finding, log and return to coder.

## Rules

- DO NOT modify Godot project files (`project.godot`, `.tscn`, `.gd`, presets) from this skill. The coder owns the project. This skill only invokes and captures.
- DO NOT recommend changing Godot version without the user's confirmation. Engine upgrades are project-level decisions.
- DO NOT bypass headless mode in CI / cloud environments. Windowed launches fail without a display server.
- DO NOT capture screenshots that depend on randomized state without seeding RNG first. Reproducibility matters for regression.
- DO NOT trust a "no errors" exit code alone. Godot can run while logging script errors to stderr — always scan stderr for `SCRIPT ERROR`, `Resource not found`, `Cyclic resource inclusion`.
- When the engine is missing or the wrong version, surface installation steps to the user rather than guessing.
