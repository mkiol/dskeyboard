/* Copyright (C) 2021-2023 Michal Kosciesza <michal@mkiol.net>
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

    function capitalize(text) {
        return text.charAt(0).toUpperCase() + text.slice(1);
    }

    function sendText(text) {
        if (text.length === 0) return;

        var key = Qt.createComponent("KeyBase.qml").createObject(stt)

        if (MInputMethodQuick.surroundingTextValid
                && MInputMethodQuick.contentType === Maliit.FreeTextContentType
                && !MInputMethodQuick.hiddenText) {
            var cap = MInputMethodQuick.autoCapitalizationEnabled
            var position = MInputMethodQuick.cursorPosition
            var stext = MInputMethodQuick.surroundingText
            var btext = stext.substring(0, position)
            var atext = stext.length > 0 ? stext.substring(position, stext.length - 1) : ""
            var front0 = btext.length > 0 ? btext[btext.length - 1] : ""
            var front1 = btext.length > 1 ? btext[btext.length - 2] : ""
            var back0 = atext.length > 0 ? atext[0] : ""

            if (front0.length > 0) {
                if (front0 === " ") {
                    if (cap && front1.length > 0 && ".?!".indexOf(front1) >= 0)
                        text = capitalize(text)
                } else {
                    key.text += " "
                    if (cap && ".?!".indexOf(front0) >= 0)
                        text = capitalize(text)
                }
            } else {
                text = capitalize(text)
            }

            if (back0.length === 0 || back0 !== " ")
                text += " "
        }

        key.text += text

        _handleKeyClick(key)
    }

//    onActiveChanged: {
//        console.error("keyboard.layout.languageCode", keyboard.layout.languageCode)
//        console.error("keyboard.layout.type", keyboard.layout.type)
//    }

    SpeechService {
        id: stt
        readonly property string layoutLang: stt.connected ? (keyboard.layout.languageCode === "中文" ? "zh-CN" : keyboard.layout.languageCode.toLowerCase()) : ""
        readonly property string lang: stt.connected ? (stt.sttLangs[layoutLang] ? layoutLang : "") : ""
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
                onListeningChanged: {
                    panel.clicked = false
                }
            }

            PasteButton {
                id: pasteButton
                x: panel.clicked || panel.down || stt.listening || panel.text.length > 0 ? -width : 0
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

                property bool clicked: false

                clickable: !busy
                status: stt.speech
                off: !stt.configured || !stt.connected || stt.lang.length === 0
                busy: stt.busy
                textPlaceholder: {
                    if (status === 2) return stt.translate("decoding")
                    if (status === 3) return stt.translate("initializing")
                    if (stt.listening) return stt.translate("say_smth")
                    return stt.translate("click_say_smth")
                }
                textPlaceholderActive: {
                    if (!stt.connected) return qsTr("Starting...")
                    if (stt.configured) {
                        if (status === 2) return stt.translate("decoding")
                        if (status === 3) return stt.translate("initializing")
                        if (busy) return stt.translate("busy_stt")
                        if (stt.lang.length > 0) return textPlaceholder
                    }
                    return stt.translate("lang_not_conf")
                }

                onClick: {
                    if (stt.connected && !stt.listening) clicked = true
                    else clicked = false

                    if (status === 2 || status === 3 || status === 4) {
                        stt.cancel()
                        return
                    }

                    if (stt.listening) stt.stopListen()
                    else stt.startListen(stt.lang)
                }
            }
        }
    }

    // TO-DO:
    //    verticalItem: Component {
    //        Item {
    //        }
    //    }
}
