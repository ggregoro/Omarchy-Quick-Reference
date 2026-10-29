# Omarchy Quick Reference

> **Status: in development.** Nothing to install yet. This page describes
> what the plugin will do.

A quick viewer for the handful of documents you keep coming back to, for
[Omarchy](https://omarchy.org). Press a key, scroll through your documents
as large cards, and press `Enter` to read the one you need. No file manager,
no searching through folders.

It is meant for a short list you pick yourself, not for everything on your
disk:

- cheat sheets and keyboard shortcuts
- recipes
- specs for the hardware you work with
- runbooks, procedures and checklists
- study notes

## How it works

1. Put the documents you want at hand in one folder:
   `~/Documents/Quick Reference` (created on first run; you can point it at
   another folder in the settings).
2. Press the key you bind it to.
3. Your documents appear as cards in a carousel, like Omarchy's background
   switcher, in your theme's colours.
4. Scroll with the arrow keys, or type to filter by title.
5. Press `Enter` to open the one you need. `Esc` closes it.

When you no longer need a document, move it out of the folder. That's all
the managing there is.

## Supported files (planned for the first version)

| File | Card shows | Opens in |
|---|---|---|
| Markdown (`.md`), text (`.txt`) | Title and the start of the text | A read-only view in the panel |
| Images (`.png`, `.jpg`, `.webp`) | The image | Omarchy's image viewer |
| PDF (`.pdf`) | The first page | Omarchy's PDF viewer |

Previews for PDFs use `pdftoppm`; both it and the PDF viewer come with
Omarchy, so there is nothing extra to install.

**Word and LibreOffice documents** (`.docx`, `.odt` and so on) are not
supported: previewing them would need a full office suite running in the
background. Save them as PDF instead; every office app can, and the PDF
looks the same. Files the plugin can't show are skipped, so nothing breaks
if one ends up in the folder.

## Also planned

- Cards in the current theme's colours and font, redrawn when you change
  theme
- Filter by title
- One key binding to open it

Maybe later: searching inside documents.

## Examples

The [`examples`](examples) folder has three sample documents to try it with:
a recipe, a hardware spec sheet and a set of keyboard shortcuts.

## Background

It started as a small script that turns a folder of cheat sheets into
preview cards and opens them in Omarchy's own image picker. It worked well
enough to deserve a proper plugin.

## License

GPL-3.0, see [`LICENSE`](LICENSE).
