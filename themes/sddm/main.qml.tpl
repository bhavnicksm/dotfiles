import QtQuick 2.0
import SddmComponents 2.0

// Omarchy-style SDDM greeter, themed from the active palette by
// themes/theme-module.nix via personal.nix. Mirrors the hyprlock look:
// full-bleed wallpaper, dimmed, centered rounded password field.

Rectangle {
  id: root
  width: 640
  height: 480
  color: "#000000"

  property string currentUser: userModel.lastUser
  property bool loginFailed: false
  property int sessionIndex: sessionModel.lastIndex

  Connections {
    target: sddm
    function onLoginFailed() {
      root.loginFailed = true
      password.text = ""
      password.focus = true
    }
    function onLoginSucceeded() {
      root.loginFailed = false
    }
  }

  Image {
    anchors.fill: parent
    source: "{{ wallpaper }}"
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
  }

  // Dim overlay so the frosted card and text stay readable on any wallpaper
  Rectangle {
    anchors.fill: parent
    color: "{{ dimOverlay }}"
  }

  Column {
    anchors.centerIn: parent
    spacing: 24

    Rectangle {
      id: entry
      width: 381
      height: 67
      radius: 6
      anchors.horizontalCenter: parent.horizontalCenter
      color: "{{ cardFill }}"
      border.color: root.loginFailed ? "{{ errorColor }}" : "{{ cardBorder }}"
      border.width: 3

      TextInput {
        id: password
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        echoMode: TextInput.Password
        passwordCharacter: "\u25CF"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 22
        font.letterSpacing: 4
        color: "{{ textColor }}"
        selectionColor: "{{ selection }}"
        cursorVisible: true
        focus: true

        onTextChanged: root.loginFailed = false

        Keys.onPressed: {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            sddm.login(root.currentUser, password.text, root.sessionIndex)
            event.accepted = true
          }
        }
      }

      Text {
        anchors.fill: password
        text: root.loginFailed ? "Authentication failed" : "Enter Password"
        visible: password.text.length === 0
        color: root.loginFailed ? "{{ errorColor }}" : "{{ placeholderColor }}"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 17
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }
  }

  Component.onCompleted: password.forceActiveFocus()
}