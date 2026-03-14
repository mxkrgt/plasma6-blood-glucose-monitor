import QtQuick
import QtMultimedia
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../code/logic.js" as Logic

PlasmoidItem {
    id: root

    property string sgvText: "---"
    property string trendArrow: ""
    property string deltaText: ""
    property int sgvValue: 0
    property string dataAge: ""
    property bool isStale: false
    property bool isError: false
    property bool tailscaleConnected: true
    property string lastError: ""
    property var historyData: []
    
    // Pour éviter les alertes répétitives sur la même mesure
    property double lastAlertTimestamp: 0

    property string serverUrl: plasmoid.configuration.serverUrl
    property string unit: plasmoid.configuration.unit
    property int lowThreshold: plasmoid.configuration.lowThreshold
    property int highThreshold: plasmoid.configuration.highThreshold
    property int refreshInterval: plasmoid.configuration.refreshInterval

    toolTipMainText: "Blood Glucose Monitor"
    toolTipSubText: lastError || (isError ? "Erreur de connexion" : "Connecté à " + serverUrl)

    Plasmoid.backgroundHints: Plasmoid.DefaultBackground
    preferredRepresentation: compactRepresentation

    compactRepresentation: CompactRepresentation {
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }
    
    fullRepresentation: FullRepresentation {}

    // Effet sonore pour les alertes
    SoundEffect {
        id: alertSound
        source: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
        volume: 1.0
    }

    Timer {
        id: refreshTimer
        interval: refreshInterval > 0 ? refreshInterval : 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateData()
    }

    function updateData() {
        checkTailscaleStatus(function(connected) {
            tailscaleConnected = connected;
            if (!connected) {
                isError = true;
                sgvText = "TS Off";
                return;
            }

            Logic.fetchGlucoseData(serverUrl, 36, function(data) {
                isError = false;
                var latest = data[0];
                sgvValue = latest.sgv;
                sgvText = Logic.convertSgv(sgvValue, unit);
                trendArrow = Logic.getTrendArrow(latest.direction);
                
                // --- Logique d'alerte ---
                var currentTimestamp = latest.date;
                if (currentTimestamp > lastAlertTimestamp) {
                    checkAlerts(latest);
                    lastAlertTimestamp = currentTimestamp;
                }
                // -----------------------

                if (data.length > 1) {
                    var delta = sgvValue - data[1].sgv;
                    deltaText = (delta > 0 ? "+" : "") + Logic.convertSgv(delta, unit);
                }
                
                var diffMins = Math.floor((new Date().getTime() - latest.date) / 60000);
                isStale = (diffMins > 15);
                dataAge = diffMins + " min";
                historyData = data.reverse(); 
            }, function(errorMsg) {
                isError = true;
                sgvText = "Err";
            });
        });
    }

    function checkAlerts(entry) {
        var val = entry.sgv;
        var message = "";
        var type = "";

        if (val <= 75) {
            message = "ALERTE BASSE : " + sgvText + " " + unit;
            type = "critical";
        } else if (val >= 250) {
            message = "ALERTE HAUTE : " + sgvText + " " + unit;
            type = "warning";
        }

        if (message !== "") {
            alertSound.play();
            // Utilisation de l'API de notification Plasma
            plasmoid.notification({
                title: "Blood Glucose Monitor",
                message: message,
                icon: "medical-cross"
            });
        }
    }

    function checkTailscaleStatus(callback) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "http://100.100.100.100/", true);
        xhr.timeout = 2000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) callback(xhr.status !== 0);
        };
        xhr.onerror = function() { callback(false); };
        xhr.ontimeout = function() { callback(false); };
        xhr.send();
    }

    function getColor() {
        if (!tailscaleConnected) return "#ff0000"; 
        if (isError) return Kirigami.Theme.textColor;
        if (sgvValue <= 0) return Kirigami.Theme.textColor; 
        if (sgvValue <= 75 || sgvValue >= 250) return "#ff0000"; 
        if (sgvValue > highThreshold || sgvValue <= lowThreshold + 10) return "#ffa500"; 
        return Kirigami.Theme.positiveTextColor; 
    }
}
