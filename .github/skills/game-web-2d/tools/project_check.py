#!/usr/bin/env python3
"""Validate a Phaser/Vite/TypeScript 2D web game project for structure & deploy.

Checks (warnings unless noted):
  - package.json exists (error) with dev + build scripts
  - phaser dependency present (warn if absent — maybe a different engine)
  - vite + typescript devDependencies present
  - tsconfig.json, index.html, a vite config, and src/ present
  - vite `base` is relative ('./') so itch.io / GitHub Pages subpaths work
  - no root-absolute asset paths ('/assets/...') in index.html or src/ (break subpaths)

Exit code: 0 if no errors (warnings allowed), 1 on errors, 2 on bad input.
With --strict, warnings become errors. Stdlib only.

Examples:
  python project_check.py
  python project_check.py --project path/to/game --json
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys

SKIP_DIRS = {"node_modules", "dist", ".git", "build", ".vite", "coverage"}
ABS_ASSET_RE = re.compile(r"""["'(]\s*/(?:assets|sprites|audio|img|images|tilemaps)/""")


def read_json(path: str) -> dict | None:
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return None


def find_vite_config(proj: str) -> str | None:
    for name in ("vite.config.ts", "vite.config.js", "vite.config.mjs", "vite.config.mts"):
        p = os.path.join(proj, name)
        if os.path.isfile(p):
            return p
    return None


def scan_absolute_assets(proj: str) -> list[str]:
    hits: list[str] = []
    targets: list[str] = []
    index_html = os.path.join(proj, "index.html")
    if os.path.isfile(index_html):
        targets.append(index_html)
    src = os.path.join(proj, "src")
    if os.path.isdir(src):
        for root, dirs, files in os.walk(src):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
            for fn in files:
                if fn.endswith((".ts", ".tsx", ".js", ".jsx", ".html")):
                    targets.append(os.path.join(root, fn))
    for path in targets:
        try:
            with open(path, encoding="utf-8", errors="ignore") as f:
                for i, line in enumerate(f, 1):
                    if ABS_ASSET_RE.search(line):
                        rel = os.path.relpath(path, proj)
                        hits.append(f"{rel}:{i}: {line.strip()[:80]}")
        except OSError:
            pass
    return hits


def main() -> int:
    p = argparse.ArgumentParser(description="Validate a Phaser/Vite/TS web game project.")
    p.add_argument("--project", default=".", help="Project directory (default: .).")
    p.add_argument("--strict", action="store_true", help="Treat warnings as errors.")
    p.add_argument("--json", action="store_true", help="Emit a JSON result.")
    args = p.parse_args()

    proj = args.project
    errors: list[str] = []
    warnings: list[str] = []

    pkg_path = os.path.join(proj, "package.json")
    pkg = read_json(pkg_path)
    if pkg is None:
        _emit({"ok": False, "errors": [f"package.json not found or invalid in {proj!r}"], "warnings": []}, args.json)
        return 2

    scripts = pkg.get("scripts", {})
    for required in ("dev", "build"):
        if required not in scripts:
            errors.append(f"package.json missing script: {required}")

    deps = {**pkg.get("dependencies", {}), **pkg.get("devDependencies", {})}
    if "phaser" not in deps:
        warnings.append("no 'phaser' dependency found — different engine? (guide assumes Phaser)")
    for dev in ("vite", "typescript"):
        if dev not in deps:
            warnings.append(f"missing devDependency: {dev}")

    for required_file in ("tsconfig.json", "index.html"):
        if not os.path.isfile(os.path.join(proj, required_file)):
            warnings.append(f"missing file: {required_file}")
    if not os.path.isdir(os.path.join(proj, "src")):
        warnings.append("missing src/ directory")

    vite_cfg = find_vite_config(proj)
    if vite_cfg is None:
        warnings.append("no vite config found (vite.config.ts/js)")
    else:
        with open(vite_cfg, encoding="utf-8", errors="ignore") as f:
            cfg = f.read()
        m = re.search(r"""base\s*:\s*['"]([^'"]+)['"]""", cfg)
        if not m:
            warnings.append("vite config has no `base` — set base: './' for itch.io / GitHub Pages subpaths")
        elif m.group(1) in ("/", ""):
            warnings.append(f"vite `base` is {m.group(1)!r} (absolute) — use './' for subpath deploys")

    for hit in scan_absolute_assets(proj):
        warnings.append(f"root-absolute asset path (breaks subpath deploy): {hit}")

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
