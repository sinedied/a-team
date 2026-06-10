#!/usr/bin/env python3
"""Summarize a Godot performance CSV produced by the PerfLogger autoload.

Reads a CSV with a header row and numeric columns (e.g. frame, fps, frame_ms,
draw_calls, nodes, mem_static_mb). Computes min / median / p95 / max for each
numeric column, and raises frame-pacing flags based on FPS and frame-time
budgets. Stdlib only.

Examples:
  python perf_summarize.py perf.csv
  python perf_summarize.py perf.csv --target-fps 60 --frame-budget-ms 16.7 --json
"""
from __future__ import annotations

import argparse
import csv
import json
import statistics
import sys


def percentile(sorted_values: list[float], pct: float) -> float:
    """Nearest-rank percentile (pct in 0..100). Assumes sorted input."""
    if not sorted_values:
        return float("nan")
    if len(sorted_values) == 1:
        return sorted_values[0]
    rank = max(1, int(round(pct / 100.0 * len(sorted_values))))
    return sorted_values[min(rank, len(sorted_values)) - 1]


def load_columns(path: str) -> dict[str, list[float]]:
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames is None:
            raise ValueError("CSV has no header row.")
        cols: dict[str, list[float]] = {name: [] for name in reader.fieldnames}
        for row in reader:
            for name, raw in row.items():
                if raw is None or raw == "":
                    continue
                try:
                    cols[name].append(float(raw))
                except ValueError:
                    pass  # non-numeric column; skip
    # Drop columns that ended up empty (non-numeric).
    return {k: v for k, v in cols.items() if v}


def stats_for(values: list[float]) -> dict[str, float]:
    s = sorted(values)
    return {
        "samples": len(s),
        "min": round(s[0], 2),
        "median": round(statistics.median(s), 2),
        "p95": round(percentile(s, 95), 2),
        "max": round(s[-1], 2),
        "mean": round(statistics.fmean(s), 2),
        "stdev": round(statistics.pstdev(s), 2) if len(s) > 1 else 0.0,
    }


def main() -> int:
    p = argparse.ArgumentParser(description="Summarize a Godot perf CSV.")
    p.add_argument("csv", help="Path to the perf CSV (from PerfLogger).")
    p.add_argument("--target-fps", type=float, default=60.0, help="FPS target for flags (default: 60).")
    p.add_argument("--frame-budget-ms", type=float, default=16.7,
                   help="Per-frame budget in ms for flags (default: 16.7).")
    p.add_argument("--fps-col", default="fps", help="FPS column name (default: fps).")
    p.add_argument("--frame-ms-col", default="frame_ms", help="Frame-time column name (default: frame_ms).")
    p.add_argument("--json", action="store_true", help="Emit a JSON result.")
    args = p.parse_args()

    try:
        cols = load_columns(args.csv)
    except FileNotFoundError:
        _fail(f"CSV not found: {args.csv!r}", args.json)
        return 2
    except ValueError as e:
        _fail(str(e), args.json)
        return 2

    if not cols:
        _fail("No numeric columns found in CSV.", args.json)
        return 2

    summary = {name: stats_for(values) for name, values in cols.items()}

    # Frame-pacing flags.
    flags: list[str] = []
    fps = cols.get(args.fps_col)
    if fps:
        below = sum(1 for v in fps if v < args.target_fps)
        pct_below = round(100.0 * below / len(fps), 1)
        if pct_below > 5.0:
            flags.append(f"{pct_below}% of samples below {args.target_fps} FPS target")
        if summary[args.fps_col]["p95"] < args.target_fps:
            # p95 of FPS being low means the typical-bad case misses target
            flags.append(f"p95 FPS {summary[args.fps_col]['p95']} below {args.target_fps} target")
    frame_ms = cols.get(args.frame_ms_col)
    if frame_ms:
        over = sum(1 for v in frame_ms if v > args.frame_budget_ms)
        pct_over = round(100.0 * over / len(frame_ms), 1)
        if pct_over > 5.0:
            flags.append(f"{pct_over}% of frames over {args.frame_budget_ms}ms budget")
        if summary[args.frame_ms_col]["stdev"] > args.frame_budget_ms * 0.5:
            flags.append("high frame-time variance (spiky pacing)")

    result = {
        "ok": len(flags) == 0,
        "source": args.csv,
        "columns": summary,
        "flags": flags,
    }
    _emit(result, args.json)
    return 0 if result["ok"] else 1


def _fail(msg: str, as_json: bool) -> None:
    _emit({"ok": False, "error": msg}, as_json)


def _emit(result: dict, as_json: bool) -> None:
    if as_json:
        print(json.dumps(result, indent=2))
        return
    if result.get("error"):
        print(f"[ERROR] {result['error']}")
        return
    print(f"Perf summary: {result['source']}")
    cols = result["columns"]
    name_w = max((len(n) for n in cols), default=6)
    header = f"  {'column'.ljust(name_w)}  {'min':>8} {'median':>8} {'p95':>8} {'max':>8} {'stdev':>8}  samples"
    print(header)
    for name, s in cols.items():
        print(f"  {name.ljust(name_w)}  {s['min']:>8} {s['median']:>8} {s['p95']:>8} "
              f"{s['max']:>8} {s['stdev']:>8}  {s['samples']}")
    if result["flags"]:
        print("  flags:")
        for fl in result["flags"]:
            print(f"    ! {fl}")
    else:
        print("  no frame-pacing flags raised")


if __name__ == "__main__":
    sys.exit(main())
