#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TOOLS="${HOME}/.local/opt"
HUC_DIR="${TOOLS}/huc"

echo "== Monty PCE toolchain setup (Linux Mint 22) =="
sudo apt-get update
sudo apt-get install -y build-essential git cmake make python3 python3-pip pkg-config libsdl2-dev
mkdir -p "$TOOLS" "${HOME}/.local/bin"

if [ ! -d "$HUC_DIR/.git" ]; then
  git clone https://github.com/uli/huc.git "$HUC_DIR"
else
  git -C "$HUC_DIR" pull --ff-only
fi

# HuC ships pceas; build using the upstream Unix makefiles.
make -C "$HUC_DIR" clean || true
make -C "$HUC_DIR" -j"$(nproc)"

PCEAS="$(find "$HUC_DIR" -type f -name pceas -perm -111 | head -n1 || true)"
if [ -z "$PCEAS" ]; then
  echo "ERROR: HuC built, but pceas was not found." >&2
  exit 1
fi
ln -sf "$PCEAS" "${HOME}/.local/bin/pceas"

echo
echo "pceas: ${HOME}/.local/bin/pceas"
echo "Ensure ~/.local/bin is in PATH, then run: ./build.sh"
