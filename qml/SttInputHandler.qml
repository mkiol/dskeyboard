/* Copyright (C) 2021 Michal Kosciesza <michal@mkiol.net>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.keyboard 1.0
import com.meego.maliitquick 1.0

InputHandler {
    id: root

    function formatText(text) {
        return Theme.highlightText(text, MInputMethodQuick.surroundingText, palette.highlightColor)
    }

    function handleKeyClick() {
        keyboard.expandedPaste = false
        return false
    }

    function sendText(text) {
        var key = Qt.createComponent("KeyBase.qml").createObject(stt)
        var st = MInputMethodQuick.surroundingText
        if (st.length === 0 || st.charAt(st.length - 1) === " ") {
            key.text = text
        } else {
            key.text = " " + text
        }
        _handleKeyClick(key)
    }

    SttService {
        id: stt
        readonly property string layoutLang: stt.connected ? (keyboard.language === "中文" ? "zh-CN" : keyboard.language.toLowerCase()) : ""
        readonly property string lang: stt.connected ? (stt.langs[layoutLang] ? layoutLang : "") : ""
        active: root.active && keyboard.fullyOpen
        onTextReady: root.sendText(text)
    }

    topItem: Component {
        TopItem {
            threshold: Math.max(2 * keyboard.height, Theme.itemSizeSmall)
            height: panel.height

            Connections {
                target: stt
                onIntermediateTextReady: panel.text = text
                onTextReady: panel.text = ""
                onActiveChanged: {
                    if (!stt.active) {
                        panel.text = ""
                    }
                }
            }

            PasteButton {
                id: pasteButton
                x: panel.down || panel.text.length > 0 ? -width : 0
                Behavior on x { NumberAnimation { duration: 50 } }
                onClicked: {
                    root.sendText(Clipboard.text)
                    keyboard.expandedPaste = false
                }
            }

            SttPanel {
                id: panel
                anchors.left: pasteButton.right
                anchors.right: parent.right

                clickable: true
                speech: stt.speech
                off: !stt.configured || !stt.connected || stt.lang.length === 0
                busy: stt.busy
                textPlaceholder: stt.connected ? stt.translate("press_say_smth") : qsTr("Press and say something...")
                textPlaceholderActive: {
                    if (!stt.connected) return qsTr("Starting...")
                    if (stt.configured) {
                        if (busy) return stt.translate("busy_stt")
                        if (stt.lang.length > 0) return stt.translate("say_smth")
                    }
                    return stt.translate("lang_not_conf")
                }

                onPressed: stt.startListen(stt.lang)
                onReleased: stt.stopListen()
            }
        }
    }

    // TO-DO:
    //    verticalItem: Component {
    //        Item {
    //        }
    //    }
}
