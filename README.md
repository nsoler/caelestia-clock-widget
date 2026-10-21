# CaeClock

A minimal desktop clock for [Caelestia shell](https://github.com/caelestia-dots/shell), modelled on
[OmaClock](https://github.com/ubeyidah/omaclock) for Omarchy.

- Sits on the bottom layer: behind every window, above the wallpaper.
- Click-through, so desktop interactions keep working.
- Follows your Caelestia colour scheme live (`~/.local/state/caelestia/scheme.json`).
- One `config.json`, hot-reloaded the moment you save it.
- IPC commands for toggling, moving, resizing and recolouring.

Caelestia doesn't have a working plugin loader yet, so CaeClock runs as its own small Quickshell
config next to the shell (`qs -c caeclock`). When plugin support lands it can be ported over.

## Install

```sh
tar xzf caeclock.tar.gz
cd caeclock
./install.sh
```

This copies the clock to `~/.config/quickshell/caeclock/`, creates `~/.config/caeclock/config.json`,
adds an `exec-once` line to `~/.config/caelestia/hypr-user.conf`, and starts it.

## Control

```sh
qs -c caeclock ipc call caeclock toggle
qs -c caeclock ipc call caeclock show
qs -c caeclock ipc call caeclock hide
qs -c caeclock ipc call caeclock format "HH:mm"
qs -c caeclock ipc call caeclock scale 0.22
qs -c caeclock ipc call caeclock move 0.5 0.8
qs -c caeclock ipc call caeclock colour primary      # any scheme role
qs -c caeclock ipc call caeclock colour "#ffcc00"     # custom hex
qs -c caeclock ipc call caeclock reset
```

Tip: bind toggle to a key in `hypr-user.conf`:

```
bind = SUPER ALT, C, exec, qs -c caeclock ipc call caeclock toggle
```

## Options (`~/.config/caeclock/config.json`)

| Key             | Default          | Description                                                       |
|-----------------|------------------|-------------------------------------------------------------------|
| `enabled`       | `true`           | Show the clock.                                                   |
| `format`        | `h:mm`           | Qt time format. `h:mm` 12h, `HH:mm` 24h, add `:ss` for seconds.   |
| `showSeconds`   | `false`          | Tick every second (automatic if `format` contains `s`).           |
| `showDate`      | `true`           | Show a date line under the time.                                  |
| `dateFormat`    | `dddd, MMMM d`   | Qt date format for the date line.                                 |
| `fontFamily`    | `Rubik`          | Any installed font. `""` = system default.                        |
| `fontWeight`    | `300`            | 100–900.                                                          |
| `fontScale`     | `0.15`           | Time size as a fraction of screen height.                         |
| `dateScale`     | `0.22`           | Date size relative to the time.                                   |
| `letterSpacing` | `-3`             | Spacing between numerals (negative tightens).                     |
| `colorMode`     | `scheme`         | `scheme` (follow Caelestia) or `custom`.                          |
| `colorRole`     | `onSurface`      | Scheme role, e.g. `primary`, `secondary`, `tertiary`, `onSurface`.|
| `color`         | `""`             | Hex colour when `colorMode` is `custom`.                          |
| `opacity`       | `0.92`           | 0–1.                                                              |
| `shadow`        | `true`           | Soft drop shadow for legibility on bright wallpapers.             |
| `xRatio`        | `0.5`            | Horizontal centre, 0 (left) to 1 (right).                         |
| `yRatio`        | `0.2`            | Vertical centre, 0 (top) to 1 (bottom).                           |
| `screens`       | `[]`             | Limit to monitors, e.g. `["eDP-1"]`. Empty = all.                 |

## Troubleshooting

Run it attached to see errors: `pkill -f "qs -c caeclock"; qs -c caeclock -n`

## Uninstall

```sh
./uninstall.sh          # keeps your config
./uninstall.sh --purge  # also deletes ~/.config/caeclock
```

## License

MIT
