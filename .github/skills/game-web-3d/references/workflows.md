# Babylon.js — Dev, Test & Deploy Workflows

Read this for the day-to-day loop, testing, and shipping. All commands are native
npm scripts — this skill does not wrap them.

## package.json scripts

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc --noEmit && vite build",
    "preview": "vite preview",
    "test": "vitest run",
    "test:watch": "vitest",
    "e2e": "playwright test",
    "lint": "eslint . && prettier --check ."
  }
}
```

## Dev loop

```
dev      → npm run dev          # Vite HMR; opens http://localhost:5173
test     → npm run test         # Vitest unit tests (pure systems)
e2e      → npm run e2e          # Playwright WebGL tests (run with a GPU)
lint     → npm run lint
build    → npm run build        # type-check + production bundle to dist/
preview  → npm run preview      # serve the built bundle locally
capture  → node tools/capture.mjs --url http://localhost:5173 --out shot.png --seconds 5 --headed
```

## Vite + WASM (Havok)

Havok ships as WebAssembly. Vite handles `.wasm` out of the box, but for production make
sure the file is emitted and fetched from the correct `base`. If you preload it, use a URL
import (`new URL('...', import.meta.url)`) so Vite fingerprints and serves it.

## Unit testing (Vitest)

Test the **pure systems** (`src/systems/`) — no browser or GPU needed.

```ts
// test/combat.test.ts
import { describe, it, expect } from "vitest";
import { applyDamage } from "../src/systems/combat";

describe("applyDamage", () => {
  it("reduces health", () => expect(applyDamage(100, 30)).toBe(70));
  it("never goes below zero", () => expect(applyDamage(10, 9999)).toBe(0));
});
```

## E2E / WebGL testing (Playwright)

Drive the real scene: boot it, exercise it via `window.__test`, screenshot for visual
regression, and assert on `window.__debug` (active meshes > 0, no context-loss).

```ts
// test/smoke.spec.ts
import { test, expect } from "@playwright/test";

test("scene boots and renders", async ({ page }) => {
  const errors: string[] = [];
  page.on("console", (m) => m.type() === "error" && errors.push(m.text()));
  page.on("pageerror", (e) => errors.push(String(e)));
  await page.goto("http://localhost:5173");
  await page.waitForFunction(() => (window as any).__debug?.activeMeshes > 0, null, { timeout: 15_000 });
  expect(await page.evaluate(() => (window as any).__debug.contextLost)).toBe(false);
  expect(errors, errors.join("\n")).toHaveLength(0);
  await page.screenshot({ path: "docs/playtest/screenshots/boot.png" });
});
```

> **GPU caveat**: in headless CI, WebGL may fall back to software (SwiftShader) — rendering
> works but FPS/timings are not representative. For real perf numbers, run headed with a GPU,
> or a CI runner with GPU access. Snapshot pixels can differ across GPU drivers; prefer
> structural assertions (state, counts) over strict pixel diffs unless you pin the renderer.

## CI (GitHub Actions)

```yaml
name: Web3D Game CI
on: [push, pull_request]
jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npm run lint
      - run: npm run test          # pure-logic units (no GPU needed)
      - run: npm run build
      - run: npx playwright install --with-deps chromium
      - run: npm run preview & npx wait-on http://localhost:4173 && npm run e2e
        # WebGL runs under SwiftShader here — assert state/structure, not FPS.
```

## Deploy

**Relative paths are mandatory** — set `base: './'` in `vite.config.ts` so the build works
under itch.io / GitHub Pages subpaths (this includes the Havok `.wasm` and `.glb`/`.env` assets).

- **itch.io**: `npm run build` → zip `dist/` (or `butler push dist/ user/game:html`). Set the project to HTML, mark `index.html` as main, enable fullscreen. 3D bundles are larger — confirm the upload size and enable compression.
- **GitHub Pages**: publish `dist/` to `gh-pages`; confirm `base` matches the repo subpath.

**Before publishing, catch the #1 silent deploy bug — root-absolute asset paths** (work in dev,
404 under a subpath). Should print nothing:

```sh
grep -rnE '["'"'"'(]/(assets|models|textures|env|audio)/' src index.html
```
