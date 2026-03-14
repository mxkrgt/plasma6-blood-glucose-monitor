import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: compactRoot
    Layout.minimumWidth: contentLayout.implicitWidth
    Layout.minimumHeight: contentLayout.implicitHeight

    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            text: root.isStale && !root.isError ? "⚠️" : ""
            visible: root.isStale && !root.isError
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8
        }

        PlasmaComponents.Label {
            id: sgvLabel
            text: root.sgvText + " " + root.unit + " " + root.trendArrow
            color: root.isStale ? Kirigami.Theme.disabledTextColor : root.getColor()
            font.weight: Font.Bold
        }
    }
}
