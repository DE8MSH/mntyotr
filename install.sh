#!/usr/bin/env bash
set -euo pipefail

TOOLS="${HOME}/.local/opt"
HUC_DIR="${TOOLS}/huc"

echo "== Monty PCE toolchain setup (Linux Mint 22) =="
sudo apt-get update
sudo apt-get install -y build-essential git cmake make python3 python3-pip pkg-config libsdl2-dev
mkdir -p "$TOOLS" "${HOME}/.local/bin"

# Use the current pce-devel HuC tree because the port uses its CORE(not TM)
# startup/VDC/font/joypad assembly libraries.
if [ ! -d "$HUC_DIR/.git" ]; then
  git clone https://github.com/pce-devel/huc.git "$HUC_DIR"
else
  git -C "$HUC_DIR" remote set-url origin https://github.com/pce-devel/huc.git
  git -C "$HUC_DIR" pull --ff-only
fi

make -C "$HUC_DIR" clean || true
make -C "$HUC_DIR" -j"$(nproc)"

PCEAS="$HUC_DIR/bin/pceas"
if [ ! -x "$PCEAS" ]; then
  echo "ERROR: expected pceas at $PCEAS" >&2
  exit 1
fi
ln -sf "$PCEAS" "${HOME}/.local/bin/pceas"

echo
echo "pceas: ${HOME}/.local/bin/pceas"
echo "HuC home: $HUC_DIR"
echo "Ensure ~/.local/bin is in PATH, then run: ./build.sh"
