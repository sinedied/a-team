# Phaser — Dev, Test & Deploy Workflows

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
e2e      → npm run e2e          # Playwright canvas/visual tests
lint     → npm run lint
build    → npm run build        # type-check + production bundle to dist/
preview  → npm run preview      # serve the built bundle locally
capture  → node tools/capture.mjs --url http://localhost:5173 --out shot.png --seconds 5
```

## Unit testing (Vitest)

Test the **pure systems** (`src/systems/`) — no browser needed, milliseconds to run.

```ts
// test/combat.test.ts
import { describe, it, expect } from "vitest";
import { applyDamage } from "../src/systems/combat";

describe("applyDamage", () => {
  it("reduces health", () => expect(applyDamage(100, 30)).toBe(70));
  it("never goes below zero", () => expect(applyDamage(10, 9999)).toBe(0));
});
```

## E2E / canvas testing (Playwright)

Drive the real game in a headless browser: boot it, exercise it via a `window.__test`
hook (see `references/templates.md`), screenshot for visual regression, and assert on
`window.__debug` state.

```ts
// test/smoke.spec.ts
import { test, expect } from "@playwright/test";

test("game boots and renders", async ({ page }) => {
  const errors: string[] = [];
  page.on("console", (m) => m.type() === "error" && errors.push(m.text()));
  await page.goto("http://localhost:5173");
  await page.waitForFunction(() => (window as any).__debug?.booted === true, null, { timeout: 10_000 });
  await expect(page.locator("canvas")).toBeVisible();
  expect(errors, errors.join("\n")).toHaveLength(0);
  await page.screenshot({ path: "docs/playtest/screenshots/boot.png" });
});
```

Run the dev server (or `preview` on the built bundle) before Playwright; Playwright's
`webServer` config can start it automatically.

## CI (GitHub Actions)

```yaml
name: Web Game CI
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
      - run: npm run test
      - run: npm run build
      - run: npx playwright install --with-deps chromium
      - run: npm run preview & npx wait-on http://localhost:4173 && npm run e2e
```

## Deploy

**Relative paths are mandatory** — set `base: './'` in `vite.config.ts` so the build
works under itch.io and GitHub Pages subpaths.

- **itch.io**: `npm run build` → zip `dist/` (or `butler push dist/ user/game:html`). Set the project to HTML, mark `index.html` as the main file, enable fullscreen.
- **GitHub Pages**: build, then publish `dist/` to the `gh-pages` branch (e.g. with `actions/deploy-pages`). Confirm `base` matches the repo subpath.

**Before publishing, catch the #1 silent deploy bug — root-absolute asset paths.** They
work in dev but 404 under a subpath. A quick grep flags them (should print nothing):

```sh
grep -rnE '["'"'"'(]/(assets|sprites|audio|img|images|tilemaps)/' src index.html
```

Also confirm `base: './'` is set in your Vite config. These two checks are all you need —
no custom validator required.
