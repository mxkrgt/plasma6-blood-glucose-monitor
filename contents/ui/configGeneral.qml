import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    property alias cfg_serverUrl: serverUrlField.text
    property alias cfg_apiSecretHash: apiSecretHashField.text
    property alias cfg_unit: unitCombo.currentText
    property alias cfg_lowThreshold: lowThresholdField.value
    property alias cfg_highThreshold: highThresholdField.value
    property alias cfg_refreshInterval: refreshIntervalField.value
    property alias cfg_soundEnabled: soundEnabledField.checked
    property alias cfg_soundVolume: soundVolumeField.value
    property alias cfg_soundInterval: soundIntervalField.value
    property alias cfg_snoozeDuration: snoozeDurationField.value

    Kirigami.FormLayout {
        Controls.TextField {
            id: serverUrlField
            Kirigami.FormData.label: "Nightscout URL:"
            placeholderText: "https://monsite.duckdns.org"
        }
        Controls.TextField {
            id: apiSecretHashField
            Kirigami.FormData.label: "API Secret (SHA1 hash):"
            placeholderText: "hash sha1 de votre API secret"
            echoMode: TextInput.Password
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
        Item {
            Kirigami.FormData.isSection: true
        }
        Controls.CheckBox {
            id: soundEnabledField
            Kirigami.FormData.label: "Activer les alarmes sonores:"
            text: "Oui"
        }
        Controls.SpinBox {
            id: soundVolumeField
            Kirigami.FormData.label: "Volume Sonore (%):"
            from: 0
            to: 200
            stepSize: 10
        }
        Controls.SpinBox {
            id: soundIntervalField
            Kirigami.FormData.label: "Répétition de l'alarme (min):"
            from: 1
            to: 60
            stepSize: 1
        }
        Controls.SpinBox {
            id: snoozeDurationField
            Kirigami.FormData.label: "Durée du Snooze (min):"
            from: 5
            to: 120
            stepSize: 5
        }
    }
}
