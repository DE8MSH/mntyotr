#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PCE_BRANCH="${PCE_BRANCH:-main}"
SNES_BRANCH="${SNES_BRANCH:-snes/parallel-port}"

cd "$ROOT"
current="$(git branch --show-current)"
if [ "$current" != "$SNES_BRANCH" ]; then
  echo "ERROR: switch to $SNES_BRANCH before syncing (currently $current)." >&2
  exit 1
fi

git fetch origin "$PCE_BRANCH"
git merge --no-edit "origin/$PCE_BRANCH"
python3 snes/tools/check_isolation.py --base "origin/$PCE_BRANCH" --working-tree

echo "SNES branch now follows origin/$PCE_BRANCH; adapt new behaviour only below snes/."
