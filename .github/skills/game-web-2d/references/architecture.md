# Phaser — Project Structure & Architecture

Read this when scaffolding a project, organizing files, designing scenes/state/input,
or swapping the engine.

## Stack scaffold

```
my-game/
├── index.html              # mounts the game; relative asset base
├── package.json            # scripts: dev / build / preview / test / lint
├── tsconfig.json
├── vite.config.ts          # set `base: './'` for itch/Pages subpath deploys
├── public/                 # static assets served as-is (copied verbatim)
│   └── assets/
│       ├── sprites/
│       ├── audio/
│       └── tilemaps/
├── src/
│   ├── main.ts             # Phaser.Game config + boot
│   ├── scenes/             # one file per scene
│   │   ├── boot.ts
│   │   ├── preload.ts
│   │   ├── game.ts
│   │   └── ui.ts
│   ├── entities/           # sprites/game objects (player.ts, enemy.ts)
│   ├── systems/            # PURE logic, no Phaser imports (testable with Vitest)
│   ├── data/               # config/balance constants & types (from docs/GAME.md)
│   └── debug/              # debug overlay, window.__debug / window.__test hooks
└── test/                   # Vitest unit tests (mirror src/systems/) + Playwright e2e
```

## Naming conventions

- Files: `kebab-case.ts` or `snake_case.ts` — pick one and be consistent (`player.ts`, `main-menu.ts`)
- Classes / Scene keys: `PascalCase` (`class GameScene`, scene key `"Game"`)
- Functions / variables: `camelCase`
- Constants: `CONSTANT_CASE`

## Game config & boot

```ts
// src/main.ts
import Phaser from "phaser";
import { BootScene } from "./scenes/boot";
import { PreloadScene } from "./scenes/preload";
import { GameScene } from "./scenes/game";

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,            // WebGL with Canvas fallback
  width: 640,
  height: 360,
  pixelArt: true,              // nearest-neighbour for crisp pixels
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  physics: { default: "arcade", arcade: { gravity: { x: 0, y: 0 }, debug: false } },
  scene: [BootScene, PreloadScene, GameScene],
};

new Phaser.Game(config);
```

## Scenes

A Phaser game is a stack of **scenes**. Typical roles:

- **Boot**: load the minimum needed to show a loading bar; set scale/registry.
- **Preload**: load all assets with a progress bar (see `references/rendering.md`).
- **Game**: the gameplay loop.
- **UI / HUD**: a parallel scene rendered above Game (`this.scene.launch("UI")`), so HUD logic stays separate from world logic.

Switch with `this.scene.start("Game")`; run in parallel with `this.scene.launch("UI")`; pause/resume with `this.scene.pause/resume`.

## Decouple logic from rendering (testability)

Keep **pure game logic** (damage math, economy, progression, RNG-driven rules) in `src/systems/` as plain TS with **no Phaser imports**. Scenes/entities call into those systems. This makes the core unit-testable with Vitest in milliseconds, and keeps balance numbers (from `docs/GAME.md`) in one place.

```ts
// src/systems/combat.ts  (no Phaser import — pure, testable)
export function applyDamage(health: number, amount: number): number {
  return Math.max(0, health - amount);
}
```

```ts
// src/entities/player.ts  (Phaser glue calls the pure system)
import { applyDamage } from "../systems/combat";
// ...
takeDamage(amount: number): void {
  this.health = applyDamage(this.health, amount);
  this.emit("health-changed", this.health);
  if (this.health === 0) this.emit("died");
}
```

## State

- **Scene-local state** lives on the scene/entity.
- **Cross-scene state** (score, level, settings) goes in the **Registry** (`this.registry.set/get`) or a small typed store module in `src/data/`.
- **Events** across scenes use `this.game.events` (global) or a dedicated event-emitter module; prefer local `this.events` where the relationship is local.

## Input

Define input centrally. For keyboard: `this.input.keyboard.addKeys(...)` or `createCursorKeys()`. For pointer/touch: `this.input.on("pointerdown", ...)`. Support gamepad via `this.input.gamepad`. Map actions (not raw keys) in a small input module so rebinding and multi-scheme support are easy. Expose a `window.__test` hook (see `references/templates.md`) to drive inputs deterministically in Playwright.

## Swapping the engine

This guide anchors on Phaser, but the squad isn't coupled to it. If you swap:

- **Excalibur** — TS-native actor/component model; `Actor`, `Scene`, `Engine`. Better typings, leaner. Keep the same `src/systems/` decoupling.
- **PixiJS** — renderer only; you own the game loop (`Ticker`), input, and physics. Best when you want full control or a custom engine.
- **Kaplay** — ECS, terse API, great for jams/prototypes; smaller ecosystem.

In all cases keep pure logic in `src/systems/`, assets in `public/`, and the Vite + TS + Vitest + Playwright tooling unchanged.
