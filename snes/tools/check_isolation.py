#!/usr/bin/env python3
"""Reject SNES branch history that changes anything outside snes/.

The comparison is against the merge base with the configurable PCE upstream
(default: main), so normal merges from PCE into the long-lived SNES branch do
not count as SNES-owned changes.
"""
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def git(*args: str) -> str:
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True).strip()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="main", help="canonical PCE branch (default: main)")
    ap.add_argument("--working-tree", action="store_true", help="also reject local edits outside snes/")
    args = ap.parse_args()

    merge_base = git("merge-base", args.base, "HEAD")
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
        print("SNES ISOLATION VIOLATION: changes outside snes/:")
        for path in sorted(set(bad)):
            print(f"  {path}")
        raise SystemExit(1)

    print(f"SNES isolation OK: {len(changed)} committed changed file(s), all below snes/")


if __name__ == "__main__":
    main()
