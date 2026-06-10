---
name: game-web-3d
description: "Complete guide and toolkit for developing 3D web games with Babylon.js on a Vite + TypeScript stack. Covers the recommended stack, scene/engine setup, asset (glTF) pipeline, Havok physics, rendering, performance (WebGPU, instancing, culling), testing, and deploy workflows, and ships an optional Playwright capture helper (screenshots, FPS, draw calls, WebGL context-loss). Use when the project is a browser-based 3D game (Babylon.js, Three.js, or WebGL/WebGPU 3D)."
---

# 3D Web Game Development (Babylon.js)

An opinionated guide and toolkit for building 3D web games with **Babylon.js** on a **Vite + TypeScript** stack. This file is a lean hub: read the focused reference in `references/` for the area you're working on, and use the tool in `tools/`.

This skill is **optional and self-contained**. Other agents (planner, coder, playtester) may use it when the project is a 3D web game, but nothing in the squad depends on it — remove, replace, or extend it freely (swap Babylon for Three.js + Rapier or PlayCanvas; see `references/architecture.md`). It satisfies a spec's `## Run Target` and the playtester's launch/capture/perf needs without coupling the rest of the squad to Babylon.

## When to use

- The project's `package.json` depends on `@babylonjs/core` (or another WebGL/WebGPU 3D framework)
- You are scaffolding, implementing, testing, or playtesting a browser-based 3D game
- The coder needs dev/build/test commands; the playtester needs launch + capture + perf

## The stack

Opinionated, current for 2025:

| Concern | Choice | Why |
|---------|--------|-----|
| Engine | **Babylon.js** | Full game engine: scene graph, PBR, animation, GUI, audio, WebGPU — TS-first, batteries included |
| Physics | **Havok** (built-in plugin, Physics v2) | Fastest production physics; native Babylon integration. `@babylonjs/havok` |
| Build / dev server | **Vite** | Instant HMR, ESM, tiny config, first-class TS; handles WASM (Havok) |
| Language | **TypeScript** | Babylon is authored in TS; excellent typings |
| Unit tests | **Vitest** | Vite-native; test decoupled game logic without a browser/GPU |
| E2E / WebGL tests | **Playwright** (headed/GPU) | Drives the real canvas; screenshots + console + context-loss capture (note GPU caveats) |
| Lint / format | **ESLint + Prettier** | Standard TS hygiene |
| Distribution | **itch.io** (butler) + **GitHub Pages** | One-command publish; relative asset paths |

Alternatives (swap-in): **Three.js** (+ Rapier physics, optionally React Three Fiber), **PlayCanvas** (engine + editor). See `references/architecture.md`.

## Reference map

Read the relevant file for the task at hand — don't load all of them at once.

| When you're… | Read |
|--------------|------|
| Scaffolding, scene/engine setup, cameras/lights, glTF loading, state/input, GUI/audio, or swapping engines | `references/architecture.md` |
| Working on visuals: meshes, PBR/Node materials, lighting, environment/IBL, post-processing, particles | `references/rendering.md` |
| Adding collisions/movement/vehicles: Havok physics | `references/physics.md` |
| Hitting frame-rate issues / setting a perf budget (instancing, culling, WebGPU) | `references/performance.md` |
| Setting up dev/build/test/deploy or CI | `references/workflows.md` |
| Adding a debug/metrics surface, test hooks, seeded RNG, or a Playwright capture spec | `references/templates.md` |

## Tooling

Keep it minimal — `npm run dev` / `build` / `test` (Vite, Vitest) are native and need no wrapper. The only thing npm doesn't give you is **driving the real WebGL canvas**, so that's the only tool shipped.

| Tool | Runtime | Purpose |
|------|---------|---------|
| `tools/capture.mjs` | Node + Playwright | Screenshot + FPS sample + draw-call/active-mesh read + console-error and **WebGL context-loss** capture against the running game (optional; `npm i -D playwright`) |

> For zero-install browser capture, the `chrome-devtools` skill (MCP) is an alternative to `capture.mjs`. The playtester uses whichever is available.
> **GPU caveat**: headless browsers often fall back to software WebGL — FPS/timings are then **not** representative of real hardware. Run with a GPU (`--headed`, or CI with a GPU/`--use-gl`) for meaningful perf numbers; note the mode in the playtest log.

## Playtest integration

When the project is a Babylon game, this skill satisfies a spec's `## Run Target`:

- **Dev command**: `npm run dev` (Vite prints the local URL, e.g. `http://localhost:5173`)
- **Smoke check**: the page returns 200, the canvas mounts, the first frame renders (non-zero active meshes), and there are no console errors or WebGL context-loss within a few seconds; `npm run build` succeeds
- **Capture**: `tools/capture.mjs` (or the `chrome-devtools` skill) for screenshots, FPS, draw calls, and context-loss; expose a `window.__debug` object (see `references/templates.md`) for a stable metrics surface
- **Deploy safety**: relative `base` + no root-absolute asset paths (grep one-liner in `references/workflows.md`)

The `playtest-harness` discovers this skill (or not) at runtime; nothing breaks if it's absent — the harness falls back to invoking the Run Target commands directly.

## References (external)

- Babylon.js docs: <https://doc.babylonjs.com/> · Playground: <https://playground.babylonjs.com/>
- Havok physics: <https://doc.babylonjs.com/features/featuresDeepDive/physics/usingPhysicsEngine>
- glTF / asset pipeline: <https://doc.babylonjs.com/features/featuresDeepDive/Exporters>
- Vite: <https://vitejs.dev/> · Vitest: <https://vitest.dev/> · Playwright: <https://playwright.dev/>
- itch.io HTML5: <https://itch.io/docs/creators/html5/> · butler: <https://itch.io/docs/butler/>
- Three.js: <https://threejs.org/> · Rapier: <https://rapier.rs/> · React Three Fiber: <https://r3f.docs.pmnd.rs/> · PlayCanvas: <https://playcanvas.com/>

## Rules

- **DO NOT** add pip dependencies — the only tool is `capture.mjs` (Node + optional Playwright).
- **DO NOT** trust headless FPS as representative — headless often means software WebGL. Capture with a GPU for real numbers and label the mode.
- **DO NOT** use absolute asset paths (`/assets/...`) — they break on itch.io / GitHub Pages subpaths. Use relative paths and set Vite `base`.
- **DO NOT** put game logic where it can't be tested — decouple pure logic into plain TS modules and unit-test with Vitest (see `references/architecture.md`).
- **DO NOT** import the whole `babylonjs` UMD bundle — import from `@babylonjs/core` (and sub-packages) so Vite tree-shakes (see `references/architecture.md`).
- **DO NOT** ignore WebGL context-loss — handle `webglcontextlost`/`webglcontextrestored` and surface it; `capture.mjs` flags it.
- **DO NOT** create per-frame garbage — reuse `Vector3`/`Matrix` temporaries, freeze static world matrices/materials, and instance repeated meshes (see `references/performance.md`).
- **DO NOT** rely on a single FPS reading — sample a window and report median / p95 (`capture.mjs` does this).
- **DO NOT** wrap native npm scripts in custom tooling — only tool what npm doesn't provide.
- Seed RNG for any test or capture that depends on randomness — reproducibility matters for regression.
