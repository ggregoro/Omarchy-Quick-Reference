// Document list helpers for Quick Reference. The filtering and position
// helpers follow Omarchy's image picker model (MIT).
// SPDX-License-Identifier: GPL-3.0-only

function nameForPath(path) {
  return String(path || "").split("/").pop().replace(/\.[^/.]+$/, "")
}

function labelForPath(path) {
  return nameForPath(path).replace(/[-_]+/g, " ").replace(/\b\w/g, function(match) { return match.toUpperCase() })
}

function isText(kind) {
  return kind === "markdown" || kind === "text"
}

// Card preview as plain text: Markdown markup is stripped so the cards
// never render rich text (drawing several large Markdown documents at once
// crashed the shell). Tables become "cell · cell" lines.
function plainPreview(content, kind, maxLines) {
  var lines = String(content || "").split("\n")
  var out = []
  var skippedTitle = false
  var limit = maxLines || 40

  for (var i = 0; i < lines.length && out.length < limit; i++) {
    var line = lines[i]

    if (kind === "markdown") {
      if (/^\s*```/.test(line)) continue
      if (/^\s*\|?[\s:|-]+\|[\s:|-]*$/.test(line) && line.indexOf("-") >= 0) continue
      if (/^\s*#/.test(line)) {
        if (!skippedTitle && out.length === 0) { skippedTitle = true; continue }
        line = line.replace(/^\s*#+\s*/, "")
      }
      if (/^\s*\|/.test(line)) {
        line = line.replace(/^\s*\|/, "").replace(/\|\s*$/, "")
          .split("|").map(function(cell) { return cell.trim() }).join("  ·  ")
      }
      line = line.replace(/\*\*|__|`/g, "").replace(/\[([^\]]*)\]\([^)]*\)/g, "$1")
    }

    if (line.trim() === "" && (out.length === 0 || out[out.length - 1] === "")) continue
    out.push(line)
  }

  return out.join("\n")
}

function loadRows(rows) {
  var docs = []
  var lines = String(rows || "").split("\n")

  for (var i = 0; i < lines.length; i++) {
    var columns = lines[i].split("\t")
    if (!columns[0]) continue

    docs.push({
      filePath: columns[0],
      kind: columns[1] || "text",
      previewPath: columns[2] || ""
    })
  }

  return docs
}

function itemMatches(docs, index, filterText) {
  if (!Array.isArray(docs) || index < 0 || index >= docs.length) return false
  var needle = String(filterText || "").toLowerCase()
  if (!needle) return true

  var path = String(docs[index].filePath || "")
  return nameForPath(path).toLowerCase().indexOf(needle) !== -1
      || labelForPath(path).toLowerCase().indexOf(needle) !== -1
}

function firstMatchingIndex(docs, filterText) {
  var values = Array.isArray(docs) ? docs : []
  for (var i = 0; i < values.length; i++) {
    if (itemMatches(values, i, filterText)) return i
  }

  return -1
}

function filteredPosition(docs, index, filterText) {
  if (!filterText) return index

  var position = 0
  for (var i = 0; i < index; i++) {
    if (itemMatches(docs, i, filterText)) position++
  }

  return position
}

function selectedFilteredPosition(docs, selectedIndex, filterText) {
  if (!filterText) return selectedIndex
  return itemMatches(docs, selectedIndex, filterText) ? filteredPosition(docs, selectedIndex, filterText) : 0
}

function indexForPath(docs, path) {
  var values = Array.isArray(docs) ? docs : []
  for (var i = 0; i < values.length; i++) {
    if (values[i].filePath === path) return i
  }

  return 0
}

function nextSelectedIndexForFilter(docs, selectedIndex, filterText) {
  if (itemMatches(docs, selectedIndex, filterText)) return selectedIndex
  return firstMatchingIndex(docs, filterText)
}

// The folder comes from this plugin's entry in shell.json ("folder"), with
// a leading ~ expanded. Anything missing falls back to the default.
function folderFromShellConfig(json, pluginId, home, fallback) {
  var config
  try { config = JSON.parse(json) } catch (e) { return fallback }

  var plugins = config && Array.isArray(config.plugins) ? config.plugins : []
  for (var i = 0; i < plugins.length; i++) {
    var entry = plugins[i]
    if (!entry || entry.id !== pluginId || typeof entry.folder !== "string") continue

    var folder = entry.folder.trim()
    if (!folder) return fallback
    if (folder === "~") return home
    if (folder.indexOf("~/") === 0) return home + folder.slice(1)
    return folder
  }

  return fallback
}
