/* Copyright (C) 2021-2023 Michal Kosciesza <michal@mkiol.net>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaItem {
    id: root

    property string text: ""
    property string textPlaceholder: ""
    property string textPlaceholderActive: ""
    property alias status: indicator.status
    property bool clickable: true
    property alias off: indicator.off
    property alias busy: busyIndicator.running
    readonly property alias down: mouse.pressed
    property alias progress: busyIndicator.progress
    property double buttonSize: Math.min(intermediateLabel.height + 2 * Theme.paddingLarge, Theme.itemSizeExtraSmall)
    property bool dialogMode: false

    signal pressed()
    signal released()
    signal click()
    signal accept()
    signal dismiss()

    readonly property bool _active: highlighted
    readonly property color _pColor: _active ? Theme.highlightColor : Theme.primaryColor
    readonly property color _sColor: _active ? Theme.secondaryHighlightColor : Theme.secondaryColor
    readonly property bool _empty: text.length === 0

    height: row.height
    highlighted: mouse.pressed || !root.clickable || root.off

    Row {
        id: row

        height: intermediateLabel.height + 2 * Theme.paddingLarge
        spacing: Theme.paddingSmall

        anchors {
            topMargin: Theme.paddingLarge
            top: parent.top
            leftMargin: Theme.paddingSmall
            left: parent.left
            rightMargin: root.dialogMode ? Theme.paddingSmall : Theme.horizontalPageMargin
            right: parent.right
        }

        Item {
            id: indicatorWrapper

            width: indicator.width
            height: indicator.height

            SpeechIndicator {
                id: indicator

                width: Theme.itemSizeSmall
                color: root._pColor
                // 0 - no speech, 1 - speech detected,
                // 2 - speech decoding, 3 - speech initializing,
                // 4 - playing speech
                status: 0
                off: false
                visible: opacity > 0.0
                opacity: busyIndicator.running ? 0.0 : 1.0
                Behavior on opacity { FadeAnimator {} }

            }

            BusyIndicatorWithProgress {
                id: busyIndicator

                size: BusyIndicatorSize.Medium
                anchors.centerIn: indicator
                running: false
                _forceAnimation: true
            }
        }

        Label {
            id: intermediateLabel

            text: {
                if (root._empty) return root._active ?
                                     root.textPlaceholderActive :
                                     root.textPlaceholder
                return root.text
            }
            wrapMode: root._empty ? Text.NoWrap : Text.WordWrap
            truncationMode: _empty ? TruncationMode.Fade : TruncationMode.None
            color: root._empty ? root._sColor : root._pColor
            font.italic: root._empty
            width: parent.width - indicator.width -
                   (root.dialogMode ? 2 * (root.buttonSize + Theme.paddingSmall) : 0)
            Behavior on width { NumberAnimation { duration: 100 } }
        }

        Row {
            height: root.buttonSize
            anchors.verticalCenter: indicatorWrapper.verticalCenter
            opacity: root.dialogMode ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {} }
            visible: opacity > 0.0

            IconButton {
                width: root.buttonSize; height: root.buttonSize
                icon {
                    width: root.buttonSize * 0.8; height: root.buttonSize * 0.8
                    source: "image://theme/icon-m-accept?" + (pressed
                                                              ? Theme.highlightColor
                                                              : Theme.primaryColor)
                }
                onClicked: root.accept()
            }

            IconButton {
                width: root.buttonSize; height: root.buttonSize
                icon {
                    width: root.buttonSize * 0.8; height: root.buttonSize * 0.8
                    source: "image://theme/icon-m-dismiss?" + (pressed
                                                               ? Theme.highlightColor
                                                               : Theme.primaryColor)
                }
                onClicked: root.dismiss()
            }
        }
    }

    MouseArea {
        id: mouse

        enabled: root.clickable && !root.off && !root.dialogMode
        anchors.fill: parent
        onPressedChanged: {
            if (pressed) root.pressed()
            else root.released()
        }
        onClicked: root.click()
    }
}
