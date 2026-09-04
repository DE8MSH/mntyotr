#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
ROM="$ROOT/build/monty.pce"
[ -f "$ROM" ] || "$ROOT/build.sh"
if command -v mednafen >/dev/null 2>&1; then
  exec mednafen "$ROM"
elif command -v retroarch >/dev/null 2>&1; then
  echo "ROM ready: $ROM"
  echo "RetroArch detected; select a PC Engine core and open the ROM."
else
  echo "ROM ready: $ROM"
  echo "Install/configure a PC Engine emulator, or copy it to your flash cart."
fi
