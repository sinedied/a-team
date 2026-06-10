# Godot — Project Structure & Core Architecture

Read this when scaffolding a project, organizing files, or designing how nodes,
scenes, data, and state fit together.

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
├── tools/               # editor tools, build scripts
└── addons/              # plugins: gdUnit4, community assets
```

## Naming conventions

- **Files & folders**: `snake_case` — `player.gd`, `enemy_ai.gd`, `main_menu.tscn`
- **Classes** (`class_name`): `PascalCase` — `class_name PlayerCharacter`
- **Nodes in scenes**: `PascalCase` — `Player`, `HealthBar`, `AttackArea`
- **Functions / variables**: `snake_case` — `take_damage()`, `move_speed`
- **Constants**: `CONSTANT_CASE` — `const MAX_HEALTH := 100`
- **Signals**: past-tense `snake_case` — `health_changed`, `died`, `item_collected`
- **Private members**: leading underscore — `_internal_timer`
- Keep a scene and its primary script side-by-side with the same stem (`player.tscn` + `player.gd`).

## Scenes & composition over inheritance

A scene is a reusable tree of nodes. Prefer **composition** (child nodes / sub-scenes that each own one responsibility) over deep script inheritance. A `Player` scene composes a `Sprite2D`, `CollisionShape2D`, `AttackArea`, `HealthComponent`, etc. Small components are testable and reusable across entities.

## Typed GDScript

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

## Signals for decoupling

Use signals to let nodes communicate without hard references. Emit with the Godot 4 syntax `signal_name.emit(args)`; connect with `node.signal_name.connect(callable)`. A global event bus autoload is fine for cross-cutting events (e.g. `Events.enemy_killed.emit(enemy)`) but don't route everything through it — prefer local signals where the relationship is local.

## Autoloads (singletons) — sparingly

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

## Data-driven design with Resources

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

## State machines

For player/enemy/AI behavior, use a simple state machine (enum-based for small cases, node-based for larger). Keep `_physics_process` thin; delegate to the active state.

## Scene transitions

Route scene changes through a small autoload that handles loading screens and `get_tree().change_scene_to_file()` (or `change_scene_to_packed()` with preloaded `PackedScene`s). For large scenes, use `ResourceLoader.load_threaded_request()` to avoid hitches.

## Input

Define actions in **Project Settings → Input Map** (e.g. `move_left`, `jump`, `interact`); never hard-code raw keycodes. Read movement with `Input.get_vector("move_left", "move_right", "move_up", "move_down")`. Support remapping by saving/loading `InputMap` overrides. Provide both keyboard and controller bindings.
