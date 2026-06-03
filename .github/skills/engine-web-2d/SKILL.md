---
name: engine-web-2d
description: "Launch and inspect web-based 2D games (Phaser, PixiJS, Kaboom, canvas) for playtesting. Builds on chrome-devtools for browser control: navigates to the dev server, captures screenshots, monitors FPS via the engine's debug API, and surfaces console / WebGL errors. Use when the project's package.json depends on Phaser, PixiJS, Kaboom, or uses 2D canvas/WebGL primitives directly."
---

# Web 2D Engine Adapter

This skill provides the launch / capture primitives for web-based 2D games. It wraps the `chrome-devtools` skill with engine-aware probes for FPS, scene state, and engine-specific debug APIs. Invoked by the `playtest-harness` skill.

## Prerequisites

- Node and the project's package manager installed (`npm`, `pnpm`, or `yarn`).
- The `chrome-devtools` MCP server configured (the `chrome-devtools` skill handles auto-config).
- A `package.json` declaring one of: `phaser`, `pixi.js`, `kaboom`, `excalibur`, `melonjs`, or hand-rolled canvas/WebGL.

## Detect the framework

Read `package.json` dependencies to pick the right debug API:

| Dependency | Framework | Debug accessor (in console) |
|------------|-----------|-----------------------------|
| `phaser` | Phaser 3 | `game.loop.actualFps`, `game.scene.scenes` |
| `pixi.js` | PixiJS | `app.ticker.FPS`, `app.stage.children` |
| `kaboom` / `kaplay` | Kaboom/Kaplay | `debug.fps()`, `debug.objCount()` |
| `excalibur` | Excalibur.js | `engine.stats.currFrame.fps`, `engine.currentScene` |
| `melonjs` | melonJS | `me.timer.fps`, `me.state.current()` |
| none of above | hand-rolled | recommend the coder expose `window.__debug` with `fps`, `scene`, `objects` |

If no recognized dependency is found, ask the coder to expose a minimal `window.__debug` object so the harness has a stable API to query. This is a small one-time investment.

## Common operations

### Start the dev server

Run the project's dev script in the background:

```sh
npm run dev
```

Wait for the server to bind to a port. Read stdout to capture the URL (commonly `http://localhost:5173`, `:3000`, `:8080`, or `:1234`). If the project's README specifies a custom command, use that.

### Open in browser

Via the `chrome-devtools` skill: `navigate_page` to the captured URL, `wait_for` until the canvas is visible. Snapshot the page to confirm the game canvas is reachable.

### Capture FPS

Use `evaluate_script` with the framework's debug accessor:

```js
// Phaser
return window.game?.loop?.actualFps ?? null;

// PixiJS
return window.app?.ticker?.FPS ?? null;

// Kaboom / Kaplay
return window.k?.debug?.fps?.() ?? null;
```

For trend capture (FPS over time), execute a script that samples every 250ms for 10 seconds and returns the array. The harness writes this to `docs/playtest/traces/<yyyy-mm-dd>_<feature>.json` and computes min / median / p95 for the log.

### Capture screenshots

Use `chrome-devtools` `take_screenshot` with `filePath: "docs/playtest/screenshots/<feature>_<state>.png"`. For game canvases that render with `preserveDrawingBuffer: false`, the screenshot may capture an empty canvas — work around by:

1. Asking the coder to enable `preserveDrawingBuffer: true` in dev builds, OR
2. Triggering a screenshot via the engine's own API (e.g. `game.renderer.snapshot` in Phaser) and downloading the result.

### Probe gameplay state

Use `evaluate_script` to inspect game state via the framework's debug accessors:

```js
// Phaser: get active scene name + entity count
return {
  scene: window.game.scene.scenes.find(s => s.scene.isActive())?.scene.key,
  entities: window.game.scene.scenes.flatMap(s => s.children?.list?.length ?? 0)
};
```

### Drive input

Most 2D web games don't have an automation API. Drive input via `chrome-devtools`:

- Keyboard: `evaluate_script` with `document.dispatchEvent(new KeyboardEvent('keydown', { code: 'ArrowRight' }))`
- Mouse / touch: use `chrome-devtools` click / fill at canvas coordinates from the snapshot

For repeatable input sequences (acceptance scenarios), ask the coder to expose a `window.__test` API that drives inputs deterministically. This is a one-time investment that makes the harness reliable.

### Console / network error monitoring

Via `chrome-devtools`:

- `evaluate_script` to install a console error hook at navigation time:

  ```js
  window.__errors = [];
  ['error', 'warn'].forEach(level => {
    const orig = console[level];
    console[level] = (...args) => { window.__errors.push({level, args}); orig.apply(console, args); };
  });
  ```

- Periodically read `window.__errors` and include in the playtest log.
- Use the chrome-devtools tracing tools for network errors and WebGL warnings.

## Health checks the playtester runs

Before a playtest session:

1. `package.json` lists a recognized 2D framework or `window.__debug` is exposed
2. `npm install` completes without errors
3. `npm run dev` starts and binds a port
4. Page loads in Chrome without console errors at navigation
5. Canvas is visible and FPS is non-zero after 2 seconds

Failure at any step = critical playtest finding, log and return to coder.

## Rules

- DO NOT modify project source files from this skill. The coder owns the project; this skill invokes, observes, and captures.
- DO NOT assume a framework — detect via `package.json` or ask. The wrong debug API returns garbage.
- DO NOT trust a single FPS reading; capture a window (10s × 4Hz sample) and report median / p95.
- DO NOT capture screenshots that depend on randomized state without seeding RNG first. Ask the coder to expose an RNG seed for tests if randomness blocks reproducibility.
- DO NOT skip console error monitoring. A game that "looks fine" while spamming WebGL warnings is a ticking bomb.
- DO NOT leave the dev server running after the playtest session ends. Kill the process.
- When the framework detection fails, ask the user / coder rather than guessing.
