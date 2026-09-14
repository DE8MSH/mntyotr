#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

REGION="${1:-${REGION:-pal}}"
case "$REGION" in
  pal|ntsc) ;;
  *) echo "usage: ./build.sh [pal|ntsc]" >&2; exit 2 ;;
esac

python3 tools/check_isolation.py --working-tree
make clean
make REGION="$REGION" all
printf '\nBuilt: %s/build/monty.sfc (%s)\n' "$ROOT" "$REGION"
ls -lh build/monty.sfc
