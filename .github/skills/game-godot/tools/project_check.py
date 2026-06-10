#!/usr/bin/env python3
"""Validate a Godot 4 project's structure and conventions.

Checks (warnings unless noted):
  - project.godot exists (error if missing)
  - recommended directories present (assets/, scenes/, test/ or tests/)
  - .gd / .tscn / .tres files use snake_case names
  - autoload paths in project.godot resolve to existing files (error)
  - .gitignore exists and ignores .godot/
  - export_presets.cfg exists

Exit code: 0 if no errors (warnings allowed), 1 if any error, 2 on bad input.
With --strict, warnings are treated as errors. Stdlib only.

Examples:
  python project_check.py
  python project_check.py --project path/to/game --json
  python project_check.py --strict
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys

SNAKE_RE = re.compile(r"^[a-z0-9]+(_[a-z0-9]+)*\.(gd|tscn|tres|gdshader)$")
RECOMMENDED_DIRS = ["assets", "scenes"]
TEST_DIRS = ["test", "tests"]
SKIP_DIRS = {".godot", ".git", "addons", "build", "export", ".import"}


def find_autoloads(project_godot: str) -> list[tuple[str, str]]:
    """Return (name, res_path) pairs from the [autoload] section."""
    autoloads: list[tuple[str, str]] = []
    in_section = False
    try:
        with open(project_godot, encoding="utf-8") as f:
            for line in f:
                stripped = line.strip()
                if stripped.startswith("[") and stripped.endswith("]"):
                    in_section = stripped == "[autoload]"
                    continue
                if in_section and "=" in stripped:
                    name, _, value = stripped.partition("=")
                    value = value.strip().strip('"')
                    # Autoload values look like "*res://globals/foo.gd" (* = enabled)
                    value = value.lstrip("*")
                    autoloads.append((name.strip(), value))
    except OSError:
        pass
    return autoloads


def res_to_fs(project_dir: str, res_path: str) -> str:
    return os.path.join(project_dir, res_path.replace("res://", "", 1))


def main() -> int:
    p = argparse.ArgumentParser(description="Validate a Godot project's structure & conventions.")
    p.add_argument("--project", default=".", help="Project directory (default: .).")
    p.add_argument("--strict", action="store_true", help="Treat warnings as errors.")
    p.add_argument("--json", action="store_true", help="Emit a JSON result.")
    args = p.parse_args()

    proj = args.project
    errors: list[str] = []
    warnings: list[str] = []

    project_godot = os.path.join(proj, "project.godot")
    if not os.path.isfile(project_godot):
        _emit({"ok": False, "errors": [f"project.godot not found in {proj!r}"], "warnings": []}, args.json)
        return 2

    # Recommended directories.
    for d in RECOMMENDED_DIRS:
        if not os.path.isdir(os.path.join(proj, d)):
            warnings.append(f"recommended directory missing: {d}/")
    if not any(os.path.isdir(os.path.join(proj, d)) for d in TEST_DIRS):
        warnings.append("no test/ or tests/ directory found — add automated tests")

    # Naming conventions for source/scene/resource files.
    for root, dirs, files in os.walk(proj):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
        for fn in files:
            if fn.endswith((".gd", ".tscn", ".tres", ".gdshader")) and not SNAKE_RE.match(fn):
                rel = os.path.relpath(os.path.join(root, fn), proj)
                warnings.append(f"non-snake_case file name: {rel}")

    # Autoload references resolve.
    for name, res_path in find_autoloads(project_godot):
        if not res_path.startswith("res://"):
            continue
        fs = res_to_fs(proj, res_path)
        if not os.path.isfile(fs):
            errors.append(f"autoload {name!r} points to missing file: {res_path}")

    # .gitignore ignores .godot/
    gitignore = os.path.join(proj, ".gitignore")
    if not os.path.isfile(gitignore):
        warnings.append(".gitignore missing — add one that ignores .godot/")
    else:
        with open(gitignore, encoding="utf-8") as f:
            content = f.read()
        if ".godot/" not in content and ".godot" not in content.split():
            warnings.append(".gitignore does not ignore .godot/ (the regenerable cache)")

    # Export presets.
    if not os.path.isfile(os.path.join(proj, "export_presets.cfg")):
        warnings.append("export_presets.cfg missing — configure exports before release playtests")

    if args.strict:
        errors += warnings
        warnings = []

    result = {"ok": len(errors) == 0, "errors": errors, "warnings": warnings}
    _emit(result, args.json)
    return 0 if result["ok"] else 1


def _emit(result: dict, as_json: bool) -> None:
    if as_json:
        print(json.dumps(result, indent=2))
        return
    status = "PASS" if result["ok"] else "FAIL"
    print(f"[{status}] project_check")
    for e in result["errors"]:
        print(f"  ERROR  {e}")
    for w in result["warnings"]:
        print(f"  warn   {w}")
    if not result["errors"] and not result["warnings"]:
        print("  no issues found")


if __name__ == "__main__":
    sys.exit(main())
