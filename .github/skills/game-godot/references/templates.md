# Godot — GDScript Templates

Drop these into the game (they are GDScript, not Python). They power deterministic
capture and the performance pipeline used by `tools/perf_summarize.py` and the playtester.

## PerfLogger autoload

Register as `PerfLogger` (Project Settings → Autoload). Writes a CSV consumed by
`tools/perf_summarize.py`.

```gdscript
# globals/perf_logger.gd  (autoload as "PerfLogger")
extends Node

@export var enabled: bool = false
@export var sample_every_frames: int = 10
@export var output_path: String = "user://perf.csv"

var _file: FileAccess
var _frame: int = 0

func _ready() -> void:
    if not enabled:
        set_process(false)
        return
    _file = FileAccess.open(output_path, FileAccess.WRITE)
    _file.store_line("frame,fps,frame_ms,draw_calls,nodes,mem_static_mb")

func _process(_delta: float) -> void:
    _frame += 1
    if _frame % sample_every_frames != 0:
        return
    var fps := Performance.get_monitor(Performance.TIME_FPS)
    var frame_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
    var draws := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
    var mem := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
    _file.store_line("%d,%f,%f,%d,%d,%f" % [_frame, fps, frame_ms, draws, nodes, mem])

func _exit_tree() -> void:
    if _file:
        _file.flush()
        _file.close()
```

## Screenshot helper

Deterministic viewport capture (call from a debug key or a headless script).

```gdscript
# tools/screenshot.gd  (run: godot --headless -s tools/screenshot.gd -- res://scenes/main.tscn out.png)
extends SceneTree

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    var scene_path := args[0] if args.size() > 0 else "res://scenes/main.tscn"
    var out_path := args[1] if args.size() > 1 else "screenshot.png"
    var packed: PackedScene = load(scene_path)
    var instance := packed.instantiate()
    root.add_child(instance)
    await process_frame
    await process_frame  # let one full frame render
    var image := root.get_texture().get_image()
    image.save_png(out_path)
    quit()
```

## Debug overlay / cheat toggles

Exposes Playtest Hooks (godmode, level skip, spawn) behind a dev-only flag.

```gdscript
# globals/debug.gd  (autoload as "Debug")
extends CanvasLayer

var godmode: bool = false

func _ready() -> void:
    visible = OS.is_debug_build()

func _unhandled_input(event: InputEvent) -> void:
    if not OS.is_debug_build():
        return
    if event.is_action_pressed("debug_godmode"):
        godmode = not godmode
    elif event.is_action_pressed("debug_skip_level"):
        Events.request_skip_level.emit()
```
