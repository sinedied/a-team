# Babylon.js — TypeScript Templates

Drop these into the game. They power deterministic testing/capture and the perf/health
surface read by `tools/capture.mjs` and the playtester.

## Debug metrics surface (`window.__debug`)

A stable object the playtester / Playwright / `capture.mjs` can read without depending on
Babylon internals. Wire it once at boot, update per frame.

```ts
// src/debug/debug.ts
import { Engine, Scene, SceneInstrumentation } from "@babylonjs/core";

export interface DebugInfo {
  booted: boolean;
  fps: number;
  activeMeshes: number;
  drawCalls: number;
  contextLost: boolean;
}

declare global {
  interface Window { __debug?: DebugInfo; }
}

export function installDebug(engine: Engine, scene: Scene, canvas: HTMLCanvasElement): void {
  const instr = new SceneInstrumentation(scene);
  instr.captureFrameTime = true;

  const info: DebugInfo = { booted: false, fps: 0, activeMeshes: 0, drawCalls: 0, contextLost: false };
  window.__debug = info;

  canvas.addEventListener("webglcontextlost", () => { info.contextLost = true; });
  canvas.addEventListener("webglcontextrestored", () => { info.contextLost = false; });

  scene.onAfterRenderObservable.add(() => {
    info.booted = true;
    info.fps = Math.round(engine.getFps());
    info.activeMeshes = scene.getActiveMeshes().length;
    info.drawCalls = instr.drawCallsCounter.current;
  });
}
```

```ts
// in main.ts, after creating engine + scene:
import { installDebug } from "./debug/debug";
installDebug(engine, scene, canvas);
```

## Deterministic test hook (`window.__test`)

Lets Playwright drive inputs/state deterministically. Gate behind a dev/test flag.

```ts
// src/debug/test-hooks.ts
import type { Scene } from "@babylonjs/core";

export function installTestHooks(scene: Scene): void {
  if (!import.meta.env.DEV && !location.search.includes("test=1")) return;
  (window as any).__test = {
    press: (action: string) => scene.onKeyboardObservable.notifyObservers({ type: 1, event: { key: action } } as any),
    setSeed: (seed: number) => ((window as any).__seed = seed),
    spawn: (type: string, x: number, y: number, z: number) =>
      scene.onBeforeRenderObservable.addOnce(() => scene.metadata?.spawn?.(type, x, y, z)),
    getState: () => ({ ...(scene.metadata?.state ?? {}) }),
  };
}
```

## Inspector toggle (dev)

```ts
// src/debug/inspector.ts  (import "@babylonjs/inspector" only in dev to keep it out of prod bundles)
import type { Scene } from "@babylonjs/core";
export async function enableInspector(scene: Scene): Promise<void> {
  if (!import.meta.env.DEV) return;
  await import("@babylonjs/inspector");
  window.addEventListener("keydown", (e) => {
    if (e.key === "i" && e.ctrlKey) scene.debugLayer.isVisible() ? scene.debugLayer.hide() : scene.debugLayer.show();
  });
}
```

## Seeded RNG

Reproducible randomness for tests, captures, and fair runs.

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
```

## Playwright capture spec (alternative to capture.mjs)

Captures a screenshot + FPS sample + context-loss check from `window.__debug`.

```ts
// test/capture.spec.ts
import { test, expect } from "@playwright/test";

test("capture + fps sample", async ({ page }) => {
  await page.goto("http://localhost:5173/?test=1");
  await page.waitForFunction(() => (window as any).__debug?.booted === true, null, { timeout: 15_000 });
  const samples: number[] = [];
  for (let i = 0; i < 40; i++) {
    samples.push(await page.evaluate(() => (window as any).__debug.fps));
    await page.waitForTimeout(100);
  }
  expect(await page.evaluate(() => (window as any).__debug.contextLost)).toBe(false);
  samples.sort((a, b) => a - b);
  const p5 = samples[Math.floor(samples.length * 0.05)];
  // Only assert FPS when running on a real GPU; headless/software WebGL is not representative.
  console.log("p5 FPS:", p5);
  await page.screenshot({ path: "docs/playtest/screenshots/capture.png" });
});
```
