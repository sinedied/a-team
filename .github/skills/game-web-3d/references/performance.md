# Babylon.js — Performance

Read this when hitting frame-rate issues, GPU stalls, or setting a perf budget.
3D adds failure modes 2D doesn't: draw calls, overdraw, shadow/light cost, GPU
memory, and WebGL context-loss.

## Draw calls & batching

- **Instances / thin instances**: render thousands of copies of one mesh in a single draw call (`mesh.createInstance(...)` or thin instances for static crowds). The single biggest 3D win.
- **Merge** static meshes sharing a material (`Mesh.MergeMeshes`).
- **Share materials** — each unique material/texture set can break batching.
- Watch the **draw-call counter** (`SceneInstrumentation.drawCallsCounter`, surfaced via `window.__debug`).

## CPU / per-frame discipline

- **Freeze** what doesn't change: `mesh.freezeWorldMatrix()` for static meshes, `material.freeze()`, `scene.freezeActiveMeshes()` when the active set is stable.
- Reuse math temporaries — don't allocate `new Vector3()`/`Matrix` in the render loop; use the `*ToRef` variants.
- Disable picking on non-interactive meshes (`mesh.isPickable = false`).

## GPU / rendering cost

- **Shadows** are the most common sink: few casters, tight shadow frustum, modest map size, PCF/blur tuned.
- **Overdraw**: limit large transparent layers and heavy particle systems; use `GPUParticleSystem` for big counts.
- **Culling/LOD**: frustum culling is automatic; add `mesh.addLODLevel(distance, lowMesh)` for distant detail reduction; use octrees (`scene.createOrUpdateSelectionOctree()`) for very large scenes.
- **Hardware scaling**: `engine.setHardwareScalingLevel(n)` to render below display resolution on weak GPUs.
- **WebGPU**: switch the engine (see `references/architecture.md`) for lower driver overhead where supported.

## Memory & context-loss

- Dispose meshes/textures/materials you remove (`.dispose()`); textures are the main GPU-memory consumer.
- Handle **WebGL context-loss** (`webglcontextlost` / `webglcontextrestored`) — long sessions and heavy scenes can trigger it; surface it (the `window.__debug` template + `capture.mjs` flag it).

## Profiling & budget

1. Use the **Babylon Inspector** (`scene.debugLayer.show()`) — stats tab for FPS, draw calls, active meshes, GPU frame time.
2. Use `SceneInstrumentation` / `EngineInstrumentation` for programmatic counters; surface them via `window.__debug` (see `references/templates.md`).
3. Sample FPS over a window and report **median / p95** — `tools/capture.mjs` does this. **Run with a GPU**, not headless software WebGL, for real numbers.
4. Set a budget in the spec's `## Constraints` (e.g. 60 FPS at 1080p on a mid GPU, draw calls < N, no context-loss) and verify before shipping.
