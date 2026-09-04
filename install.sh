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

# Build HuC. Current upstream mkit/as copies pceas to src/bin; older trees may
# place it in bin. The aggregate build can fail later in unrelated examples,
# so locate the executable that was actually produced instead of assuming one
# fixed layout.
make -C "$HUC_DIR/src" -j"$(nproc)" || true
PCEAS=""
for candidate in \
  "$HUC_DIR/src/bin/pceas" \
  "$HUC_DIR/bin/pceas" \
  "$HUC_DIR/src/mkit/as/pceas"; do
  if [ -x "$candidate" ]; then
    PCEAS="$candidate"
    break
  fi
done
if [ -z "$PCEAS" ]; then
  PCEAS="$(find "$HUC_DIR" -type f -name pceas -perm -u+x -print -quit 2>/dev/null || true)"
fi
if [ -z "$PCEAS" ] || [ ! -x "$PCEAS" ]; then
  echo "ERROR: pceas was not produced by the HuC build" >&2
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
echo "pceas source: $PCEAS"
echo "pceas command: ${HOME}/.local/bin/pceas"
"${HOME}/.local/bin/pceas" -? >/dev/null 2>&1 || true
echo "HuC home: $HUC_DIR"
echo "Build with: ./build.sh"
