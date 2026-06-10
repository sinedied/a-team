# Phaser — Performance

Read this when hitting frame-rate issues, GC stutter, or setting a perf budget.

## Rendering

- **Minimize draw calls**: batch sprites that share a texture; pack art into **atlases** so the renderer can batch. Mixing textures breaks the batch.
- **Texture sizes**: keep atlas pages within GPU limits; powers-of-two are safe everywhere.
- **Overdraw**: limit large additive/transparent layers and particle storms, especially on mobile.
- **Containers/Layers**: group for transforms, but deep nesting costs — keep trees shallow.

## CPU / memory

- **Object pooling**: reuse bullets, enemies, particles via `Phaser.GameObjects.Group` with `get()`/`killAndHide()` instead of `new`/`destroy()` churn — this is the single biggest win against GC stutter.
- **`update()` discipline**: avoid per-frame allocations (no `new Vector2()` in a hot loop — reuse), cache lookups, avoid scanning large arrays every frame.
- **Destroy what you remove**: call `destroy()` on objects/timers/tweens you discard to avoid leaks; remove event listeners.
- **Tweens/timers**: prefer a few pooled tweens over thousands of one-shot ones.

## Mobile / low-end

- Detect with `this.sys.game.device`; scale down resolution, particle counts, and effects.
- Cap the render resolution and use `Phaser.Scale.FIT`; avoid huge canvases.
- Prefer Arcade over Matter physics.

## Profiling & budget

1. Use the browser **DevTools Performance** panel (or the `chrome-devtools` skill) to find long frames and GC.
2. Expose live metrics via a `window.__debug` object (see `references/templates.md`): FPS, active object count, draw calls (`game.renderer`), scene key.
3. Sample FPS over a window (not a single reading) and report **median / p95** — `tools/capture.mjs` does this against the running game.
4. Set a budget in the spec's `## Constraints` (e.g. 60 FPS on mid-range mobile, < 5% of frames over 16.7 ms) and verify before shipping.

## Loading performance

- One **preload scene**; show a progress bar.
- Atlases + audio sprites reduce request count.
- Compress: PNG via TinyPNG/oxipng, audio as `.ogg` (+ a fallback codec).
- **Lazy-load** large/optional assets (later levels, cutscenes) on demand.
- Consider a service worker for instant warm reloads on itch/Pages.
