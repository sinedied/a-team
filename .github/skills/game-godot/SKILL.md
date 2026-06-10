---
name: game-godot
description: "Complete guide and toolkit for developing games with the Godot 4 engine (GDScript, 2D and 3D). Covers the recommended stack, project structure, core architecture patterns, performance, testing, dev/export workflows, and ships stdlib-only Python tooling for launch/smoke-check, headless testing, performance summarization, and project validation. Use when the project contains a project.godot file or you are building a Godot game."
---

# Godot Game Development

A complete, opinionated guide for building games in **Godot 4** with **GDScript**, covering both **2D and 3D**. It documents the recommended stack, architecture, workflows, and best practices, and ships a small **stdlib-only Python toolkit** (`tools/`) for launching, testing, profiling, and validating a Godot project.

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
| Testing | **GdUnit4** (primary) | Headless CLI, JUnit XML, mocks, parameterized tests, GDScript + C#. `GUT` is a lighter GDScript-only alternative |
| Format / lint | **gdtoolkit** (`gdformat`, `gdlint`) | Deterministic formatting + static checks. Install via `pipx install gdtoolkit` |
| Version control | git + `.gitignore` (`.godot/`) + **Git LFS** for binary assets | Keeps the repo lean; `.godot/` is a regenerable cache |
| CI | GitHub Actions: `chickensoft-games/setup-godot` + headless test + export | Reproducible builds/tests on every push |
| Distribution | `export_presets.cfg` + **butler** (itch.io) | Scriptable export + one-command publish |

Install the editor from <https://godotengine.org/download> (or use a version manager). Verify: `godot --version`.

### .gitignore essentials

```gitignore
# Godot 4 regenerable cache
.godot/
# Exported builds
/build/
/export/
# OS / editor noise
.DS_Store
*.tmp
```

Use Git LFS for binary assets (`.png`, `.webp`, `.ogg`, `.wav`, `.glb`, `.blend`):

```gitattributes
*.png filter=lfs diff=lfs merge=lfs -text
*.webp filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text
*.glb filter=lfs diff=lfs merge=lfs -text
```

## Project structure

A clear, scalable layout. Keep `test/` at the project root so it can be excluded from exports.

```
res://
├── project.godot
├── export_presets.cfg
├── assets/              # textures, audio, fonts, models (by type then feature)
│   ├── sprites/
│   ├── audio/
│   ├── fonts/
│   └── models/
├── scenes/              # one folder per feature/system; scenes + their scripts together
│   ├── player/
│   │   ├── player.tscn
│   │   └── player.gd
│   ├── enemies/
│   └── ui/
├── globals/             # autoload singletons (game_state.gd, audio.gd, events.gd)
├── resources/           # custom Resource scripts + .tres data (data-driven design)
├── shaders/             # .gdshader files
├── test/                # GdUnit4 tests, mirroring scenes/ + resources/
├── tools/               # editor tools, build scripts (this skill's Python tools can live here)
└── addons/              # plugins: gdUnit4, community assets
```

### Naming conventions

- **Files & folders**: `snake_case` — `player.gd`, `enemy_ai.gd`, `main_menu.tscn`
- **Classes** (`class_name`): `PascalCase` — `class_name PlayerCharacter`
- **Nodes in scenes**: `PascalCase` — `Player`, `HealthBar`, `AttackArea`
- **Functions / variables**: `snake_case` — `take_damage()`, `move_speed`
- **Constants**: `CONSTANT_CASE` — `const MAX_HEALTH := 100`
- **Signals**: past-tense `snake_case` — `health_changed`, `died`, `item_collected`
- **Private members**: leading underscore — `_internal_timer`
- Keep a scene and its primary script side-by-side with the same stem (`player.tscn` + `player.gd`).

## Core architecture

### Scenes & composition over inheritance

A scene is a reusable tree of nodes. Prefer **composition** (child nodes / sub-scenes that each own one responsibility) over deep script inheritance. A `Player` scene composes a `Sprite2D`, `CollisionShape2D`, `AttackArea`, `HealthComponent`, etc. Small components are testable and reusable across entities.

### Typed GDScript

Always type variables, parameters, and return values. Typing catches errors at parse time and speeds up the VM.

```gdscript
class_name Player
extends CharacterBody2D

const SPEED: float = 220.0
const JUMP_VELOCITY: float = -400.0

@export var max_health: int = 100
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var health: int = max_health

signal health_changed(current: int, maximum: int)
signal died

func take_damage(amount: int) -> void:
    health = maxi(health - amount, 0)
    health_changed.emit(health, max_health)
    if health == 0:
        died.emit()
```

### Signals for decoupling

Use signals to let nodes communicate without hard references. Emit with the Godot 4 syntax `signal_name.emit(args)`; connect with `node.signal_name.connect(callable)`. A global event bus autoload is fine for cross-cutting events (e.g. `Events.enemy_killed.emit(enemy)`) but don't route everything through it — prefer local signals where the relationship is local.

### Autoloads (singletons) — sparingly

Register true globals in **Project → Project Settings → Autoload**: game state, an audio manager, a global event bus, a scene router. Avoid turning autoloads into a dumping ground; each should own one concern.

```gdscript
# globals/game_state.gd  (autoload as "GameState")
extends Node

var score: int = 0
var current_level: int = 1

func reset() -> void:
    score = 0
    current_level = 1
```

### Data-driven design with Resources

Model data (enemy stats, weapon configs, dialogue) as custom `Resource` types saved to `.tres`. This separates content from code, makes balance tunable by editing data, and lets the game-designer's `docs/GAME.md` numbers map to concrete `.tres` files.

```gdscript
# resources/enemy_stats.gd
class_name EnemyStats
extends Resource

@export var display_name: String = ""
@export var max_health: int = 10
@export var move_speed: float = 80.0
@export var damage: int = 1
@export var loot_table: Array[Resource] = []
```

### State machines

For player/enemy/AI behavior, use a simple state machine (enum-based for small cases, node-based for larger). Keep `_physics_process` thin; delegate to the active state.

### Scene transitions

Route scene changes through a small autoload that handles loading screens and `get_tree().change_scene_to_file()` (or `change_scene_to_packed()` with preloaded `PackedScene`s). For large scenes, use `ResourceLoader.load_threaded_request()` to avoid hitches.

### Input

Define actions in **Project Settings → Input Map** (e.g. `move_left`, `jump`, `interact`); never hard-code raw keycodes. Read movement with `Input.get_vector("move_left", "move_right", "move_up", "move_down")`. Support remapping by saving/loading `InputMap` overrides. Provide both keyboard and controller bindings.

## 2D specifics

- **Rendering**: 2D nodes derive from `CanvasItem`. For pixel art, set the texture filter to *Nearest* (project default or per-texture) and choose a viewport stretch mode (`canvas_items` or `viewport`) with an integer scale for crisp pixels. Configure the base resolution in Display settings.
- **Physics**: use `CharacterBody2D` + `move_and_slide()` for player/enemy movement (set `velocity`, no args in Godot 4). Use `Area2D` for triggers/hitboxes and `StaticBody2D`/`RigidBody2D` for world/dynamic bodies. Organize **collision layers and masks** deliberately and document them (e.g. layer 1 = world, 2 = player, 3 = enemy, 4 = player_hitbox).
- **Tilemaps**: use the `TileMapLayer` node (Godot 4.3+ replaces the monolithic `TileMap`) with `TileSet` resources; use physics and navigation layers in the TileSet for collision/pathing.
- **Camera**: `Camera2D` with smoothing and limits; for screen shake, offset the camera via a `Tween` or noise.
- **Animation**: `AnimatedSprite2D` (`SpriteFrames`) for frame animation; `AnimationPlayer` for keyframed property animation; `AnimationTree` for blending/state-driven animation. Use **Y-sort** (`YSortEnabled`) for top-down depth ordering.

## 3D specifics

- **Rendering**: the **Forward+** renderer is the default for desktop; use **Mobile** or **Compatibility** for low-end/web targets. Set up a `WorldEnvironment` (tonemapping, ambient light, SSAO, glow) and lighting (`DirectionalLight3D` + GI via `VoxelGI`, `LightmapGI`, or `SDFGI`). Bake lightmaps for static scenes; reserve real-time GI for dynamic ones.
- **Physics**: `CharacterBody3D` + `move_and_slide()` for characters; `CollisionShape3D` with primitive shapes where possible (cheaper than trimesh). Use trimesh collision only for static geometry. Same layer/mask discipline as 2D.
- **Levels**: `GridMap` with a `MeshLibrary` for modular/blockout levels; import full scenes from `.glb` (Blender export) for authored geometry.
- **Camera & navigation**: `Camera3D` (+ `SpringArm3D` for third-person follow); `NavigationRegion3D` + `NavigationAgent3D` for pathfinding; bake navmesh for static levels.
- **Materials & shaders**: `StandardMaterial3D` for PBR; custom `.gdshader` (Godot Shading Language) or `ShaderMaterial` for effects. Reuse materials to cut state changes.
- **Performance helpers**: `VisibleOnScreenNotifier3D`, LOD via `MeshInstance3D` LOD bias / `visibility_range_*`, occlusion culling (`OccluderInstance3D`).

## Performance & profiling

1. **Profile first, optimize second.** Use the editor **Debugger → Profiler** (script/function timings) and **Monitors** (FPS, draw calls, physics, memory, objects).
2. **Read live metrics** via the `Performance` singleton (the `PerfLogger` template below writes these to CSV for offline analysis):

   ```gdscript
   Performance.get_monitor(Performance.TIME_FPS)
   Performance.get_monitor(Performance.TIME_PROCESS)          # main thread, seconds
   Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
   Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
   Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
   Performance.get_monitor(Performance.MEMORY_STATIC)
   ```

3. **`_process` / `_physics_process` discipline**: keep per-frame code minimal. Cache lookups (don't `get_node` every frame), avoid allocations in hot loops, prefer signals/timers over polling.
4. **Object pooling**: reuse bullets/particles/enemies instead of `instantiate()`/`queue_free()` churn.
5. **2D**: watch draw calls and overdraw; batch via texture atlases; cap `Light2D` count. **3D**: watch draw calls, vertex count, real-time light/shadow count; bake GI; use LOD and occlusion; prefer primitive collision shapes.
6. **Set a budget** in the spec's `## Constraints` (e.g. 60 FPS, ≤ 8 ms frame on target hardware) and verify with `tools/perf_summarize.py`.

## Dev workflow

```
setup    → install Godot 4.x; first import:  python tools/godot_run.py --import
run      → python tools/godot_run.py --scene scenes/main.tscn          # windowed
smoke    → python tools/godot_run.py --headless --quit-after 120 --json # CI smoke
test     → python tools/godot_test.py --runner gdunit4 --test-dir res://test
format   → gdformat .   &&   gdlint .
profile  → run with PerfLogger autoload enabled → python tools/perf_summarize.py user://perf.csv
validate → python tools/project_check.py
export   → godot --headless --export-release "Linux/X11" build/game.x86_64
publish  → butler push build/ user/game:linux
```

## Testing workflow (GdUnit4)

1. Install GdUnit4 from the Asset Library (or copy into `addons/gdUnit4/`) and enable the plugin.
2. Put tests under `test/`, mirroring `scenes/` and `resources/`. Name files `*_test.gd`.
3. Write tests extending `GdUnitTestSuite`:

   ```gdscript
   # test/player_test.gd
   extends GdUnitTestSuite

   func test_take_damage_reduces_health() -> void:
       var player := preload("res://scenes/player/player.tscn").instantiate()
       add_child(player)
       player.take_damage(30)
       assert_int(player.health).is_equal(70)

   func test_damage_cannot_go_below_zero() -> void:
       var player := preload("res://scenes/player/player.tscn").instantiate()
       add_child(player)
       player.take_damage(9999)
       assert_int(player.health).is_equal(0)
   ```

4. Run headless locally and in CI with `tools/godot_test.py` (auto-detects GdUnit4's `runtest` wrapper or the `GdUnitCmdTool.gd` entry point). Emit JUnit XML for CI dashboards.

### CI (GitHub Actions)

```yaml
name: Godot CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { lfs: true }
      - uses: chickensoft-games/setup-godot@v2
        with: { version: 4.4.0 }
      - run: godot --headless --import          # build the resource cache
      - run: python tools/godot_test.py --runner gdunit4 --test-dir res://test --report-dir reports
      - run: godot --headless --export-release "Linux/X11" build/game.x86_64
```

## Custom tooling

All tools are **Python 3 stdlib-only** (no pip installs). Run any with `-h` for full options. They print human-readable output by default and structured JSON with `--json` (so the playtester/CI can parse them).

| Tool | Purpose |
|------|---------|
| `tools/godot_run.py` | Launch (headless / windowed / specific scene), run a smoke check, scan stderr for `SCRIPT ERROR` / missing resources / parse errors (exit code alone is unreliable in Godot), enforce a timeout, emit a JSON result |
| `tools/godot_test.py` | Run GdUnit4 (or GUT) headless, surface pass/fail and the report path; auto-detects the runner entry point |
| `tools/perf_summarize.py` | Parse a perf CSV (from the `PerfLogger` template) → min / median / p95 FPS + frame-time, with frame-pacing flags |
| `tools/project_check.py` | Validate project structure, naming conventions, autoload references, `.gitignore`, and export presets |

> **Locating the Godot binary**: every tool accepts `--godot <path>` (default `godot`). Set the `GODOT_BIN` env var to override the default globally.

### GDScript templates

Drop these into the game (they are GDScript, not Python). They power deterministic capture and the perf pipeline.

**PerfLogger autoload** — register as `PerfLogger`; writes a CSV consumed by `perf_summarize.py`:

```gdscript
# globals/perf_logger.gd  (autoload as "PerfLogger")
extends Node

@export var enabled: bool = false
@export var sample_every_frames: int = 10
@export var output_path: String = "user://perf.csv"

var _file: FileAccess
var _frame: int = 0

func _ready() -> void:
    if not enabled:
        set_process(false)
        return
    _file = FileAccess.open(output_path, FileAccess.WRITE)
    _file.store_line("frame,fps,frame_ms,draw_calls,nodes,mem_static_mb")

func _process(_delta: float) -> void:
    _frame += 1
    if _frame % sample_every_frames != 0:
        return
    var fps := Performance.get_monitor(Performance.TIME_FPS)
    var frame_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
    var draws := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
    var mem := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
    _file.store_line("%d,%f,%f,%d,%d,%f" % [_frame, fps, frame_ms, draws, nodes, mem])

func _exit_tree() -> void:
    if _file:
        _file.flush()
        _file.close()
```

**Screenshot helper** — deterministic viewport capture (call from a debug key or headless script):

```gdscript
# tools/screenshot.gd  (run: godot --headless -s tools/screenshot.gd -- res://scenes/main.tscn out.png)
extends SceneTree

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    var scene_path := args[0] if args.size() > 0 else "res://scenes/main.tscn"
    var out_path := args[1] if args.size() > 1 else "screenshot.png"
    var packed: PackedScene = load(scene_path)
    var instance := packed.instantiate()
    root.add_child(instance)
    await process_frame
    await process_frame  # let one full frame render
    var image := root.get_texture().get_image()
    image.save_png(out_path)
    quit()
```

**Debug overlay / cheat toggles** — exposes Playtest Hooks (godmode, level skip, spawn) behind a dev-only flag:

```gdscript
# globals/debug.gd  (autoload as "Debug")
extends CanvasLayer

var godmode: bool = false

func _ready() -> void:
    visible = OS.is_debug_build()

func _unhandled_input(event: InputEvent) -> void:
    if not OS.is_debug_build():
        return
    if event.is_action_pressed("debug_godmode"):
        godmode = not godmode
    elif event.is_action_pressed("debug_skip_level"):
        Events.request_skip_level.emit()
```

## Playtest integration

When the project is a Godot game, this skill satisfies a spec's `## Run Target`:

- **Dev command**: `python tools/godot_run.py --scene <main scene>` (windowed) or `--headless` for CI
- **Smoke check**: `godot_run.py` exits non-zero and reports the offending lines if any `SCRIPT ERROR` / missing-resource / parse error appears, or if the process crashes before the timeout
- **Capture**: `tools/screenshot.gd` for deterministic screenshots; the `PerfLogger` autoload + `perf_summarize.py` for performance tables in the playtest log

The playtester's `playtest-harness` discovers this skill (or not) at runtime; nothing breaks if it's absent — the harness falls back to invoking the Run Target commands directly.

## References

- Godot docs — Best practices: <https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html>
- Godot docs — Project organization: <https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html>
- Godot docs — Command line tutorial: <https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html>
- Godot docs — Debug & profiling: <https://docs.godotengine.org/en/stable/tutorials/debug/index.html>
- Godot docs — GDScript style guide: <https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html>
- GdUnit4: <https://github.com/MikeSchulze/gdUnit4>
- GUT: <https://github.com/bitwes/Gut>
- gdtoolkit (gdformat/gdlint): <https://github.com/Scony/godot-gdscript-toolkit>
- setup-godot CI action: <https://github.com/chickensoft-games/setup-godot>
- godot-ci (export templates): <https://github.com/abarichello/godot-ci>
- butler (itch.io): <https://itch.io/docs/butler/>

## Rules

- **DO NOT** require any pip dependencies for the Python tools. Stdlib only. If a tool genuinely needs more, document it and keep the dependency optional.
- **DO NOT** trust Godot's exit code alone — it can return 0 while logging `SCRIPT ERROR` to stderr. Always scan output (`godot_run.py` does this).
- **DO NOT** run windowed launches in CI / headless environments — use `--headless`.
- **DO NOT** commit the `.godot/` cache or exported builds. Use the provided `.gitignore`.
- **DO NOT** hard-code input keycodes — define actions in the Input Map and read them by name.
- **DO NOT** invent magic numbers in code — model tunable values as exported vars or `Resource` data mapped from `docs/GAME.md`.
- **DO NOT** over-use autoloads or a global event bus; prefer local signals where the relationship is local.
- Pin the Godot version in CI and document the required version in the project README; engine upgrades are project-level decisions.
- Prefer composition (small reusable sub-scenes/components) over deep inheritance.
- Seed RNG for any test or screenshot that depends on randomness — reproducibility matters for regression.
