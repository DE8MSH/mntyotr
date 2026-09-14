#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

if [ -r /etc/os-release ]; then
  . /etc/os-release
  printf 'Detected: %s %s\n' "${PRETTY_NAME:-Linux}" "${VERSION_ID:-}"
fi

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  SUDO=()
elif command -v sudo >/dev/null 2>&1; then
  SUDO=(sudo)
else
  echo "ERROR: sudo is required to install packages (or run this script as root)." >&2
  exit 1
fi

"${SUDO[@]}" apt-get update
"${SUDO[@]}" apt-get install -y cc65 make python3 git

for tool in ca65 ld65 python3 make git; do
  command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: $tool missing after install" >&2; exit 1; }
done

printf '\nToolchain:\n'
ca65 --version || true
ld65 --version || true
python3 --version

printf '\nRunning PAL build smoke test...\n'
cd "$ROOT"
./build.sh pal

printf '\nSNES toolchain ready. Use ./build.sh pal or ./build.sh ntsc.\n'
