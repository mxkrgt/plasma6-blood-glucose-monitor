import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: fullRoot
    Layout.minimumWidth: Kirigami.Units.gridUnit * 20
    Layout.minimumHeight: Kirigami.Units.gridUnit * 18
    Layout.preferredWidth: Kirigami.Units.gridUnit * 24
    Layout.preferredHeight: Kirigami.Units.gridUnit * 22

    property bool debugVisible: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        // Header
        RowLayout {
            Layout.fillWidth: true
            
            PlasmaComponents.Button {
                icon.name: "system-run"
                flat: true
                onClicked: fullRoot.debugVisible = !fullRoot.debugVisible
                PlasmaComponents.ToolTip { text: "Afficher/Masquer les logs de Debug" }
            }

            Item { Layout.fillWidth: true } 

            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents.Label {
                    text: root.sgvText
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 3
                    font.weight: Font.Bold
                    color: root.getColor()
                }
                
                PlasmaComponents.Label {
                    text: root.unit
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5
                    color: root.getColor()
                    Layout.alignment: Qt.AlignBottom
                }
                
                PlasmaComponents.Label {
                    text: root.trendArrow
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 3
                    color: root.getColor()
                }
            }

            Item { Layout.fillWidth: true } 

            RowLayout {
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Button {
                    icon.name: "notifications-disabled"
                    flat: true
                    visible: (root.sgvValue <= root.lowThreshold || root.sgvValue >= root.highThreshold) && root.soundEnabled
                    onClicked: root.snoozeAlert()
                    PlasmaComponents.ToolTip { text: "Snooze l'alarme (" + root.snoozeDuration + " min)" }
                }

                PlasmaComponents.Button {
                    icon.name: "view-refresh"
                    flat: true
                    onClicked: root.updateData()
                    PlasmaComponents.ToolTip { text: "Rafraîchir maintenant" }
                }
            }
        }
        
        PlasmaComponents.Label {
            text: root.deltaText ? "Delta: " + root.deltaText : ""
            Layout.alignment: Qt.AlignHCenter
            color: Kirigami.Theme.textColor
            visible: root.deltaText !== "" && !fullRoot.debugVisible
        }

        // Vue Graphique (Masquée si Debug ouvert)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Kirigami.Units.gridUnit
            visible: !fullRoot.debugVisible
            
            readonly property int leftMargin: Kirigami.Units.gridUnit * 2.5
            readonly property int bottomMargin: Kirigami.Units.gridUnit * 1.5

            Canvas {
                id: chartCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (!root.historyData || root.historyData.length < 2) return;
                    
                    var data = root.historyData;
                    var drawW = width - parent.leftMargin;
                    var drawH = height - parent.bottomMargin;
                    var startX = parent.leftMargin;
                    
                    var maxVal = 200; 
                    var minVal = 60;  
                    for (var i = 0; i < data.length; i++) {
                        if (data[i].sgv > maxVal) maxVal = data[i].sgv + 20;
                        if (data[i].sgv < minVal) minVal = data[i].sgv - 20;
                    }
                    var range = maxVal - minVal;
                    
                    ctx.strokeStyle = Kirigami.Theme.textColor;
                    ctx.fillStyle = Kirigami.Theme.textColor;
                    ctx.lineWidth = 1;
                    ctx.font = (Kirigami.Theme.defaultFont.pixelSize * 0.75) + "px sans-serif";
                    
                    var steps = 4;
                    for (var s = 0; s <= steps; s++) {
                        var val = Math.round(minVal + (range * s / steps));
                        var y = drawH - (s / steps * drawH);
                        ctx.globalAlpha = 0.1;
                        ctx.beginPath(); ctx.moveTo(startX, y); ctx.lineTo(width, y); ctx.stroke();
                        ctx.globalAlpha = 0.8;
                        ctx.fillText(val, 0, y + 4);
                    }

                    ctx.globalAlpha = 0.2;
                    ctx.beginPath(); ctx.moveTo(startX, drawH); ctx.lineTo(width, drawH); ctx.stroke();
                    
                    var lastTime = data[data.length - 1].date;
                    var firstTime = data[0].date;
                    var totalTimeMs = lastTime - firstTime;
                    
                    function drawTimeMarker(minutesAgo, label) {
                        var msAgo = minutesAgo * 60000;
                        var ratio = (totalTimeMs - msAgo) / totalTimeMs;
                        if (ratio < 0) return;
                        var x = startX + (ratio * drawW);
                        ctx.globalAlpha = 0.1;
                        ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, drawH); ctx.stroke();
                        ctx.globalAlpha = 0.7;
                        ctx.textAlign = "center";
                        ctx.fillText(label, x, height - 2);
                    }

                    drawTimeMarker(0, "Maint.");
                    drawTimeMarker(15, "15m");
                    drawTimeMarker(30, "30m");
                    drawTimeMarker(60, "1h");
                    drawTimeMarker(90, "1h30");
                    ctx.textAlign = "left";

                    ctx.setLineDash([5, 5]);
                    var yHigh = drawH - ((root.highThreshold - minVal) / range * drawH);
                    var yLow = drawH - ((root.lowThreshold - minVal) / range * drawH);
                    ctx.globalAlpha = 0.4;
                    ctx.strokeStyle = "#ffa500"; ctx.beginPath(); ctx.moveTo(startX, yHigh); ctx.lineTo(width, yHigh); ctx.stroke();
                    ctx.strokeStyle = "#ff0000"; ctx.beginPath(); ctx.moveTo(startX, yLow); ctx.lineTo(width, yLow); ctx.stroke();
                    ctx.setLineDash([]);
                    ctx.globalAlpha = 1.0;

                    var xStep = drawW / (data.length - 1);
                    ctx.beginPath();
                    ctx.strokeStyle = Kirigami.Theme.highlightColor;
                    ctx.lineWidth = 3;
                    ctx.lineJoin = "round";
                    for (var j = 0; j < data.length; j++) {
                        var px = startX + (j * xStep);
                        var py = drawH - ((data[j].sgv - minVal) / range * drawH);
                        if (j === 0) ctx.moveTo(px, py);
                        else ctx.lineTo(px, py);
                    }
                    ctx.stroke();

                    var grad = ctx.createLinearGradient(0, 0, 0, drawH);
                    grad.addColorStop(0, Kirigami.Theme.highlightColor);
                    grad.addColorStop(1, "transparent");
                    ctx.fillStyle = grad;
                    ctx.globalAlpha = 0.15;
                    ctx.lineTo(width, drawH);
                    ctx.lineTo(startX, drawH);
                    ctx.fill();
                }
            }
            Connections { target: root; function onHistoryDataChanged() { chartCanvas.requestPaint(); } }
        }
        
        PlasmaComponents.Label {
            text: root.isError ? "Erreur de connexion" : "Dernière mise à jour : " + root.dataAge
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8
            color: Kirigami.Theme.disabledTextColor
            visible: !fullRoot.debugVisible
        }

        // Vue de Debug
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: fullRoot.debugVisible

            PlasmaComponents.Label {
                text: "Console de Diagnostic"
                font.weight: Font.Bold
                color: Kirigami.Theme.highlightColor
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.focusColor
                radius: 4

                Controls.ScrollView {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    contentWidth: availableWidth
                    
                    Text {
                        width: parent.width
                        text: root.debugLogText
                        font.family: "monospace"
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.85
                        color: Kirigami.Theme.textColor
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                PlasmaComponents.Button {
                    text: "Forcer le test réseau"
                    icon.name: "network-connect"
                    onClicked: root.updateData()
                    Layout.fillWidth: true
                }
            }
        }
    }
}
