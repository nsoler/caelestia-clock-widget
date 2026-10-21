//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1

// CaeClock: a minimal desktop clock for Caelestia, modelled on OmaClock.
// Renders on the Wayland bottom layer (behind every window, above the
// wallpaper), is click-through, and follows the active Caelestia colour
// scheme. Settings live in ~/.config/caeclock/config.json and hot-reload.

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/caeclock"
    readonly property string configPath: configDir + "/config.json"
    readonly property string schemePath: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/caelestia/scheme.json"

    readonly property var defaults: ({
        enabled: true,
        format: "h:mm",          // Qt time format: h:mm, h:mm:ss, HH:mm, HH:mm:ss
        showSeconds: false,
        showDate: true,
        dateFormat: "dddd, MMMM d",
        fontFamily: "Rubik",     // "" = system default
        fontWeight: 300,
        fontScale: 0.15,         // fraction of screen height
        dateScale: 0.22,         // date size relative to the time
        letterSpacing: -3,
        colorMode: "scheme",     // scheme | custom
        colorRole: "onSurface",  // any key from Caelestia's scheme.json colours
        color: "",               // hex for custom mode
        opacity: 0.92,
        shadow: true,
        xRatio: 0.5,
        yRatio: 0.2,
        screens: []              // [] = all monitors, or e.g. ["eDP-1"]
    })

    property var settings: defaults
    property var scheme: ({})

    function merge(base, over) {
        const out = {};
        for (const k in base) out[k] = base[k];
        for (const k in over) if (Object.prototype.hasOwnProperty.call(over, k)) out[k] = over[k];
        return out;
    }

    function num(v, fallback) {
        if (v === null || v === undefined || v === "") return fallback;
        const n = Number(v);
        return isNaN(n) ? fallback : n;
    }

    function set(key, value) {
        const next = merge(settings, {});
        next[key] = value;
        settings = next;
        cfgFile.setText(JSON.stringify(settings, null, 2) + "\n");
    }

    // Qt only gives 1-12 hours when an AP token is present, so render with AP
    // and strip the suffix for 12-hour formats that don't ask for AM/PM.
    function timeString(date, fmt) {
        if (/h/.test(fmt) && !/H/.test(fmt) && !/AP/i.test(fmt))
            return Qt.formatDateTime(date, fmt + " AP").replace(/\s*(AM|PM)$/i, "").trim();
        return Qt.formatDateTime(date, fmt);
    }

    readonly property color activeColor: {
        const s = settings;
        if (s.colorMode === "custom" && s.color) return Qt.color(s.color);
        const hex = scheme[s.colorRole] || scheme.onSurface;
        return hex ? Qt.color("#" + hex) : "#e6e1e5";
    }

    readonly property color shadowColor: {
        const hex = scheme.shadow || scheme.surface;
        return hex ? Qt.color("#" + hex) : "#000000";
    }

    FileView {
        id: cfgFile
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.settings = root.merge(root.defaults, JSON.parse(text()));
            } catch (e) {
                console.warn("caeclock: invalid config.json, using defaults:", e);
            }
        }
        onLoadFailed: root.settings = root.defaults
    }

    FileView {
        path: root.schemePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.scheme = JSON.parse(text()).colours || {};
            } catch (e) {
                console.warn("caeclock: could not parse Caelestia scheme:", e);
            }
        }
    }

    SystemClock {
        id: clock
        precision: root.settings.showSeconds || /s/.test(root.settings.format) ? SystemClock.Seconds : SystemClock.Minutes
    }

    // caelestia-style control: qs -c caeclock ipc call caeclock <fn> [args]
    IpcHandler {
        target: "caeclock"

        function toggle(): void { root.set("enabled", !root.settings.enabled); }
        function show(): void { root.set("enabled", true); }
        function hide(): void { root.set("enabled", false); }
        function format(fmt: string): void { root.set("format", fmt); }
        function scale(value: real): void { root.set("fontScale", value); }
        function move(x: real, y: real): void {
            root.set("xRatio", x);
            root.set("yRatio", y);
        }
        function colour(role: string): void {
            if (role.startsWith("#")) {
                root.set("color", role);
                root.set("colorMode", "custom");
            } else {
                root.set("colorRole", role);
                root.set("colorMode", "scheme");
            }
        }
        function reset(): void {
            root.settings = root.defaults;
            cfgFile.setText(JSON.stringify(root.defaults, null, 2) + "\n");
        }
    }

    Variants {
        model: Quickshell.screens.filter(s => {
            const list = root.settings.screens;
            return !list || list.length === 0 || list.indexOf(s.name) !== -1;
        })

        PanelWindow {
            id: win
            required property ShellScreen modelData

            screen: modelData
            visible: root.settings.enabled !== false
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}  // fully click-through

            WlrLayershell.namespace: "caeclock"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Item {
                id: surface
                anchors.fill: parent

                Column {
                    id: content
                    spacing: timeText.font.pixelSize * 0.02
                    opacity: Math.min(1, Math.max(0, root.num(root.settings.opacity, 0.92)))
                    x: surface.width * root.num(root.settings.xRatio, 0.5) - width / 2
                    y: surface.height * root.num(root.settings.yRatio, 0.2) - height / 2

                    layer.enabled: root.settings.shadow !== false
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: root.shadowColor
                        shadowOpacity: 0.6
                        shadowBlur: 0.5
                        shadowVerticalOffset: 2
                    }

                    Text {
                        id: timeText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.timeString(clock.date, root.settings.format)
                        color: root.activeColor
                        font.family: root.settings.fontFamily
                        font.weight: root.settings.fontWeight
                        font.pixelSize: Math.max(8, Math.round(surface.height * root.num(root.settings.fontScale, 0.15)))
                        font.letterSpacing: root.settings.letterSpacing
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.settings.showDate !== false
                        text: Qt.formatDateTime(clock.date, root.settings.dateFormat)
                        color: root.activeColor
                        font.family: root.settings.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: Math.max(8, Math.round(timeText.font.pixelSize * root.num(root.settings.dateScale, 0.22)))
                        font.letterSpacing: 1
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }
            }
        }
    }
}
