#!/usr/bin/env python3
"""Launch a Godot 4 project and report a reliable pass/fail result.

Godot's process exit code is unreliable: it can return 0 while logging
SCRIPT ERROR / missing-resource / parse errors to stderr. This wrapper runs the
engine (headless or windowed, optionally a specific scene), captures output,
scans it for error signatures, enforces a timeout, and emits a structured
result. Stdlib only.

Examples:
  python godot_run.py --import
  python godot_run.py --scene scenes/main.tscn
  python godot_run.py --headless --quit-after 120 --json
  python godot_run.py --headless --expect "Game ready" --timeout 20
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time

# Lines matching these patterns indicate a failure even if the exit code is 0.
ERROR_PATTERNS = [
    re.compile(r"\bSCRIPT ERROR\b", re.IGNORECASE),
    re.compile(r"\bParse Error\b", re.IGNORECASE),
    re.compile(r"Resource file not found", re.IGNORECASE),
    re.compile(r"\bERROR:\b.*(failed to load|can't open|cannot open)", re.IGNORECASE),
    re.compile(r"Cyclic resource inclusion", re.IGNORECASE),
    re.compile(r"Condition .* is true\. (Returning|Continuing)", re.IGNORECASE),
    re.compile(r"Failed to (load|instantiate)", re.IGNORECASE),
    re.compile(r"Attempt to call function .* on a null instance", re.IGNORECASE),
]


def build_command(args: argparse.Namespace) -> list[str]:
    cmd = [args.godot, "--path", args.project]
    if args.import_only:
        cmd.append("--import")
        return cmd
    if args.headless:
        cmd.append("--headless")
    if args.quit_after is not None:
        cmd += ["--quit-after", str(args.quit_after)]
    if args.scene:
        cmd.append(args.scene)
    if args.extra:
        cmd += args.extra
    return cmd


def scan_errors(output: str) -> list[str]:
    hits: list[str] = []
    for line in output.splitlines():
        for pat in ERROR_PATTERNS:
            if pat.search(line):
                hits.append(line.strip())
                break
    return hits


def main() -> int:
    p = argparse.ArgumentParser(description="Launch a Godot project with a reliable smoke check.")
    p.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"),
                   help="Path to the Godot binary (default: $GODOT_BIN or 'godot').")
    p.add_argument("--project", default=".", help="Project directory containing project.godot (default: .).")
    p.add_argument("--scene", help="Scene to run, e.g. scenes/main.tscn (relative to project).")
    p.add_argument("--headless", action="store_true", help="Run without a window (required in CI).")
    p.add_argument("--import", dest="import_only", action="store_true",
                   help="Only (re)import resources, then exit.")
    p.add_argument("--quit-after", type=int, help="Quit after N rendered frames (smoke runs).")
    p.add_argument("--timeout", type=float, default=30.0, help="Kill the process after N seconds (default: 30).")
    p.add_argument("--expect", help="Substring that must appear in output for success (optional).")
    p.add_argument("--json", action="store_true", help="Emit a JSON result instead of text.")
    p.add_argument("extra", nargs=argparse.REMAINDER,
                   help="Extra args passed through to Godot (prefix with --).")
    args = p.parse_args()

    cmd = build_command(args)
    start = time.monotonic()
    timed_out = False
    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, timeout=args.timeout,
        )
        exit_code = proc.returncode
        output = (proc.stdout or "") + (proc.stderr or "")
    except subprocess.TimeoutExpired as e:
        timed_out = True
        exit_code = None
        output = ((e.stdout or "") if isinstance(e.stdout, str) else "") + \
                 ((e.stderr or "") if isinstance(e.stderr, str) else "")
        # A timeout is expected for windowed/long runs but a failure for smoke runs
        # that were supposed to --quit-after a frame budget.
    except FileNotFoundError:
        result = {
            "ok": False,
            "reason": f"Godot binary not found: {args.godot!r}. "
                      f"Install Godot or set --godot / $GODOT_BIN.",
        }
        _emit(result, args.json)
        return 2

    duration = round(time.monotonic() - start, 2)
    errors = scan_errors(output)

    expect_ok = True
    if args.expect is not None:
        expect_ok = args.expect in output

    # Decide pass/fail.
    smoke_run = args.import_only or args.quit_after is not None or args.headless
    if timed_out and smoke_run:
        ok = False
        reason = f"Timed out after {args.timeout}s (smoke run expected a clean exit)."
    elif timed_out:
        ok = len(errors) == 0  # windowed run we deliberately stopped; only errors fail it
        reason = "Stopped by timeout (expected for a windowed run)." if ok \
            else "Errors detected before timeout."
    elif errors:
        ok = False
        reason = f"{len(errors)} error line(s) in output."
    elif not expect_ok:
        ok = False
        reason = f"Expected substring not found: {args.expect!r}."
    elif exit_code not in (0, None):
        ok = False
        reason = f"Non-zero exit code: {exit_code}."
    else:
        ok = True
        reason = "Clean run."

    result = {
        "ok": ok,
        "reason": reason,
        "command": " ".join(cmd),
        "exit_code": exit_code,
        "timed_out": timed_out,
        "duration_s": duration,
        "errors": errors[:50],
        "error_count": len(errors),
    }
    _emit(result, args.json)
    return 0 if ok else 1


def _emit(result: dict, as_json: bool) -> None:
    if as_json:
        print(json.dumps(result, indent=2))
        return
    status = "PASS" if result.get("ok") else "FAIL"
    print(f"[{status}] {result.get('reason', '')}")
    if "command" in result:
        print(f"  command : {result['command']}")
    if result.get("exit_code") is not None:
        print(f"  exit    : {result['exit_code']}")
    if "duration_s" in result:
        print(f"  duration: {result['duration_s']}s")
    if result.get("errors"):
        print(f"  errors  : {result['error_count']}")
        for line in result["errors"][:10]:
            print(f"    - {line}")
        if result["error_count"] > 10:
            print(f"    ... and {result['error_count'] - 10} more")


if __name__ == "__main__":
    sys.exit(main())
