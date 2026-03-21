import QtQuick
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
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
    property string lastError: ""
    property var historyData: []
    property string debugLogText: ""
    
    property double lastAlertTimestamp: 0

    property string serverUrl: plasmoid.configuration.serverUrl
    property string apiSecretHash: plasmoid.configuration.apiSecretHash
    property string unit: plasmoid.configuration.unit
    property int lowThreshold: plasmoid.configuration.lowThreshold
    property int highThreshold: plasmoid.configuration.highThreshold
    property int refreshInterval: plasmoid.configuration.refreshInterval
    property bool soundEnabled: plasmoid.configuration.soundEnabled
    property int soundVolume: plasmoid.configuration.soundVolume
    property int soundInterval: plasmoid.configuration.soundInterval
    property int snoozeDuration: plasmoid.configuration.snoozeDuration

    property double snoozeUntil: 0
    property double lastSoundTime: 0

    toolTipMainText: "Blood Glucose Monitor"
    toolTipSubText: lastError || (isError ? "Erreur de connexion" : "Nightscout: " + serverUrl)

    Plasmoid.backgroundHints: Plasmoid.DefaultBackground
    preferredRepresentation: compactRepresentation

    compactRepresentation: CompactRepresentation {
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }
    
    fullRepresentation: FullRepresentation {}

    Plasma5Support.DataSource {
        id: soundRunner
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
        }
        function playAlert() {
            var rawVolume = Math.floor((root.soundVolume / 100.0) * 65536);
            root.logDebug("Exécution de paplay (vol: " + root.soundVolume + "% -> " + rawVolume + ")...");
            connectSource("paplay --volume=" + rawVolume + " /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga");
        }
    }

    Timer {
        id: refreshTimer
        interval: refreshInterval > 0 ? refreshInterval : 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateData()
    }

    function logDebug(msg) {
        var time = new Date().toLocaleTimeString();
        var fullMsg = "[" + time + "] " + msg;
        console.log("BloodGlucose: " + fullMsg);
        
        var lines = debugLogText.split("\n");
        if (lines.length > 30) {
            lines = lines.slice(0, 30);
        }
        debugLogText = fullMsg + "\n" + lines.join("\n");
    }

    function updateData() {
        logDebug("--- Démarrage mise à jour ---");
        fetchData();
    }

    function fetchData() {
        var url = serverUrl;
        if (!url.endsWith("/")) url += "/";
        url += "api/v1/entries/sgv.json?count=36";

        lastError = "Récupération...";
        logDebug("GET " + url);

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4) {
                logDebug("API HTTP Status: " + xhr.status);
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        logDebug("Données reçues: " + data.length + " entrées");
                        processData(data);
                    } catch (e) {
                        handleError("Erreur JSON: " + e.message);
                    }
                } else {
                    handleError("Erreur HTTP " + xhr.status);
                }
            }
        };
        xhr.open("GET", url, true);
        xhr.timeout = 8000;
        xhr.setRequestHeader("API-SECRET", apiSecretHash);
        xhr.ontimeout = function() { handleError("Timeout lors de la récupération des données"); };
        xhr.onerror = function() { handleError("Erreur réseau lors de la récupération"); };
        xhr.send();
    }

    function processData(data) {
        if (!data || data.length === 0) {
            handleError("Aucune donnée retournée par le JSON");
            return;
        }
        isError = false;
        lastError = "";
        
        var latest = data[0];
        sgvValue = latest.sgv;
        sgvText = Logic.convertSgv(sgvValue, unit);
        trendArrow = Logic.getTrendArrow(latest.direction);
        
        logDebug("Valeur lue: " + sgvValue + " " + trendArrow);

        checkAlerts(latest);

        if (data.length > 1) {
            var delta = sgvValue - data[1].sgv;
            deltaText = (delta > 0 ? "+" : "") + Logic.convertSgv(delta, unit);
        }
        
        var diffMins = Math.floor((new Date().getTime() - latest.date) / 60000);
        isStale = (diffMins > 15);
        dataAge = diffMins + " min";
        historyData = data.reverse();
        logDebug("Mise à jour UI terminée");
    }

    function handleError(msg) {
        logDebug("CRASH: " + msg);
        isError = true;
        sgvText = "Err";
        lastError = msg;
    }

    function checkAlerts(entry) {
        var val = entry.sgv;
        var message = "";
        
        if (val <= lowThreshold) message = "ALERTE BASSE : " + sgvText + " " + unit;
        else if (val >= highThreshold) message = "ALERTE HAUTE : " + sgvText + " " + unit;

        if (message !== "") {
            var now = new Date().getTime();
            
            if (!soundEnabled) {
                logDebug("Alerte bloquée : Son désactivé.");
                return;
            }
            if (now < snoozeUntil) {
                var remainingMins = Math.ceil((snoozeUntil - now) / 60000);
                logDebug("Alerte bloquée : Snooze actif (" + remainingMins + " min restants).");
                return;
            }
            if ((now - lastSoundTime) < (soundInterval * 60000)) {
                logDebug("Alerte bloquée : Intervalle non écoulé.");
                return;
            }

            logDebug("Déclenchement alerte via paplay: " + message);
            soundRunner.playAlert();
            lastSoundTime = now;
        }
    }

    function snoozeAlert() {
        snoozeUntil = new Date().getTime() + (snoozeDuration * 60000);
        logDebug("Snooze activé pour " + snoozeDuration + " minutes.");
    }

    function getColor() {
        if (isError) return Kirigami.Theme.textColor;
        if (sgvValue <= 0) return Kirigami.Theme.textColor;
        if (sgvValue <= 75 || sgvValue >= 250) return "#ff0000";
        if (sgvValue > highThreshold || sgvValue <= lowThreshold + 10) return "#ffa500";
        return Kirigami.Theme.positiveTextColor;
    }
}
