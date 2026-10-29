// Quick Reference: a quick viewer for the handful of documents you keep
// coming back to. Shows the files in one folder as cards in a carousel;
// Enter reads a text or Markdown document in place, or opens an image or
// PDF in Omarchy's viewer; Ctrl+E edits a text document.
//
// The carousel is Omarchy's image picker (`omarchy.image-picker`, MIT),
// with document cards in place of wallpaper thumbnails.
// SPDX-License-Identifier: GPL-3.0-only

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Commons
import qs.Commons as Commons
import "QuickReferenceModel.js" as Model

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  readonly property string pluginId: "ggregoro.quick-reference"
  readonly property string home: Quickshell.env("HOME")
  readonly property string defaultFolder: home + "/Documents/Quick Reference"
  readonly property string listScript: decodeURIComponent(String(Qt.resolvedUrl("list.sh")).replace(/^file:\/\//, ""))

  // Set by the "folder" field of this plugin's entry in shell.json.
  property string folder: defaultFolder
  property var docs: []
  property int selectedIndex: 0
  property string selectedPath: ""
  property bool opened: false
  property bool loaded: false
  property bool viewing: false
  property string filterText: ""
  property string viewerText: ""

  // The carousel uses the image picker's colours; the cards use the menu's.
  property color dimColor: Commons.Color.background
  property color foreground: Commons.Color.imagePicker.text
  property color scrim: Commons.Color.imagePicker.scrim
  property color selectedBorder: Commons.Color.imagePicker.selectedBorder
  property color unselectedBorder: Commons.Color.imagePicker.unselectedBorder
  property color cardBackground: Commons.Color.menu.background
  property color cardText: Commons.Color.menu.text
  property color accent: Commons.Color.accent

  property int expandedWidth: 768
  property int expandedHeight: 475
  property int sliceWidth: 108
  property int sliceHeight: 432
  property int sliceSpacing: -30
  property int skewOffset: 28
  // Keeps card text clear of the slanted edges.
  readonly property int textInset: skewOffset + 26
  property int bottomChromeHeight: 104

  readonly property var currentDoc: docs.length > 0 && itemMatches(selectedIndex) ? docs[selectedIndex] : null

  function labelForPath(path) {
    return Model.labelForPath(path)
  }

  function itemMatches(index) {
    return Model.itemMatches(docs, index, filterText)
  }

  function filteredPosition(index) {
    return Model.filteredPosition(docs, index, filterText)
  }

  function selectedFilteredPosition() {
    return Model.selectedFilteredPosition(docs, selectedIndex, filterText)
  }

  function currentLabel() {
    if (!currentDoc) return filterText ? "No matches" : ""
    return labelForPath(currentDoc.filePath)
  }

  function hintText() {
    if (!currentDoc) return "Esc  close"
    var parts = ["Enter  open"]
    if (Model.isText(currentDoc.kind)) parts.push("Ctrl+E  edit")
    parts.push("type to filter", "Esc  close")
    return parts.join("     ")
  }

  function select(index) {
    if (index < 0 || index >= docs.length || !itemMatches(index)) return
    selectedIndex = index
    selectedPath = docs[index].filePath
  }

  function selectAdjacent(direction) {
    var count = docs.length
    var index = selectedIndex
    for (var i = 0; i < count; i++) {
      index = (index + direction + count) % count
      if (itemMatches(index)) {
        select(index)
        return
      }
    }
  }

  function updateFilter(nextFilterText) {
    filterText = nextFilterText
    if (!itemMatches(selectedIndex)) {
      var first = Model.nextSelectedIndexForFilter(docs, selectedIndex, filterText)
      if (first >= 0) select(first)
    }
  }

  function loadRows(rows) {
    var next = Model.loadRows(rows)
    docs = next
    selectedIndex = Model.indexForPath(next, selectedPath)
    if (next.length > 0) selectedPath = next[selectedIndex].filePath
    loaded = true
    focusCarousel()
  }

  function refresh() {
    if (listProc.running) return
    listProc.command = ["bash", root.listScript, root.folder]
    listProc.running = true
  }

  function focusCarousel() {
    Qt.callLater(function() {
      if (root.opened && !root.viewing) carousel.forceActiveFocus()
    })
  }

  function openSelected() {
    var doc = currentDoc
    if (!doc) return

    if (Model.isText(doc.kind)) {
      viewerFile.path = doc.filePath
      viewerFile.reload()
      viewing = true
      viewerFlick.contentY = 0
      Qt.callLater(function() { viewerFlick.forceActiveFocus() })
    } else {
      close()
      Quickshell.execDetached(["uwsm-app", "--", "xdg-open", doc.filePath])
    }
  }

  function editSelected() {
    var doc = currentDoc
    if (!doc || !Model.isText(doc.kind)) return
    close()
    Quickshell.execDetached(["omarchy-launch-editor", doc.filePath])
  }

  function closeViewer() {
    viewing = false
    focusCarousel()
  }

  function scrollViewer(delta) {
    var max = Math.max(0, viewerFlick.contentHeight - viewerFlick.height)
    viewerFlick.contentY = Math.max(0, Math.min(max, viewerFlick.contentY + delta))
  }

  // Lifecycle hooks called by omarchy-shell (summon / hide / toggle).
  function open(payload) {
    filterText = ""
    viewing = false
    loaded = false
    opened = true
    refresh()
  }

  function close() {
    viewing = false
    filterText = ""
    opened = false
  }

  function toggle() {
    if (opened) close()
    else open("{}")
  }

  FileView {
    id: shellConfig
    path: root.home + "/.config/omarchy/shell.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.folder = Model.folderFromShellConfig(text(), root.pluginId, root.home, root.defaultFolder)
    onLoadFailed: root.folder = root.defaultFolder
    onFileChanged: reload()
  }

  FileView {
    id: viewerFile
    printErrors: false
    onLoaded: root.viewerText = text()
    onLoadFailed: root.viewerText = "This document could not be read."
  }

  Process {
    id: listProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.loadRows(String(text || ""))
    }
  }

  PanelWindow {
    id: panel

    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "quick-reference"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.viewing ? root.closeViewer() : root.close()
    }

    // Empty folder.
    Rectangle {
      visible: root.loaded && root.docs.length === 0 && !root.viewing
      anchors.centerIn: parent
      width: Math.min(parent.width - 80, root.expandedWidth)
      height: emptyText.implicitHeight + 80
      color: root.cardBackground
      border.color: root.selectedBorder
      border.width: 2

      MouseArea { anchors.fill: parent; onClicked: {} }

      Text {
        id: emptyText
        anchors.centerIn: parent
        width: parent.width - 80
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: root.cardText
        font.pixelSize: Style.font.title
        text: "No documents yet.\n\nPut the Markdown, text, image or PDF files you want at hand in\n" + root.folder + "\n\nEsc  close"
      }
    }

    Item {
      id: card
      visible: root.loaded && root.docs.length > 0 && !root.viewing
      width: Math.min(parent.width - 80, root.expandedWidth + 13 * (root.sliceWidth + root.sliceSpacing) + 40)
      height: root.expandedHeight + Style.space(30) + root.bottomChromeHeight
      anchors.centerIn: parent

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: carousel
        anchors.top: parent.top
        anchors.topMargin: Style.space(30)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bottomChromeHeight
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.expandedWidth + 13 * (root.sliceWidth + root.sliceSpacing)
        focus: true

        readonly property real itemStep: root.sliceWidth + root.sliceSpacing
        readonly property real previewX: (width - root.expandedWidth) / 2

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            if (root.filterText) root.updateFilter("")
            else root.close()
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.openSelected()
            event.accepted = true
          } else if (event.key === Qt.Key_E && (event.modifiers & Qt.ControlModifier)) {
            root.editSelected()
            event.accepted = true
          } else if (Util.editsFilter(event, root.filterText)) {
            root.updateFilter(Util.editedFilter(event, root.filterText))
            event.accepted = true
          } else if (event.key === Qt.Key_Left || (event.key === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Backtab) {
            root.selectAdjacent(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            root.selectAdjacent(1)
            event.accepted = true
          } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127 && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
            root.updateFilter(root.filterText + event.text)
            event.accepted = true
          }
        }

        Repeater {
          model: root.docs.length

          delegate: Item {
            id: item
            required property int index

            readonly property var doc: root.docs[index]
            readonly property string filePath: doc ? doc.filePath : ""
            readonly property string kind: doc ? doc.kind : ""
            readonly property string previewPath: doc ? doc.previewPath : ""
            readonly property bool isText: Model.isText(kind)

            readonly property bool matched: root.itemMatches(index)
            readonly property int relativeIndex: root.filteredPosition(index) - root.selectedFilteredPosition()
            readonly property bool selected: matched && index === root.selectedIndex
            readonly property bool nearby: matched && Math.abs(relativeIndex) <= 16

            property string content: ""

            visible: nearby
            x: selected ? carousel.previewX : (relativeIndex < 0 ? carousel.previewX + relativeIndex * carousel.itemStep : carousel.previewX + root.expandedWidth + root.sliceSpacing + (relativeIndex - 1) * carousel.itemStep)
            width: selected ? root.expandedWidth : root.sliceWidth
            height: selected ? root.expandedHeight : root.sliceHeight
            y: selected ? 0 : (root.expandedHeight - root.sliceHeight) / 2
            z: selected ? 100 : 50 - Math.min(Math.abs(relativeIndex), 40)

            readonly property real skAbs: Math.abs(root.skewOffset)
            readonly property real topLeft: root.skewOffset >= 0 ? skAbs : 0
            readonly property real topRight: root.skewOffset >= 0 ? width : width - skAbs
            readonly property real bottomRight: root.skewOffset >= 0 ? width - skAbs : width
            readonly property real bottomLeft: root.skewOffset >= 0 ? 0 : skAbs

            FileView {
              path: item.isText ? item.filePath : ""
              printErrors: false
              onLoaded: item.content = text()
            }

            Item {
              id: maskShape
              anchors.fill: parent
              visible: false
              layer.enabled: true

              Shape {
                anchors.fill: parent
                antialiasing: true
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                  fillColor: "white"
                  strokeColor: "transparent"
                  startX: item.topLeft; startY: 0
                  PathLine { x: item.topRight; y: 0 }
                  PathLine { x: item.bottomRight; y: item.height }
                  PathLine { x: item.bottomLeft; y: item.height }
                  PathLine { x: item.topLeft; y: 0 }
                }
              }
            }

            Item {
              anchors.fill: parent
              layer.enabled: true
              layer.smooth: true
              layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: maskShape
                maskThresholdMin: 0.3
                maskSpreadAtMin: 0.3
              }

              // Image or PDF first page.
              Image {
                anchors.fill: parent
                visible: !item.isText
                source: !item.isText && item.previewPath ? Util.fileUrl(item.previewPath) : ""
                fillMode: Image.PreserveAspectCrop
                verticalAlignment: Image.AlignTop
                cache: false
                smooth: true
              }

              // Text or Markdown document. Always laid out at full card
              // width so the slices show a strip of the same card.
              Rectangle {
                anchors.fill: parent
                visible: item.isText
                color: root.cardBackground

                Text {
                  id: cardTitle
                  x: root.textInset
                  y: Style.space(24)
                  width: root.expandedWidth - root.textInset * 2
                  textFormat: Text.PlainText
                  text: root.labelForPath(item.filePath)
                  color: root.accent
                  font.pixelSize: Style.font.display
                  font.weight: Font.DemiBold
                  elide: Text.ElideRight
                }

                Rectangle {
                  id: cardRule
                  x: root.textInset
                  y: cardTitle.y + cardTitle.height + Style.space(10)
                  width: root.expandedWidth - root.textInset * 2
                  height: 1
                  color: Util.alpha(root.cardText, 0.25)
                }

                Text {
                  x: root.textInset
                  y: cardRule.y + Style.space(14)
                  width: root.expandedWidth - root.textInset * 2
                  height: parent.height - y - Style.space(16)
                  clip: true
                  // Plain text only: rich text on the cards crashed the shell.
                  textFormat: Text.PlainText
                  text: Model.plainPreview(item.content, item.kind, 40)
                  wrapMode: Text.Wrap
                  color: root.cardText
                  font.pixelSize: Style.font.body
                  font.family: Style.font.family
                }
              }

              Rectangle {
                anchors.fill: parent
                color: Util.alpha(root.dimColor, item.selected ? 0 : 0.42)
              }
            }

            Shape {
              anchors.fill: parent
              antialiasing: true
              preferredRendererType: Shape.CurveRenderer
              ShapePath {
                fillColor: "transparent"
                strokeColor: item.selected ? root.selectedBorder : root.unselectedBorder
                strokeWidth: item.selected ? 3 : 1
                startX: item.topLeft; startY: 0
                PathLine { x: item.topRight; y: 0 }
                PathLine { x: item.bottomRight; y: item.height }
                PathLine { x: item.bottomLeft; y: item.height }
                PathLine { x: item.topLeft; y: 0 }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: item.selected ? root.openSelected() : root.select(index)
            }
          }
        }
      }

      Text {
        id: selectedLabel
        textFormat: Text.PlainText
        anchors.top: carousel.bottom
        anchors.topMargin: Style.space(16)
        anchors.horizontalCenter: carousel.horizontalCenter
        width: root.expandedWidth
        text: root.currentLabel()
        color: root.foreground
        style: Text.Outline
        styleColor: Util.alpha(root.dimColor, 0.7)
        font.pixelSize: Style.font.display
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
      }

      Text {
        textFormat: Text.PlainText
        anchors.top: selectedLabel.bottom
        anchors.topMargin: Style.space(8)
        anchors.horizontalCenter: carousel.horizontalCenter
        width: root.expandedWidth
        text: root.filterText ? root.filterText : root.hintText()
        color: root.foreground
        opacity: root.filterText ? 0.85 : 0.6
        style: Text.Outline
        styleColor: Util.alpha(root.dimColor, 0.7)
        font.pixelSize: root.filterText ? Style.font.title : Style.font.body
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
      }
    }

    // Full text or Markdown document, read-only.
    Rectangle {
      id: viewer
      visible: root.viewing
      anchors.centerIn: parent
      width: Math.min(parent.width - Style.space(120), Style.space(1000))
      height: parent.height - Style.space(120)
      color: root.cardBackground
      border.color: root.selectedBorder
      border.width: 2

      MouseArea { anchors.fill: parent; onClicked: {} }

      Text {
        id: viewerTitle
        anchors { left: parent.left; right: viewerHint.left; top: parent.top; margins: Style.space(28) }
        textFormat: Text.PlainText
        text: root.currentDoc ? root.labelForPath(root.currentDoc.filePath) : ""
        color: root.accent
        font.pixelSize: Style.font.display
        font.weight: Font.DemiBold
        elide: Text.ElideRight
      }

      Text {
        id: viewerHint
        anchors { right: parent.right; rightMargin: Style.space(28); verticalCenter: viewerTitle.verticalCenter }
        textFormat: Text.PlainText
        text: "Ctrl+E  edit     Esc  back"
        color: root.cardText
        opacity: 0.6
        font.pixelSize: Style.font.body
      }

      Rectangle {
        id: viewerRule
        anchors { left: parent.left; right: parent.right; top: viewerTitle.bottom; leftMargin: Style.space(28); rightMargin: Style.space(28); topMargin: Style.space(12) }
        height: 1
        color: Util.alpha(root.cardText, 0.25)
      }

      Flickable {
        id: viewerFlick
        anchors { left: parent.left; right: parent.right; top: viewerRule.bottom; bottom: parent.bottom; leftMargin: Style.space(28); rightMargin: Style.space(28); topMargin: Style.space(16); bottomMargin: Style.space(20) }
        clip: true
        contentWidth: width
        contentHeight: viewerBody.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Keys.onPressed: function(event) {
          var page = viewerFlick.height - Style.space(40)
          if (event.key === Qt.Key_Escape) root.closeViewer()
          else if (event.key === Qt.Key_Q) root.close()
          else if (event.key === Qt.Key_E && (event.modifiers & Qt.ControlModifier)) root.editSelected()
          else if (event.key === Qt.Key_E && event.modifiers === Qt.NoModifier) root.editSelected()
          else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) root.scrollViewer(Style.space(48))
          else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) root.scrollViewer(-Style.space(48))
          else if (event.key === Qt.Key_PageDown || event.key === Qt.Key_Space) root.scrollViewer(page)
          else if (event.key === Qt.Key_PageUp) root.scrollViewer(-page)
          else if (event.key === Qt.Key_Home) viewerFlick.contentY = 0
          else if (event.key === Qt.Key_End) root.scrollViewer(viewerFlick.contentHeight)
          else return
          event.accepted = true
        }

        Text {
          id: viewerBody
          width: viewerFlick.width
          textFormat: root.currentDoc && root.currentDoc.kind === "markdown" ? Text.MarkdownText : Text.PlainText
          text: root.currentDoc && root.currentDoc.kind === "markdown" ? root.viewerText.replace(/^\s*#[^\n]*\n/, "") : root.viewerText
          wrapMode: Text.Wrap
          color: root.cardText
          font.pixelSize: Style.font.title
          font.family: Style.font.family
          onLinkActivated: function(link) { Quickshell.execDetached(["uwsm-app", "--", "xdg-open", link]) }
        }
      }
    }
  }
}
