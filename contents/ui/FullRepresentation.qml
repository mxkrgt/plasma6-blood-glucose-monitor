import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: fullRoot
    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.minimumHeight: Kirigami.Units.gridUnit * 14
    Layout.preferredWidth: Kirigami.Units.gridUnit * 24
    Layout.preferredHeight: Kirigami.Units.gridUnit * 18

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        // Header
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            
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
        
        PlasmaComponents.Label {
            text: root.deltaText ? "Delta: " + root.deltaText : ""
            Layout.alignment: Qt.AlignHCenter
            color: Kirigami.Theme.textColor
            visible: root.deltaText !== ""
        }

        // Graphique avec Axes
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Kirigami.Units.gridUnit
            
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
                    
                    // 1. Grille et Axes
                    ctx.strokeStyle = Kirigami.Theme.textColor;
                    ctx.fillStyle = Kirigami.Theme.textColor;
                    ctx.lineWidth = 1;
                    ctx.font = (Kirigami.Theme.defaultFont.pixelSize * 0.75) + "px sans-serif";
                    
                    // Axe Y - Valeurs
                    var steps = 4;
                    for (var s = 0; s <= steps; s++) {
                        var val = Math.round(minVal + (range * s / steps));
                        var y = drawH - (s / steps * drawH);
                        ctx.globalAlpha = 0.1;
                        ctx.beginPath(); ctx.moveTo(startX, y); ctx.lineTo(width, y); ctx.stroke();
                        ctx.globalAlpha = 0.8;
                        ctx.fillText(val, 0, y + 4);
                    }

                    // Axe X - Repères temporels (15m, 30m, 1h, 1h30)
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
                        
                        // Petite ligne verticale
                        ctx.globalAlpha = 0.1;
                        ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, drawH); ctx.stroke();
                        
                        // Label
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

                    // 2. Seuils
                    ctx.setLineDash([5, 5]);
                    var yHigh = drawH - ((root.highThreshold - minVal) / range * drawH);
                    var yLow = drawH - ((root.lowThreshold - minVal) / range * drawH);
                    ctx.globalAlpha = 0.4;
                    ctx.strokeStyle = "#ffa500"; ctx.beginPath(); ctx.moveTo(startX, yHigh); ctx.lineTo(width, yHigh); ctx.stroke();
                    ctx.strokeStyle = "#ff0000"; ctx.beginPath(); ctx.moveTo(startX, yLow); ctx.lineTo(width, yLow); ctx.stroke();
                    ctx.setLineDash([]);
                    ctx.globalAlpha = 1.0;

                    // 3. Courbe
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

                    // Gradient
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
            
            Connections {
                target: root
                function onHistoryDataChanged() {
                    chartCanvas.requestPaint();
                }
            }
        }
        
        PlasmaComponents.Label {
            text: root.isError ? "Erreur de connexion" : "Dernière mise à jour : " + root.dataAge
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8
            color: Kirigami.Theme.disabledTextColor
        }
    }
}
