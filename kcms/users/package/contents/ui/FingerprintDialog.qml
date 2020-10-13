/*
    Copyright 2020  Devin Lin <espidev@gmail.com>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) version 3, or any
    later version accepted by the membership of KDE e.V. (or its
    successor approved by the membership of KDE e.V.), which shall
    act as a proxy defined in Section 6 of version 3 of the license.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.12
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.3
import QtQuick.Shapes 1.12
import QtQuick.Controls 2.5 as QQC2

import org.kde.kirigami 2.12 as Kirigami
import FingerprintModel 1.0

Kirigami.OverlaySheet {
    id: fingerprintRoot
    
    property var account
    property var fingerprintModel: kcm.fingerprintModel
    
    enum DialogState {
        FingerprintList,
        PickFinger,
        Enrolling,
        EnrollComplete
    }
    
    function openAndClear() {
        fingerprintModel.switchUser(account.name == kcm.userModel.getLoggedInUser().name ? "" : account.name);
        this.open();
    }

    onSheetOpenChanged: {
        if (sheetOpen && fingerprintModel.currentlyEnrolling) {
            fingerprintModel.stopEnrolling();
        }
    }
    
    header: Kirigami.Heading {
        text: i18n("Fingerprint")
    }
    
    footer: RowLayout {
        Item {
            Layout.fillWidth: true
        }
        
        // FingerprintList State
        QQC2.Button {
            text: i18n("Clear Fingerprints")
            visible: fingerprintModel.dialogState === FingerprintDialog.DialogState.FingerprintList
            enabled: fingerprintModel.enrolledFingerprints.length !== 0
            icon.name: "delete"
            onClicked: fingerprintModel.clearFingerprints();
        }
        QQC2.Button {
            text: i18n("Add")
            visible: fingerprintModel.dialogState === FingerprintDialog.DialogState.FingerprintList
            enabled: fingerprintModel.availableFingersToEnroll.length !== 0
            icon.name: "list-add"
            onClicked: fingerprintModel.dialogState = FingerprintDialog.DialogState.PickFinger
        }
        
        // PickFinger State
        QQC2.Button {
            text: i18n("Cancel")
            visible: fingerprintModel.dialogState === FingerprintDialog.DialogState.PickFinger
            icon.name: "dialog-cancel"
            onClicked: fingerprintModel.dialogState = FingerprintDialog.DialogState.FingerprintList
        }
        QQC2.Button {
            text: i18n("Continue")
            visible: fingerprintModel.dialogState === FingerprintDialog.DialogState.PickFinger
            icon.name: "dialog-ok"
            onClicked: fingerprintModel.startEnrolling(pickFingerBox.currentValue);
        }
        
        // Enrolling State
        QQC2.Button {
            text: i18n("Cancel")
            visible: fingerprintModel.dialogState === FingerprintDialog.DialogState.Enrolling
            icon.name: "dialog-cancel"
            onClicked: fingerprintModel.stopEnrolling();
        }
        
        // EnrollComplete State
        QQC2.Button {
            text: i18n("Done")
            visible: fingerprintModel.dialogState === FingerprintDialog.DialogState.EnrollComplete
            icon.name: "dialog-ok"
            onClicked: fingerprintModel.stopEnrolling();
        }
    }

    contentItem: Item {
        id: rootPanel
        // TODO figure out why specified width is not being used at all
        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
        Layout.maximumWidth: Kirigami.Units.gridUnit * 12
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        width: Kirigami.Units.gridUnit * 12
        height: Kirigami.Units.gridUnit * 12
        
        ColumnLayout {
            id: enrollFeedback
            spacing: Kirigami.Units.largeSpacing * 2
            visible: fingerprintModel.dialogState === FingerprintDialog.DialogState.Enrolling || fingerprintModel.dialogState === FingerprintDialog.DialogState.EnrollComplete
            anchors.fill: parent
            
            Kirigami.Heading {
                level: 2
                text: i18n("Enrolling Fingerprint")
                Layout.alignment: Qt.AlignHCenter
                visible: fingerprintModel.dialogState === FingerprintDialog.DialogState.Enrolling
            }
            
            QQC2.Label {
                text: i18n("Please repeatedly " + fingerprintModel.scanType + " your " + pickFingerBox.currentText.toLowerCase() + " on the fingerprint sensor.")
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                Layout.maximumWidth: parent.width
                visible: fingerprintModel.dialogState === FingerprintDialog.DialogState.Enrolling
            }
            
            Kirigami.Heading {
                level: 2
                text: i18n("Finger Enrolled")
                Layout.alignment: Qt.AlignHCenter
                visible: fingerprintModel.dialogState === FingerprintDialog.DialogState.EnrollComplete
            }

            // reset from back from whatever color was used before
            onVisibleChanged: colorChangeBackTimer.restart();
            
            // progress circle
            Item {
                width: progressCircle.width
                height: progressCircle.height
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                
                Timer {
                    id: colorChangeBackTimer
                    interval: 500
                    onTriggered: {
                        iconColorAnimation.to = Kirigami.Theme.textColor
                        iconColorAnimation.start();
                        circleColorAnimation.to = Kirigami.Theme.highlightColor
                        circleColorAnimation.start();
                    }
                }
                
                Connections {
                    target: fingerprintModel
                    function onScanSuccess() {
                        iconColorAnimation.to = Kirigami.Theme.highlightColor
                        iconColorAnimation.start();
                        colorChangeBackTimer.restart();
                    }
                    function onScanFailure() {
                        iconColorAnimation.to = Kirigami.Theme.negativeTextColor
                        iconColorAnimation.start();
                        colorChangeBackTimer.restart();
                    }
                    function onScanComplete() {
                        iconColorAnimation.to = Kirigami.Theme.positiveTextColor
                        iconColorAnimation.start();
                    }
                }
                
                Kirigami.Icon {
                    id: fingerprintEnrollFeedback
                    source: "fingerprint"
                    implicitHeight: Kirigami.Units.iconSizes.huge
                    implicitWidth: implicitHeight
                    anchors.centerIn: parent
                
                    ColorAnimation on color {
                        id: iconColorAnimation
                        easing.type: Easing.InOutQuad
                        duration: 200
                    }
                }
                
                Shape {
                    id: progressCircle
                    anchors.horizontalCenter: fingerprintEnrollFeedback.horizontalCenter
                    anchors.verticalCenter: fingerprintEnrollFeedback.verticalCenter
                    implicitWidth: Kirigami.Units.iconSizes.huge + Kirigami.Units.gridUnit
                    implicitHeight: Kirigami.Units.iconSizes.huge + Kirigami.Units.gridUnit
                    layer.enabled: true
                    layer.samples: 40
                    anchors.centerIn: parent
                    
                    property int rawAngle: fingerprintModel.enrollProgress * 360
                    property int renderedAngle: 0
                    NumberAnimation on renderedAngle {
                        id: elapsedAngleAnimation
                        easing.type: Easing.InOutQuad
                        duration: 500
                    }
                    onRawAngleChanged: {
                        elapsedAngleAnimation.to = rawAngle;
                        elapsedAngleAnimation.start();
                    }
                    
                    ShapePath {
                        strokeColor: "lightgrey"
                        fillColor: "transparent"
                        strokeWidth: 3
                        capStyle: ShapePath.FlatCap
                        PathAngleArc {
                            centerX: progressCircle.implicitWidth / 2; centerY: progressCircle.implicitHeight / 2;
                            radiusX: (progressCircle.implicitWidth - Kirigami.Units.gridUnit) / 2; radiusY: radiusX;
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }
                    ShapePath {
                        strokeColor: Kirigami.Theme.highlightColor
                        fillColor: "transparent"
                        strokeWidth: 3
                        capStyle: ShapePath.RoundCap
                        
                        ColorAnimation on strokeColor {
                            id: circleColorAnimation
                            easing.type: Easing.InOutQuad
                            duration: 200
                        }
                        
                        PathAngleArc {
                            centerX: progressCircle.implicitWidth / 2; centerY: progressCircle.implicitHeight / 2;
                            radiusX: (progressCircle.implicitWidth - Kirigami.Units.gridUnit) / 2; radiusY: radiusX;
                            startAngle: -90
                            sweepAngle: progressCircle.renderedAngle
                        }
                    }
                }
            }
            
            QQC2.Label {
                text: fingerprintModel.enrollFeedback
                wrapMode: Text.Wrap
                Layout.maximumWidth: parent.width
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            }
        }
        
        ColumnLayout {
            id: pickFinger
            visible: fingerprintModel.dialogState === FingerprintDialog.DialogState.PickFinger
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing
            
            Kirigami.Icon {
                source: "fingerprint"
                implicitHeight: Kirigami.Units.iconSizes.huge
                implicitWidth: Kirigami.Units.iconSizes.huge
                Layout.alignment: Qt.AlignHCenter
            }
            
            Kirigami.Heading {
                level: 2
                text: i18n("Pick a finger to enroll")
                Layout.alignment: Qt.AlignHCenter
            }
            
            QQC2.ComboBox {
                id: pickFingerBox
                model: fingerprintModel.availableFingersToEnroll
                textRole: "friendlyName"
                valueRole: "internalName"
                Layout.alignment: Qt.AlignHCenter
            }
        }
        
        ColumnLayout {
            id: fingerprints
            spacing: Kirigami.Units.smallSpacing
            visible: fingerprintModel.dialogState === FingerprintDialog.DialogState.FingerprintList
            anchors.fill: parent
            
            Kirigami.InlineMessage {
                id: errorMessage
                type: Kirigami.MessageType.Error
                visible: fingerprintModel.currentError !== ""
                text: fingerprintModel.currentError
                Layout.fillWidth: true
                actions: [
                    Kirigami.Action {
                        iconName: "dialog-close"
                        onTriggered: fingerprintModel.currentError = ""
                    }
                ]
            }
            
            ListView {
                id: fingerprintsList
                model: kcm.fingerprintModel.deviceFound ? fingerprintModel.enrolledFingerprints : 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

                delegate: Kirigami.SwipeListItem {
                    property Finger finger: modelData
                    contentItem: RowLayout {
                        Kirigami.Icon {
                            source: "fingerprint"
                            height: Kirigami.Units.iconSizes.medium
                            width: Kirigami.Units.iconSizes.medium
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: finger.internalName
                            Component.onCompleted: console.log(finger)
                        }
                    }
                }
                
                Kirigami.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - (Kirigami.Units.largeSpacing * 4)
                    visible: fingerprintsList.count == 0
                    text: i18n("No fingerprints added")
                    icon.name: "fingerprint"
                }
            }
        }
    }
}

