#!/usr/bin/env bash
# Remove CaeClock. Your config in ~/.config/caeclock is kept unless you pass --purge.
set -euo pipefail

cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
hypruser="$cfg/caelestia/hypr-user.conf"

pkill -f "qs -c caeclock" 2>/dev/null || true
pkill -f "quickshell -c caeclock" 2>/dev/null || true

rm -rf "$cfg/quickshell/caeclock"

if [[ -f "$hypruser" ]]; then
    sed -i '/# CaeClock desktop clock/d; /qs -c caeclock/d' "$hypruser"
fi

if [[ "${1:-}" == "--purge" ]]; then
    rm -rf "$cfg/caeclock"
fi

echo "CaeClock removed."
