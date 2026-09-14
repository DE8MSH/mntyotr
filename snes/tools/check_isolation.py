#!/usr/bin/env python3
"""Reject SNES branch history that changes anything outside snes/.

The comparison is against the merge base with the configurable PCE upstream.
By default origin/main is preferred when available, falling back to local main.
Normal merges from PCE into the long-lived SNES branch therefore do not count
as SNES-owned changes.
"""
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def git(*args: str) -> str:
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True).strip()


def ref_exists(ref: str) -> bool:
    return subprocess.call(
        ["git", "-C", str(ROOT), "rev-parse", "--verify", "--quiet", ref],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    ) == 0


def default_base() -> str:
    return "origin/main" if ref_exists("origin/main") else "main"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", help="canonical PCE ref (default: origin/main, else main)")
    ap.add_argument("--working-tree", action="store_true", help="also reject local edits outside snes/")
    args = ap.parse_args()

    base = args.base or default_base()
    merge_base = git("merge-base", base, "HEAD")
    changed = [p for p in git("diff", "--name-only", f"{merge_base}..HEAD").splitlines() if p]
    bad = [p for p in changed if not p.startswith("snes/")]

    if args.working_tree:
        status = git("status", "--porcelain")
        for line in status.splitlines():
            path = line[3:]
            if " -> " in path:
                path = path.split(" -> ", 1)[1]
            if path and not path.startswith("snes/"):
                bad.append(path)

    if bad:
        print(f"SNES ISOLATION VIOLATION against {base}: changes outside snes/:")
        for path in sorted(set(bad)):
            print(f"  {path}")
        raise SystemExit(1)

    print(f"SNES isolation OK vs {base}: {len(changed)} committed changed file(s), all below snes/")


if __name__ == "__main__":
    main()
