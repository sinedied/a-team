---
name: game-web-2d
description: "Complete guide and toolkit for developing 2D web games with Phaser 3 on a Vite + TypeScript stack. Covers the recommended stack, project structure, architecture (scenes, decoupled logic), rendering, physics, performance, testing, and deploy workflows, and ships an optional Playwright capture helper (screenshots, FPS, console errors). Use when the project is a browser-based 2D game (Phaser, or canvas/WebGL 2D)."
---

# 2D Web Game Development (Phaser)

An opinionated guide and toolkit for building 2D web games with **Phaser 3** on a **Vite + TypeScript** stack. This file is a lean hub: read the focused reference in `references/` for the area you're working on, and use the tools in `tools/`.

This skill is **optional and self-contained**. Other agents (planner, coder, playtester) may use it when the project is a 2D web game, but nothing in the squad depends on it — remove, replace, or extend it freely (swap Phaser for Excalibur/PixiJS/Kaplay; see `references/architecture.md`). It satisfies a spec's `## Run Target` and the playtester's launch/capture/perf needs without coupling the rest of the squad to Phaser.

## When to use

- The project's `package.json` depends on `phaser` (or another 2D canvas/WebGL framework)
- You are scaffolding, implementing, testing, or playtesting a browser-based 2D game
- The coder needs dev/build/test commands; the playtester needs launch + capture + perf

## The stack

Opinionated, current for 2025:

| Concern | Choice | Why |
|---------|--------|-----|
| Engine | **Phaser 3** | Largest 2D web ecosystem; scenes, physics, tilemaps, input, audio, animation built in |
| Build / dev server | **Vite** | Instant HMR, ESM, tiny config, first-class TS |
| Language | **TypeScript** | Types catch errors early; Phaser ships solid typings |
| Unit tests | **Vitest** | Vite-native; test decoupled game logic without a browser |
| E2E / canvas tests | **Playwright** (headless) | Drives the real canvas; screenshots + visual regression + console capture |
| Lint / format | **ESLint + Prettier** | Standard TS hygiene |
| Distribution | **itch.io** (butler) + **GitHub Pages** | One-command publish; relative asset paths |

Alternatives (swap-in): **Excalibur** (TS-native actor model), **PixiJS** (renderer only, BYO loop), **Kaplay** (ECS, jam-speed). See `references/architecture.md`.

## Reference map

Read the relevant file for the task at hand — don't load all of them at once.

| When you're… | Read |
|--------------|------|
| Scaffolding, organizing files, designing scenes/state/input, or swapping engines | `references/architecture.md` |
| Drawing things: sprites, atlases, tilemaps (Tiled), animation, cameras, particles | `references/rendering.md` |
| Adding collisions/movement: Arcade vs Matter physics | `references/physics.md` |
| Hitting frame-rate issues / setting a perf budget | `references/performance.md` |
| Setting up dev/build/test/deploy or CI | `references/workflows.md` |
| Adding a debug/FPS overlay, seeded RNG, test hooks, or a Playwright capture spec | `references/templates.md` |

## Tooling

Keep it minimal — `npm run dev` / `build` / `test` (Vite, Vitest) are native and need no wrapper, and project structure comes pre-wired by scaffolding and fails loudly on build if broken. The only thing npm doesn't give you is **driving the real browser**, so that's the only tool shipped.

| Tool | Runtime | Purpose |
|------|---------|---------|
| `tools/capture.mjs` | Node + Playwright | Screenshot + FPS sample + console/error capture against the running game (optional; `npm i -D playwright`) |

> For zero-install browser capture, the `chrome-devtools` skill (MCP) is an alternative to `capture.mjs`. The playtester uses whichever is available.
> Bundle size: `npm run build` (Vite prints per-chunk sizes). Deploy-path safety (relative `base`, no root-absolute asset paths): one grep, documented in `references/workflows.md` — no custom validator needed.

## Playtest integration

When the project is a Phaser game, this skill satisfies a spec's `## Run Target`:

- **Dev command**: `npm run dev` (Vite prints the local URL, e.g. `http://localhost:5173`)
- **Smoke check**: the page returns 200 with the expected root markup and the canvas mounts with no console errors within a few seconds; `npm run build` succeeds. (A plain HTTP GET / `curl` confirms the server is up — no custom launcher needed.)
- **Capture**: `tools/capture.mjs` (or the `chrome-devtools` skill) for screenshots, FPS, and console errors; expose a `window.__debug` object (see `references/templates.md`) for a stable metrics surface
- **Deploy safety**: before publishing, confirm relative `base` + no root-absolute asset paths (grep one-liner in `references/workflows.md`)

The `playtest-harness` discovers this skill (or not) at runtime; nothing breaks if it's absent — the harness falls back to invoking the Run Target commands directly.

## References (external)

- Phaser docs: <https://docs.phaser.io/> · Examples: <https://phaser.io/examples>
- Vite: <https://vitejs.dev/> · Vitest: <https://vitest.dev/> · Playwright: <https://playwright.dev/>
- Tiled (tilemap editor): <https://www.mapeditor.org/>
- TexturePacker (atlases): <https://www.codeandweb.com/texturepacker>
- itch.io HTML5: <https://itch.io/docs/creators/html5/> · butler: <https://itch.io/docs/butler/>
- Excalibur: <https://excaliburjs.com/> · PixiJS: <https://pixijs.com/> · Kaplay: <https://kaplayjs.com/>

## Rules

- **DO NOT** add pip dependencies for the Python tools. Stdlib only. Browser capture may use Playwright (Node), kept optional.
- **DO NOT** use absolute asset paths (`/assets/...`) — they break on itch.io and GitHub Pages subpaths. Use relative paths and set Vite `base` appropriately.
- **DO NOT** put game logic inside render/update callbacks that can't be tested — decouple pure logic into plain TS modules and unit-test them with Vitest (see `references/architecture.md`).
- **DO NOT** load assets ad hoc — use a dedicated preload scene with a progress bar (see `references/rendering.md`).
- **DO NOT** churn objects with `new`/`destroy()` in hot paths — pool bullets/enemies/particles (see `references/performance.md`).
- **DO NOT** rely on a single FPS reading — sample a window and report median / p95 (`capture.mjs` does this).
- **DO NOT** wrap native npm scripts (`dev`, `build`, `test`) in custom tooling — call them directly; only tool what npm doesn't provide.
- Seed RNG for any test or capture that depends on randomness — reproducibility matters for regression.
