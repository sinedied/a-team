# Phaser — TypeScript Templates

Drop these into the game. They power deterministic testing/capture and the perf pipeline
used by `tools/capture.mjs` and the playtester.

## Debug metrics surface (`window.__debug`)

A stable object the playtester / Playwright / `capture.mjs` can read without depending on
Phaser internals. Update it once per frame from the game scene.

```ts
// src/debug/debug.ts
export interface DebugInfo {
  booted: boolean;
  scene: string;
  fps: number;
  objects: number;
  drawCalls: number;
}

declare global {
  interface Window { __debug?: DebugInfo; }
}

export function publishDebug(game: Phaser.Game, scene: Phaser.Scene): void {
  const renderer = game.renderer as Phaser.Renderer.WebGL.WebGLRenderer;
  window.__debug = {
    booted: true,
    scene: scene.scene.key,
    fps: Math.round(game.loop.actualFps),
    objects: scene.children.length,
    drawCalls: (renderer.drawCount ?? 0) as number,
  };
}
```

```ts
// in your Game scene's update():
import { publishDebug } from "../debug/debug";
update(): void {
  // ...game logic...
  publishDebug(this.game, this);
}
```

## Deterministic test hook (`window.__test`)

Lets Playwright drive inputs and state deterministically (no synthetic key-event guessing).
Gate it behind a dev/test flag so it never ships enabled in production.

```ts
// src/debug/test-hooks.ts
export function installTestHooks(scene: Phaser.Scene): void {
  if (!import.meta.env.DEV && !location.search.includes("test=1")) return;
  (window as any).__test = {
    press: (action: string) => scene.events.emit("test-press", action),
    setSeed: (seed: number) => scene.registry.set("rngSeed", seed),
    spawn: (type: string, x: number, y: number) => scene.events.emit("test-spawn", { type, x, y }),
    getState: () => ({ score: scene.registry.get("score") }),
  };
}
```

## Seeded RNG

Reproducible randomness for tests, captures, and fair runs. Phaser ships a seeded RNG; or
use this tiny standalone mulberry32 for pure systems.

```ts
// src/systems/rng.ts
export function mulberry32(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
// Phaser-native alternative inside a scene:
//   this.rng = new Phaser.Math.RandomDataGenerator([String(seed)]);
//   this.rng.frac(); this.rng.between(1, 6);
```

## Playwright capture spec (alternative to capture.mjs)

If you prefer the test-runner over the standalone `tools/capture.mjs`, this spec captures a
screenshot + an FPS sample from `window.__debug`.

```ts
// test/capture.spec.ts
import { test, expect } from "@playwright/test";

test("capture + fps sample", async ({ page }) => {
  await page.goto("http://localhost:5173/?test=1");
  await page.waitForFunction(() => (window as any).__debug?.booted === true);
  const samples: number[] = [];
  for (let i = 0; i < 40; i++) {                 // ~ a few seconds at 100ms
    samples.push(await page.evaluate(() => (window as any).__debug.fps));
    await page.waitForTimeout(100);
  }
  samples.sort((a, b) => a - b);
  const p5 = samples[Math.floor(samples.length * 0.05)];
  expect(p5, "p5 FPS").toBeGreaterThan(50);
  await page.screenshot({ path: "docs/playtest/screenshots/capture.png" });
});
```
