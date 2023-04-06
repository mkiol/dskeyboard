/* Copyright (C) 2021-2023 Michal Kosciesza <michal@mkiol.net>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

import QtQuick 2.0
import Nemo.DBus 2.0

Item {
    id: root

    /*
    States:
    0 = Unknown
    1 = Not Configured
    2 = Busy
    3 = Idle
    4 = Listening Manual
    5 = Listening Auto
    6 = Transcribing File
    7 = Listening One-sentence

    Listening modes:
    0 - Automatic
    1 - Manual
    2 - One Sentence

    Speech status:
    0 - No Speech
    1 - Speech Detected
    2 - Speech Decoding
    3 - Speech Initializing
    */

    property bool active: false // set active to send keepalive pings to stt service
    property int mode: 2 // 'One Sentence' is a default

    readonly property bool connected: dbus.state > 0
    readonly property alias speech: dbus.speech
    readonly property bool listening: dbus.state > 3 && !anotherAppConnected
    readonly property bool anotherAppConnected: dbus.myTask !== dbus.currentTask
    readonly property bool busy: speech !== 2 && speech !== 3 && (dbus.state === 2 || anotherAppConnected)
    readonly property bool configured: dbus.state > 1
    readonly property alias langs: dbus.langs

    signal intermediateTextReady(string text)
    signal textReady(string text)

    function cancel() {
        if (busy) {
            console.warn("cannot call cancel, stt service is busy")
            return;
        }

        if (dbus.myTask < 0) {
            console.warn("cannot call cancel, no active listening task")
            return;
        }

        keepaliveTaskTimer.stop()
        dbus.typedCall("Cancel", [{"type": "i", "value": dbus.myTask}],
                       function(result) {
                           if (result !== 0) {
                               console.error("cancel failed")
                           }
                       }, _handle_error)
    }

    function stopListen() {
        if (busy) {
            console.warn("cannot call stopListen, stt service is busy")
            return;
        }

        if (dbus.myTask < 0) {
            console.warn("cannot call stopListen, no active listening task")
            return;
        }

        keepaliveTaskTimer.stop()
        dbus.typedCall("StopListen", [{"type": "i", "value": dbus.myTask}],
                       function(result) {
                           if (result !== 0) {
                               console.error("stopListen failed")
                           }
                       }, _handle_error)
    }

    function startListen(lang) {
        if (busy) {
            console.error("cannot call startListen, stt service is busy")
            return;
        }

        if (!lang) lang = '';

        dbus.typedCall("StartListen",
                  [{"type": "i", "value": root.mode}, {"type": "s", "value": lang}, {"type": "b", "value": false}],
                  function(result) {
                      dbus.myTask = result
                      if (result < 0) {
                          console.error("startListen failed")
                      } else {
                          _keepAliveTask()
                      }
                  }, _handle_error)
    }

    function translate(id) {
        if (connected) {
            var trans = dbus.translations[id]
            if (trans.length > 0) return trans
        }
        return ""
    }

    // ------

    function _keepAliveTask() {
        if (dbus.myTask < 0) return;
        dbus.typedCall("KeepAliveTask", [{"type": "i", "value": dbus.myTask}],
                       function(result) {
                           if (result > 0 && root.active && dbus.myTask > 0) {
                               keepaliveTaskTimer.interval = result * 0.75
                               keepaliveTaskTimer.start()
                           }
                       }, _handle_error)
    }

    function _keepAliveService() {
        dbus.typedCall("KeepAliveService", [],
                       function(result) {
                           if (result > 0 && root.active) {
                               keepaliveServiceTimer.interval = result * 0.75
                               keepaliveServiceTimer.start()
                           }
                       }, _handle_error)
    }

    function _handle_result(result) {
        console.debug("DBus call completed", result)
    }

    function _handle_error(error, message) {
        console.debug("DBus call failed", error, "message:", message)
    }

    DBusInterface {
        id: dbus

        property int myTask: -1
        property int currentTask: -1
        property int state: 0
        property int speech: 0
        property var translations
        property var langs

        service: "org.mkiol.Stt"
        iface: "org.mkiol.Stt"
        path: "/"

        signalsEnabled: true

        function intermediateTextDecoded(text, lang, task) {
            if (myTask === task) {
                root.intermediateTextReady(text)
            }
        }

        function textDecoded(text, lang, task) {
            if (myTask === task) {
                root.textReady(text)
            }
        }

        function statePropertyChanged(state) {
            dbus.state = state
        }

        function speechPropertyChanged(speech) {
            if (dbus.currentTask === dbus.myTask) {
                dbus.speech = speech
            }
        }

        function currentTaskPropertyChanged(task) {
            dbus.currentTask = task
            if (dbus.currentTask == -1) dbus.myTask = -1
            if (dbus.currentTask > -1 && dbus.currentTask === dbus.myTask) {
                dbus.speech = dbus.getProperty("Speech")
            } else {
                dbus.speech = 0
            }
        }

        function langsPropertyChanged(langs) {
            dbus.langs = langs
        }

        function updateProperties() {
            dbus.translations = dbus.getProperty("Translations")
            dbus.currentTask = dbus.getProperty("CurrentTask")
            if (dbus.currentTask == -1) dbus.myTask = -1
            dbus.state = dbus.getProperty("State")
            if (dbus.currentTask > -1 && dbus.currentTask === dbus.myTask) {
                dbus.speech = dbus.getProperty("Speech")
            } else {
                dbus.speech = 0
            }
            dbus.langs = dbus.getProperty("Langs")
        }
    }

    Timer {
        id: keepaliveServiceTimer
        repeat: false
        onTriggered: _keepAliveService()
    }

    Timer {
        id: keepaliveTaskTimer
        repeat: false
        onTriggered: _keepAliveTask()
    }

    onActiveChanged: {
        if (active) {
            _keepAliveService()
            dbus.updateProperties()
        } else {
            keepaliveServiceTimer.stop()
            stopListen()
        }
    }

    Component.onDestruction: {
        stopListen()
    }
}
