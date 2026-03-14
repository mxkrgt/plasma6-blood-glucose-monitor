import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcm

SimpleKCM {
    property alias cfg_serverUrl: serverUrlField.text
    property alias cfg_unit: unitCombo.currentText
    property alias cfg_lowThreshold: lowThresholdField.value
    property alias cfg_highThreshold: highThresholdField.value
    property alias cfg_refreshInterval: refreshIntervalField.value

    Kirigami.FormLayout {
        Controls.TextField {
            id: serverUrlField
            Kirigami.FormData.label: "Server URL (e.g. Tailscale IP):"
            placeholderText: "http://100.x.y.z:17580"
        }
        Controls.ComboBox {
            id: unitCombo
            Kirigami.FormData.label: "Unit:"
            model: ["mg/dL", "mmol/L"]
        }
        Controls.SpinBox {
            id: lowThresholdField
            Kirigami.FormData.label: "Low Threshold:"
            from: 20
            to: 400
            stepSize: 1
        }
        Controls.SpinBox {
            id: highThresholdField
            Kirigami.FormData.label: "High Threshold:"
            from: 20
            to: 400
            stepSize: 1
        }
        Controls.SpinBox {
            id: refreshIntervalField
            Kirigami.FormData.label: "Refresh Interval (ms):"
            from: 10000
            to: 3600000
            stepSize: 1000
        }
    }
}
