# Babylon.js — Project Structure & Architecture

Read this when scaffolding, setting up the engine/scene, loading assets, or
designing how systems fit together.

## Stack scaffold

```
my-game/
├── index.html              # <canvas id="app"> + module script; relative asset base
├── package.json            # scripts: dev / build / preview / test / lint
├── tsconfig.json
├── vite.config.ts          # base: './' for deploy; ensure WASM (Havok) is served
├── public/
│   └── assets/
│       ├── models/         # .glb / .gltf
│       ├── textures/
│       ├── env/            # .env / .hdr image-based lighting
│       └── audio/
├── src/
│   ├── main.ts             # Engine + Scene boot, render loop
│   ├── scenes/             # scene builders (world.ts, menu.ts)
│   ├── entities/           # player.ts, enemy.ts (Babylon glue)
│   ├── systems/            # PURE logic, no Babylon imports (Vitest-testable)
│   ├── data/               # config/balance constants & types (from docs/GAME.md)
│   └── debug/              # window.__debug / window.__test hooks, inspector toggle
└── test/                   # Vitest unit tests + Playwright e2e
```

## Packages & tree-shaking

Use the ES6 packages and import from `@babylonjs/core` (never the `babylonjs` UMD bundle) so Vite tree-shakes:

```
@babylonjs/core      # engine, scene, meshes, materials, cameras, physics glue
@babylonjs/loaders   # glTF/GLB import (side-effect import)
@babylonjs/gui       # HUD/menus
@babylonjs/materials # extra materials (optional)
@babylonjs/havok     # Havok physics WASM
@babylonjs/inspector # debug layer (dev only)
```

## Engine & scene boot

```ts
// src/main.ts
import { Engine, Scene, ArcRotateCamera, HemisphericLight, Vector3, MeshBuilder } from "@babylonjs/core";

const canvas = document.getElementById("app") as HTMLCanvasElement;
const engine = new Engine(canvas, true, { preserveDrawingBuffer: true, stencil: true });
// preserveDrawingBuffer:true lets screenshot tools read the canvas reliably (small cost; dev/test).

const scene = new Scene(engine);
const camera = new ArcRotateCamera("cam", -Math.PI / 2, Math.PI / 2.5, 10, Vector3.Zero(), scene);
camera.attachControl(canvas, true);
new HemisphericLight("light", new Vector3(0, 1, 0), scene);
MeshBuilder.CreateBox("box", { size: 1 }, scene);

engine.runRenderLoop(() => scene.render());
window.addEventListener("resize", () => engine.resize());
```

**WebGPU** (optional, faster where supported): use `WebGPUEngine` with async init and a WebGL fallback:

```ts
import { WebGPUEngine, Engine } from "@babylonjs/core";
const engine = (await WebGPUEngine.IsSupportedAsync)
  ? await (async () => { const e = new WebGPUEngine(canvas); await e.initAsync(); return e; })()
  : new Engine(canvas, true);
```

## Cameras & lights

- **Cameras**: `ArcRotateCamera` (orbit), `UniversalCamera`/`FreeCamera` (FPS/free), `FollowCamera` (third-person). Attach control to the canvas.
- **Lights**: `HemisphericLight` (ambient fill), `DirectionalLight` (+ `ShadowGenerator` for sun shadows), `PointLight`, `SpotLight`. Keep real-time shadow casters few.

## Asset pipeline (glTF)

Author/export models as **`.glb`** (Blender glTF export). Load with the async helpers (side-effect import the loaders once):

```ts
import "@babylonjs/loaders/glTF";
import { ImportMeshAsync } from "@babylonjs/core";

const result = await ImportMeshAsync("assets/models/hero.glb", scene);
const root = result.meshes[0];
result.animationGroups.forEach((g) => g.stop());
result.animationGroups.find((g) => g.name === "Idle")?.start(true);
```

Use `LoadAssetContainerAsync` to load once and instantiate many; prefer **relative** paths (no leading `/`) so deploys under a subpath work.

## Decouple logic from rendering (testability)

Keep pure game logic (damage, economy, progression, AI decisions, RNG rules) in `src/systems/` with **no Babylon imports**. Entities/scenes call into them. This makes the core unit-testable in milliseconds and keeps `docs/GAME.md` numbers in one place.

```ts
// src/systems/combat.ts  (pure, testable)
export function applyDamage(health: number, amount: number): number {
  return Math.max(0, health - amount);
}
```

## State, input, GUI, audio

- **State**: scene-local on entities; cross-scene in a small typed store module (`src/data/`).
- **Input**: `scene.onKeyboardObservable` / `scene.onPointerObservable`, or `DeviceSourceManager` for gamepad/keyboard/mouse unification. Map **actions** (not raw keys) in an input module; expose a `window.__test` hook for deterministic Playwright input.
- **GUI / HUD**: Babylon GUI (`AdvancedDynamicTexture.CreateFullscreenUI`) for menus/HUD, kept in its own module separate from world logic.
- **Audio**: Babylon's audio engine plays positional/2D sound; map audio cues to gameplay events per the spec's Audio Design section. (Babylon 8 introduced a new async audio engine — check the docs for the version you pin.)

## Swapping the engine

This guide anchors on Babylon, but the squad isn't coupled to it. If you swap:

- **Three.js** — a renderer; add **Rapier** (physics), your own loop, and systems. Largest ecosystem. **React Three Fiber** gives a declarative React API over Three.
- **PlayCanvas** — full engine with a cloud editor; entity/component model.

In all cases keep pure logic in `src/systems/`, assets in `public/`, and the Vite + TS + Vitest + Playwright tooling unchanged.
