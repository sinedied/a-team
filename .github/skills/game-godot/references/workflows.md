# Godot — Dev, Test & Export Workflows

Read this for the day-to-day loop, testing setup, and CI/export.

## Dev workflow

```
setup    → install Godot 4.x; first import:  python tools/godot_run.py --import
run      → python tools/godot_run.py --scene scenes/main.tscn          # windowed
smoke    → python tools/godot_run.py --headless --quit-after 120 --json # CI smoke
test     → python tools/godot_test.py --runner gdunit4 --test-dir res://test
format   → gdformat .   &&   gdlint .
profile  → run with PerfLogger autoload enabled → python tools/perf_summarize.py user://perf.csv
validate → python tools/project_check.py
export   → godot --headless --export-release "Linux/X11" build/game.x86_64
publish  → butler push build/ user/game:linux
```

## Testing workflow (GdUnit4)

1. Install GdUnit4 from the Asset Library (or copy into `addons/gdUnit4/`) and enable the plugin.
2. Put tests under `test/`, mirroring `scenes/` and `resources/`. Name files `*_test.gd`.
3. Write tests extending `GdUnitTestSuite`:

   ```gdscript
   # test/player_test.gd
   extends GdUnitTestSuite

   func test_take_damage_reduces_health() -> void:
       var player := preload("res://scenes/player/player.tscn").instantiate()
       add_child(player)
       player.take_damage(30)
       assert_int(player.health).is_equal(70)

   func test_damage_cannot_go_below_zero() -> void:
       var player := preload("res://scenes/player/player.tscn").instantiate()
       add_child(player)
       player.take_damage(9999)
       assert_int(player.health).is_equal(0)
   ```

4. Run headless locally and in CI with `tools/godot_test.py` (auto-detects GdUnit4's `runtest` wrapper or the `GdUnitCmdTool.gd` entry point). Emit JUnit XML for CI dashboards.

`GUT` is a lighter GDScript-only alternative; `tools/godot_test.py --runner gut` supports it.

## CI (GitHub Actions)

```yaml
name: Godot CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { lfs: true }
      - uses: chickensoft-games/setup-godot@v2
        with: { version: 4.4.0 }
      - run: godot --headless --import          # build the resource cache
      - run: python tools/godot_test.py --runner gdunit4 --test-dir res://test --report-dir reports
      - run: godot --headless --export-release "Linux/X11" build/game.x86_64
```

## Version control

`.gitignore` essentials:

```gitignore
# Godot 4 regenerable cache
.godot/
# Exported builds
/build/
/export/
# OS / editor noise
.DS_Store
*.tmp
```

Use Git LFS for binary assets (`.png`, `.webp`, `.ogg`, `.wav`, `.glb`, `.blend`):

```gitattributes
*.png filter=lfs diff=lfs merge=lfs -text
*.webp filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text
*.glb filter=lfs diff=lfs merge=lfs -text
```
