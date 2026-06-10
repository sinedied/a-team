# Babylon.js — Physics (Havok)

Read this when adding collisions, gravity, character movement, or vehicles.
Babylon's recommended engine is **Havok** via the **Physics v2** API.

## Enable Havok

Havok ships as WASM (`@babylonjs/havok`). Initialize it async before using physics:

```ts
import HavokPhysics from "@babylonjs/havok";
import { HavokPlugin, Vector3 } from "@babylonjs/core";

const havok = await HavokPhysics();
scene.enablePhysics(new Vector3(0, -9.81, 0), new HavokPlugin(true, havok));
```

> Vite serves the `.wasm` automatically. If you see a 404 for the Havok WASM, ensure it isn't excluded from the build and that `base` is correct for your deploy path.

## Bodies with PhysicsAggregate

`PhysicsAggregate` is the quick way to give a mesh a body + shape:

```ts
import { PhysicsAggregate, PhysicsShapeType } from "@babylonjs/core";

// dynamic box (mass > 0)
new PhysicsAggregate(box, PhysicsShapeType.BOX, { mass: 1, restitution: 0.3, friction: 0.5 }, scene);
// static ground (mass 0)
new PhysicsAggregate(ground, PhysicsShapeType.BOX, { mass: 0 }, scene);
// sphere, capsule (characters), mesh (static concave), convexHull (dynamic)
```

Shape types: `BOX`, `SPHERE`, `CAPSULE`, `CYLINDER`, `CONVEX_HULL` (dynamic), `MESH` (static concave only — never for fast dynamic bodies).

## Lower-level: PhysicsBody / PhysicsShape

For shared shapes or fine control, create `PhysicsShape*` and `PhysicsBody` directly and reuse one shape across many bodies (cheaper than per-mesh aggregates).

## Collisions & triggers

```ts
import { HavokPlugin } from "@babylonjs/core";
const hk = scene.getPhysicsEngine()!.getPhysicsPlugin() as HavokPlugin;
hk.onCollisionObservable.add((ev) => {
  // ev.collider / ev.collidedAgainst, ev.type (COLLISION_STARTED, ...)
});
// Mark a shape as a trigger to get overlap events without a physical response.
```

## Character movement

For player controllers, prefer a **capsule** body with locked rotation, or Babylon's character-controller helper where available. Drive movement by setting linear velocity / applying impulses each physics step; raycast down for grounded checks (`scene.getPhysicsEngine().raycast(...)`). Keep gameplay-deciding logic (intended velocity) in a pure system (`src/systems/`) so it's unit-testable; the physics body just consumes it.

## Choosing shapes & determinism

- Primitives (box/sphere/capsule) are far cheaper than convex hulls; hulls are far cheaper than concave meshes.
- Use concave `MESH` only for **static** world geometry.
- Fix the physics timestep for reproducible behavior; seed any gameplay RNG.

## Alternatives

If you swap off Babylon: **Three.js** has no built-in physics — pair it with **Rapier** (Rust/WASM; fastest, deterministic) or **cannon-es** (pure JS; simpler, for prototypes). The pure-systems decoupling keeps the swap localized.
