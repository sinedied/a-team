# Godot — Performance & Profiling

Read this when hitting frame-rate issues, setting a perf budget, or preparing a
performance pass for the playtester.

1. **Profile first, optimize second.** Use the editor **Debugger → Profiler** (script/function timings) and **Monitors** (FPS, draw calls, physics, memory, objects).
2. **Read live metrics** via the `Performance` singleton (the `PerfLogger` template in `references/templates.md` writes these to CSV for offline analysis with `tools/perf_summarize.py`):

   ```gdscript
   Performance.get_monitor(Performance.TIME_FPS)
   Performance.get_monitor(Performance.TIME_PROCESS)          # main thread, seconds
   Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
   Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
   Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
   Performance.get_monitor(Performance.MEMORY_STATIC)
   ```

3. **`_process` / `_physics_process` discipline**: keep per-frame code minimal. Cache lookups (don't `get_node` every frame), avoid allocations in hot loops, prefer signals/timers over polling.
4. **Object pooling**: reuse bullets/particles/enemies instead of `instantiate()`/`queue_free()` churn.
5. **2D**: watch draw calls and overdraw; batch via texture atlases; cap `Light2D` count. **3D**: watch draw calls, vertex count, real-time light/shadow count; bake GI; use LOD and occlusion; prefer primitive collision shapes.
6. **Set a budget** in the spec's `## Constraints` (e.g. 60 FPS, ≤ 8 ms frame on target hardware) and verify with `tools/perf_summarize.py`.

## Optimization workflow

1. Reproduce the slowdown with a repeatable scenario (ideally a Playtest Hook).
2. Profile to find the hot spot — script time vs render time vs physics time.
3. Fix the dominant cost first (Amdahl's law); re-profile.
4. Capture a `PerfLogger` CSV before and after; compare with `perf_summarize.py`.
5. Record the win and the technique in `docs/memory/decisions.md`.
