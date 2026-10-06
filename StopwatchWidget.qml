import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

/*
  The bar surface. Holds no state; everything is the daemon's
  (StopwatchDaemon.qml).

    idle    -> timer icon;        click starts
    running -> elapsed time;      click pauses
    paused  -> time, dimmed;      click opens the Resume / Reset popup

  The popup is the plugin popout. A click with a pillClickAction never reaches
  it, so the action is withdrawn while paused and the click falls through to
  PluginComponent's default: toggle the popout, positioned under the pill.
*/
PluginComponent {
    id: root

    layerNamespacePlugin: "stopwatch"

    readonly property var daemon: PluginService.pluginDaemonInstances[pluginId] || null
    readonly property string mode: daemon ? daemon.mode : "idle"

    // Refreshed by the timer; the daemon's timestamps carry the real time.
    property real now: Date.now()
    readonly property string label: daemon ? daemon.format(daemon.elapsed(now)) : ""

    // Set by the popout content once it has been opened.
    property var _popout: null

    Timer {
        running: root.mode === "running"
        interval: 250
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    onModeChanged: {
        now = Date.now();
        if (mode !== "paused" && _popout && _popout.shouldBeVisible)
            closePopout();
    }

    pillClickAction: mode === "paused" ? null : () => root.daemon && root.daemon.toggle()

    component Pill: Item {
        implicitWidth: root.mode === "idle" ? root.iconSize : text.implicitWidth
        implicitHeight: root.iconSize

        DankIcon {
            anchors.centerIn: parent
            visible: root.mode === "idle"
            name: "timer"
            color: Theme.surfaceText
            size: root.iconSize
        }

        StyledText {
            id: text
            anchors.centerIn: parent
            visible: root.mode !== "idle"
            text: root.label
            font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
            font.features: ({ "tnum": 1 }) // fixed-width digits, so the pill does not jitter
            color: root.mode === "running" ? Theme.primary : Theme.surfaceVariantText
        }
    }

    horizontalBarPill: Component {
        Pill {}
    }

    verticalBarPill: Component {
        Pill {}
    }

    popoutWidth: 240

    popoutContent: Component {
        PopoutComponent {
            headerText: "Stopwatch"
            detailsText: `Paused at ${root.label}`

            onParentPopoutChanged: root._popout = parentPopout

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingS
                topPadding: Theme.spacingM

                DankButton {
                    text: "Resume"
                    iconName: "play_arrow"
                    onClicked: root.daemon && root.daemon.resume()
                }

                DankButton {
                    text: "Reset"
                    iconName: "restart_alt"
                    backgroundColor: Theme.surfaceContainerHigh
                    textColor: Theme.surfaceText
                    onClicked: root.daemon && root.daemon.reset()
                }
            }
        }
    }
}
