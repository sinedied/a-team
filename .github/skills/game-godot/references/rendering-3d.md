# Godot — 3D Specifics

Read this when building a 3D game: rendering, physics, levels, camera/navigation, materials.

- **Rendering**: the **Forward+** renderer is the default for desktop; use **Mobile** or **Compatibility** for low-end/web targets. Set up a `WorldEnvironment` (tonemapping, ambient light, SSAO, glow) and lighting (`DirectionalLight3D` + GI via `VoxelGI`, `LightmapGI`, or `SDFGI`). Bake lightmaps for static scenes; reserve real-time GI for dynamic ones.
- **Physics**: `CharacterBody3D` + `move_and_slide()` for characters; `CollisionShape3D` with primitive shapes where possible (cheaper than trimesh). Use trimesh collision only for static geometry. Same layer/mask discipline as 2D.
- **Levels**: `GridMap` with a `MeshLibrary` for modular/blockout levels; import full scenes from `.glb` (Blender export) for authored geometry.
- **Camera & navigation**: `Camera3D` (+ `SpringArm3D` for third-person follow); `NavigationRegion3D` + `NavigationAgent3D` for pathfinding; bake navmesh for static levels.
- **Materials & shaders**: `StandardMaterial3D` for PBR; custom `.gdshader` (Godot Shading Language) or `ShaderMaterial` for effects. Reuse materials to cut state changes.
- **Performance helpers**: `VisibleOnScreenNotifier3D`, LOD via `MeshInstance3D` LOD bias / `visibility_range_*`, occlusion culling (`OccluderInstance3D`).

## Common movement example (with gravity)

```gdscript
class_name PlayerBody3D
extends CharacterBody3D

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity += get_gravity() * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY
    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
    velocity.x = direction.x * SPEED
    velocity.z = direction.z * SPEED
    move_and_slide()
```

## Lighting / GI guidance

- **Static scene** → bake `LightmapGI` for best quality/perf.
- **Dynamic scene, desktop** → `SDFGI` (no baking, large scenes) or `VoxelGI` (bounded, sharper).
- **Mobile / web** → avoid real-time GI; bake or use baked ambient + light probes.
