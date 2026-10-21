#!/usr/bin/env bash
# Install CaeClock alongside Caelestia shell and start it on login.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
qsdir="$cfg/quickshell/caeclock"
confdir="$cfg/caeclock"
hypruser="$cfg/caelestia/hypr-user.conf"
autostart='exec-once = qs -c caeclock -n -d'

mkdir -p "$qsdir" "$confdir"
install -m644 "$here/shell.qml" "$qsdir/shell.qml"

# Keep an existing config on reinstall
[[ -f "$confdir/config.json" ]] || install -m644 "$here/config.json" "$confdir/config.json"

# Autostart through Caelestia's user Hyprland overrides
if [[ -f "$cfg/caelestia/hypr-user.lua" && ! -f "$hypruser" ]]; then
    echo "Lua Hyprland config detected; add this to hypr-user.lua to autostart:"
    echo '  hl.exec_cmd("qs -c caeclock -n -d")'
else
    mkdir -p "$(dirname "$hypruser")"
    touch "$hypruser"
    if ! grep -qF "qs -c caeclock" "$hypruser"; then
        printf '\n# CaeClock desktop clock\n%s\n' "$autostart" >> "$hypruser"
    fi
fi

# (Re)start now
pkill -f "qs -c caeclock" 2>/dev/null || true
pkill -f "quickshell -c caeclock" 2>/dev/null || true
qs -c caeclock -n -d >/dev/null 2>&1 || true

echo "CaeClock installed."
echo "  Config:  $confdir/config.json (hot-reloads on save)"
echo "  Toggle:  qs -c caeclock ipc call caeclock toggle"
