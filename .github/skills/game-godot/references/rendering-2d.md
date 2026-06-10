# Godot — 2D Specifics

Read this when building a 2D game: rendering, physics, tilemaps, camera, animation.

- **Rendering**: 2D nodes derive from `CanvasItem`. For pixel art, set the texture filter to *Nearest* (project default or per-texture) and choose a viewport stretch mode (`canvas_items` or `viewport`) with an integer scale for crisp pixels. Configure the base resolution in Display settings.
- **Physics**: use `CharacterBody2D` + `move_and_slide()` for player/enemy movement (set `velocity`, no args in Godot 4). Use `Area2D` for triggers/hitboxes and `StaticBody2D`/`RigidBody2D` for world/dynamic bodies. Organize **collision layers and masks** deliberately and document them (e.g. layer 1 = world, 2 = player, 3 = enemy, 4 = player_hitbox).
- **Tilemaps**: use the `TileMapLayer` node (Godot 4.3+ replaces the monolithic `TileMap`) with `TileSet` resources; use physics and navigation layers in the TileSet for collision/pathing.
- **Camera**: `Camera2D` with smoothing and limits; for screen shake, offset the camera via a `Tween` or noise.
- **Animation**: `AnimatedSprite2D` (`SpriteFrames`) for frame animation; `AnimationPlayer` for keyframed property animation; `AnimationTree` for blending/state-driven animation. Use **Y-sort** (`YSortEnabled`) for top-down depth ordering.

## Common movement example

```gdscript
class_name PlayerBody
extends CharacterBody2D

const SPEED: float = 220.0

func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * SPEED
    move_and_slide()
```

## Collision layers/masks checklist

- Assign each gameplay category its own layer; name layers in Project Settings → Layer Names → 2D Physics.
- A body's **layer** is what it *is*; its **mask** is what it *scans for*.
- Document the mapping in `docs/memory/conventions.md` so every contributor uses the same numbers.
