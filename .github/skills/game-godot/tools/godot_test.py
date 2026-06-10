#!/usr/bin/env python3
"""Run a Godot 4 test suite headless and report pass/fail.

Supports GdUnit4 (default) and GUT. For GdUnit4 it auto-detects the shipped
runner wrapper (`addons/gdUnit4/runtest.sh` / `runtest.cmd`) and falls back to
the `GdUnitCmdTool.gd` entry point; the exact CLI has shifted across GdUnit4
versions, so `--runner-cmd` lets you override the invocation entirely.

Parses JUnit XML when a report directory is produced, otherwise relies on the
runner's exit code. Stdlib only.

Examples:
  python godot_test.py --runner gdunit4 --test-dir res://test
  python godot_test.py --runner gut --test-dir res://test --json
  python godot_test.py --runner-cmd "godot --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test --continue"
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import shlex
import subprocess
import sys
import xml.etree.ElementTree as ET


def detect_gdunit4_cmd(godot: str, project: str, test_dir: str, report_dir: str | None) -> list[str]:
    """Prefer the shipped wrapper; fall back to the CmdTool entry point."""
    is_windows = os.name == "nt"
    wrapper = os.path.join(project, "addons", "gdUnit4",
                           "runtest.cmd" if is_windows else "runtest.sh")
    if os.path.isfile(wrapper):
        cmd = [wrapper, "-a", test_dir, "--continue"]
        if report_dir:
            cmd += ["--rd", report_dir]
        return cmd
    # Fallback: direct CmdTool invocation.
    cmd = [godot, "--path", project, "--headless", "-s",
           "res://addons/gdUnit4/bin/GdUnitCmdTool.gd", "-a", test_dir, "--continue"]
    if report_dir:
        cmd += ["--rd", report_dir]
    return cmd


def detect_gut_cmd(godot: str, project: str, test_dir: str) -> list[str]:
    return [godot, "--path", project, "--headless", "-s",
            "res://addons/gut/gut_cmdln.gd", f"-gdir={test_dir}", "-ginclude_subdirs", "-gexit"]


def parse_junit(report_dir: str) -> dict | None:
    """Aggregate testcase/failure counts from any JUnit XML under report_dir."""
    files = glob.glob(os.path.join(report_dir, "**", "*.xml"), recursive=True)
    if not files:
        return None
    tests = failures = errors = skipped = 0
    for f in files:
        try:
            root = ET.parse(f).getroot()
        except ET.ParseError:
            continue
        suites = [root] if root.tag == "testsuite" else root.iter("testsuite")
        for suite in suites:
            tests += int(suite.get("tests", 0))
            failures += int(suite.get("failures", 0))
            errors += int(suite.get("errors", 0))
            skipped += int(suite.get("skipped", 0))
    if tests == 0:
        return None
    return {"tests": tests, "failures": failures, "errors": errors, "skipped": skipped}


def main() -> int:
    p = argparse.ArgumentParser(description="Run a Godot test suite headless.")
    p.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"),
                   help="Path to the Godot binary (default: $GODOT_BIN or 'godot').")
    p.add_argument("--project", default=".", help="Project directory (default: .).")
    p.add_argument("--runner", choices=["gdunit4", "gut"], default="gdunit4",
                   help="Test framework (default: gdunit4).")
    p.add_argument("--test-dir", default="res://test", help="Test directory (default: res://test).")
    p.add_argument("--report-dir", help="Directory for JUnit XML reports (GdUnit4).")
    p.add_argument("--runner-cmd", help="Full command override (bypasses auto-detection).")
    p.add_argument("--timeout", type=float, default=600.0, help="Kill after N seconds (default: 600).")
    p.add_argument("--json", action="store_true", help="Emit a JSON result.")
    args = p.parse_args()

    if args.runner_cmd:
        cmd = shlex.split(args.runner_cmd)
    elif args.runner == "gdunit4":
        cmd = detect_gdunit4_cmd(args.godot, args.project, args.test_dir, args.report_dir)
    else:
        cmd = detect_gut_cmd(args.godot, args.project, args.test_dir)

    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=args.timeout)
    except FileNotFoundError:
        _emit({"ok": False, "reason": f"Command not found: {cmd[0]!r}. Is Godot installed / the runner present?"},
              args.json)
        return 2
    except subprocess.TimeoutExpired:
        _emit({"ok": False, "reason": f"Test run timed out after {args.timeout}s.", "command": " ".join(cmd)},
              args.json)
        return 1

    output = (proc.stdout or "") + (proc.stderr or "")
    summary = parse_junit(args.report_dir) if args.report_dir else None

    if summary is not None:
        ok = summary["failures"] == 0 and summary["errors"] == 0
        reason = (f"{summary['tests']} tests, {summary['failures']} failures, "
                  f"{summary['errors']} errors, {summary['skipped']} skipped.")
    else:
        ok = proc.returncode == 0
        reason = "Runner exit code 0." if ok else f"Runner exit code {proc.returncode}."

    result = {
        "ok": ok,
        "reason": reason,
        "runner": args.runner,
        "command": " ".join(cmd),
        "exit_code": proc.returncode,
        "summary": summary,
        "report_dir": args.report_dir,
    }
    _emit(result, args.json, tail=output)
    return 0 if ok else 1


def _emit(result: dict, as_json: bool, tail: str = "") -> None:
    if as_json:
        print(json.dumps(result, indent=2))
        return
    status = "PASS" if result.get("ok") else "FAIL"
    print(f"[{status}] {result.get('reason', '')}")
    if "command" in result:
        print(f"  command: {result['command']}")
    if result.get("summary"):
        s = result["summary"]
        print(f"  tests  : {s['tests']} (fail {s['failures']}, err {s['errors']}, skip {s['skipped']})")
    if not result.get("ok") and tail:
        print("  --- last output lines ---")
        for line in tail.splitlines()[-20:]:
            print(f"  {line}")


if __name__ == "__main__":
    sys.exit(main())
