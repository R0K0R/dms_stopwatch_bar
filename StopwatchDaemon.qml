import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Modules.Plugins

/*
  The one copy of the stopwatch. Bar widgets are instantiated per bar per
  screen (and this config swaps between two bars on rotation), so the state
  lives here and every widget reads it through
  PluginService.pluginDaemonInstances -- all pills show the same time.

  Time is kept as timestamps, not a ticking counter: `banked` is what earlier
  runs added up to, `startedAt` is when the current run began. Nothing has to
  tick for the time to stay right; widgets only refresh their label.
*/
PluginComponent {
    id: root

    property string mode: "idle" // idle | running | paused
    property real startedAt: 0
    property real banked: 0

    function elapsed(now) {
        return banked + (mode === "running" ? now - startedAt : 0);
    }

    function start() {
        banked = 0;
        startedAt = Date.now();
        mode = "running";
    }

    function pause() {
        if (mode !== "running")
            return;
        banked = elapsed(Date.now());
        mode = "paused";
    }

    function resume() {
        if (mode !== "paused")
            return;
        startedAt = Date.now();
        mode = "running";
    }

    function reset() {
        banked = 0;
        startedAt = 0;
        mode = "idle";
    }

    // Same step the bar click takes, minus the popup: paused -> resume.
    function toggle() {
        if (mode === "idle")
            start();
        else if (mode === "running")
            pause();
        else
            resume();
    }

    function format(ms) {
        const s = Math.floor(ms / 1000);
        const h = Math.floor(s / 3600);
        const m = Math.floor(s / 60) % 60;
        const ss = String(s % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${ss}` : `${m}:${ss}`;
    }

    IpcHandler {
        target: "stopwatch"

        function toggle(): string {
            root.toggle();
            return root.mode;
        }
        function pause(): string {
            root.pause();
            return root.mode;
        }
        function resume(): string {
            root.resume();
            return root.mode;
        }
        function reset(): string {
            root.reset();
            return root.mode;
        }
        function status(): string {
            return `${root.mode} ${root.format(root.elapsed(Date.now()))}`;
        }
    }
}
