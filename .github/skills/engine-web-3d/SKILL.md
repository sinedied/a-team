---
name: engine-web-3d
description: "Launch and inspect web-based 3D games (Three.js, Babylon.js, PlayCanvas, WebGL/WebGPU) for playtesting. Builds on chrome-devtools for browser control: navigates to the dev server, captures screenshots, monitors FPS, inspects WebGL/WebGPU state, and surfaces shader / context-lost errors. Use when the project's package.json depends on Three.js, Babylon.js, PlayCanvas, or uses WebGL/WebGPU 3D primitives."
---

# Web 3D Engine Adapter

This skill provides the launch / capture primitives for web-based 3D games. It wraps the `chrome-devtools` skill with 3D-aware probes for FPS, draw calls, scene graph state, and WebGL/WebGPU diagnostics. Invoked by the `playtest-harness` skill.

3D web games surface a different failure class than 2D: shader compile failures, WebGL context loss, GPU memory exhaustion, asset (GLTF / textures / shaders) loading errors. This skill focuses on those.

## Prerequisites

- Node and the project's package manager installed (`npm`, `pnpm`, or `yarn`).
- The `chrome-devtools` MCP server configured (the `chrome-devtools` skill handles auto-config).
- A `package.json` declaring one of: `three`, `@babylonjs/core`, `playcanvas`, or hand-rolled WebGL/WebGPU.
- For meaningful 3D testing, Chrome must run with GPU acceleration enabled. Headless mode supports WebGL but with software rendering — note this in the playtest log (FPS / load measurements are not representative of real hardware in headless software-rendered mode).

## Detect the framework

Read `package.json` dependencies:

| Dependency | Framework | Debug accessor (in console) |
|------------|-----------|-----------------------------|
| `three` | Three.js | `renderer.info`, `scene.children`, `renderer.capabilities` |
| `@babylonjs/core` | Babylon.js | `engine.getFps()`, `scene.meshes`, `engine.getGlInfo()` |
| `playcanvas` | PlayCanvas | `app.stats`, `app.scene.root.children` |
| none of above | hand-rolled WebGL/WebGPU | recommend the coder expose `window.__debug` with `fps`, `drawCalls`, `triangles`, `programs`, `textures` |

If no recognized dependency is found, ask the coder to expose a minimal `window.__debug` object.

## Common operations

### Start the dev server

```sh
npm run dev
```

Same as web-2D: capture the URL from stdout. Common ports: 5173 (Vite), 3000 (Next/Webpack), 8080 (default), 1234 (Parcel).

### Open in browser

Via `chrome-devtools`: `navigate_page` to the captured URL, `wait_for` until the canvas is visible **and** a non-zero draw-call count is reported (3D games can show an empty canvas while still loading assets).

### Capture FPS and render stats

Use `evaluate_script`:

```js
// Three.js
return {
  fps: 1000 / window.renderer.info.render.frame_time, // if measured
  drawCalls: window.renderer.info.render.calls,
  triangles: window.renderer.info.render.triangles,
  geometries: window.renderer.info.memory.geometries,
  textures: window.renderer.info.memory.textures
};

// Babylon.js
return {
  fps: window.engine.getFps(),
  drawCalls: window.scene.getActiveMeshes().length,
  triangles: window.scene.getTotalVertices()
};

// PlayCanvas
return window.app.stats;
```

For trend capture, sample every 250ms for 10 seconds and report median / p95.

### Inspect the scene graph

```js
// Three.js: list scene children with types
return window.scene.children.map(c => ({type: c.type, name: c.name, visible: c.visible}));

// Babylon.js
return window.scene.meshes.map(m => ({name: m.name, vertices: m.getTotalVertices(), visible: m.isVisible}));
```

Useful for verifying that an expected entity is present in the scene at a given gameplay state.

### Detect WebGL / WebGPU errors

WebGL errors are silent by default. Install a probe at navigation time:

```js
// Three.js: hook into renderer.getContext().getError() each frame
// Babylon.js: scene.onAfterRenderObservable.add(() => ...) then check engine._gl.getError()
// Generic WebGL: poll gl.getError() periodically

window.__gl_errors = [];
const gl = window.renderer?.getContext?.() ?? window.engine?._gl;
if (gl) {
  setInterval(() => {
    const err = gl.getError();
    if (err !== gl.NO_ERROR) window.__gl_errors.push({code: err, t: performance.now()});
  }, 250);
}
```

Read `window.__gl_errors` periodically and include any in the playtest log. Common codes: `INVALID_OPERATION (1282)`, `OUT_OF_MEMORY (1285)`, `CONTEXT_LOST_WEBGL (37442)`.

### Detect context loss

```js
const canvas = document.querySelector('canvas');
window.__context_lost = false;
canvas.addEventListener('webglcontextlost', () => { window.__context_lost = true; });
canvas.addEventListener('webglcontextrestored', () => { window.__context_lost = 'restored'; });
```

Context loss in production is rare but catastrophic. Probe in long playtest sessions and on resource-heavy scenes.

### Asset loading errors

GLTF / texture / shader load failures often print to console without throwing. Hook console as in `engine-web-2d`, then additionally listen for framework-specific load events:

```js
// Three.js GLTFLoader: pass an onError callback in your loader code (coder must instrument)
// Babylon.js: scene.onErrorObservable.add(err => window.__asset_errors.push(err))
```

If the project doesn't instrument load errors, recommend the coder add it once.

### Capture screenshots

Use `chrome-devtools` `take_screenshot`. **Important**: 3D contexts often use `preserveDrawingBuffer: false` for performance, which makes `toDataURL()`-based screenshots return an empty image. Workarounds:

1. Ask the coder to enable `preserveDrawingBuffer: true` in dev builds (small perf cost, acceptable for testing).
2. Trigger an explicit re-render before screenshot: `evaluate_script` with `renderer.render(scene, camera)` immediately before `take_screenshot`.
3. Use the framework's own screenshot API if it exists (e.g. Babylon's `Tools.CreateScreenshot`).

### Drive input

Same as web-2D: dispatch synthetic `KeyboardEvent` / `MouseEvent` / pointer events via `chrome-devtools`. For 3D games using `PointerLockControls` or similar, pointer-lock must be acquired by a real user gesture — automated tests will need a `window.__test` API exposed by the coder to drive camera / character movement deterministically.

## Health checks the playtester runs

Before a playtest session:

1. `package.json` lists a recognized 3D framework or `window.__debug` is exposed
2. `npm install` completes without errors
3. `npm run dev` starts and binds a port
4. Page loads in Chrome without console errors at navigation
5. Canvas is visible **and** draw-call count is > 0 within 5 seconds (3D scenes need asset loading)
6. WebGL / WebGPU context is healthy (no `CONTEXT_LOST_WEBGL` immediately on launch)
7. No silent GL errors in the first 5 seconds

Failure at any step = critical playtest finding, log and return to coder.

## Rules

- DO NOT modify project source files from this skill. Capture and observe only.
- DO NOT assume a framework — detect via `package.json` or ask. The wrong debug API returns garbage.
- DO NOT trust headless-mode performance numbers as representative. Note in the log: "headless / software-rendered" if applicable.
- DO NOT capture screenshots without verifying `preserveDrawingBuffer: true` or using a framework-native screenshot API. An empty PNG is worse than no PNG.
- DO NOT ignore silent WebGL errors. They compound and often precede context loss.
- DO NOT skip GPU memory monitoring on long sessions or heavy scenes. Memory leaks in textures / geometries are the most common cause of late-game crashes.
- DO NOT leave the dev server running after the playtest session ends. Kill the process.
- When framework detection fails, ask the user / coder rather than guessing.
