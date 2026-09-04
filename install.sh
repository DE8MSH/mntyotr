#!/usr/bin/env bash
set -euo pipefail

TOOLS="${HOME}/.local/opt"
HUC_DIR="${TOOLS}/huc"

echo "== Monty PCE toolchain setup (Linux Mint 22) =="
sudo apt-get update
sudo apt-get install -y build-essential git cmake make python3 python3-pip pkg-config libsdl2-dev
mkdir -p "$TOOLS" "${HOME}/.local/bin"

if [ ! -d "$HUC_DIR/.git" ]; then
  git clone https://github.com/pce-devel/huc.git "$HUC_DIR"
else
  git -C "$HUC_DIR" remote set-url origin https://github.com/pce-devel/huc.git
  git -C "$HUC_DIR" pull --ff-only
fi

# The upstream aggregate build can fail in unrelated examples after pceas is
# already complete. Build host tools, then gate on the executable we need.
make -C "$HUC_DIR/src" -j"$(nproc)" || true
PCEAS="$HUC_DIR/bin/pceas"
if [ ! -x "$PCEAS" ]; then
  echo "ERROR: expected pceas at $PCEAS" >&2
  exit 1
fi
ln -sf "$PCEAS" "${HOME}/.local/bin/pceas"

cat > "${HOME}/.local/bin/motr-env" <<EOF
export HUC_HOME="$HUC_DIR"
export PCE_INCLUDE="$HUC_DIR/examples/asm/elmer/include:$HUC_DIR/include/hucc"
export PATH="${HOME}/.local/bin:\$PATH"
EOF
chmod +x "${HOME}/.local/bin/motr-env"

echo
echo "pceas: ${HOME}/.local/bin/pceas"
echo "HuC home: $HUC_DIR"
echo "Build with: ./build.sh"
