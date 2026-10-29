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

1. Press the key you bind it to.
2. Your documents appear as cards in a carousel, like Omarchy's background
   switcher. Each card shows the title and the first part of the document,
   in your theme's colours.
3. Scroll with the arrow keys, or type to filter by title.
4. Press `Enter` to open the full document, read-only. `Esc` closes it.

## Planned for the first version

- Markdown (`.md`) and plain text (`.txt`) documents
- You choose which documents (or which folder) it shows
- Cards drawn in the current theme's colours and font, redrawn when you
  change theme
- Filter by title
- One key binding to open it

Maybe later: PDFs and images, searching inside documents.

## Examples

The [`examples`](examples) folder has three sample documents to try it with:
a recipe, a hardware spec sheet and a set of keyboard shortcuts.

## Background

It started as a small script that turns a folder of cheat sheets into
preview cards and opens them in Omarchy's own image picker. It worked well
enough to deserve a proper plugin.

## License

GPL-3.0, see [`LICENSE`](LICENSE).
