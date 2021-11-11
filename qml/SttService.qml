/* Copyright (C) 2021 Michal Kosciesza <michal@mkiol.net>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

import QtQuick 2.0
import Nemo.DBus 2.0

Item {
    id: root

//    enum StateType {
//        Unknown = 0,
//        NotConfigured = 1,
//        Busy = 2,
//        Idle = 3,
//        ListeningManual = 4,
//        ListeningAuto = 5,
//        TranscribingFile = 6
//    }

    property bool active: false
    readonly property bool connected: dbus.state > 0
    readonly property alias speech: dbus.speech
    readonly property alias state: dbus.state
    readonly property bool anotherAppConnected: dbus.myTask !== dbus.currentTask
    readonly property bool busy: dbus.state === 2 || anotherAppConnected
    readonly property bool configured: dbus.state > 1
    signal intermediateTextReady(string text)
    signal textReady(string text)

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
                  [{"type": "i", "value": 1}, {"type": "s", "value": lang}],
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
        property bool speech: false
        property var translations

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
                dbus.speech = false
            }
        }

        function updateProperties() {
            dbus.translations = dbus.getProperty("Translations")
            dbus.currentTask = dbus.getProperty("CurrentTask")
            if (dbus.currentTask == -1) dbus.myTask = -1
            dbus.state = dbus.getProperty("State")
            if (dbus.currentTask > -1 && dbus.currentTask === dbus.myTask) {
                dbus.speech = dbus.getProperty("Speech")
            } else {
                dbus.speech = false
            }
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
