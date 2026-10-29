#!/bin/bash
# Lists the documents in the Quick Reference folder, one row per file:
#   path<TAB>kind<TAB>preview
# kind is markdown, text, image or pdf. A PDF's preview is its first page,
# drawn by pdftoppm into the cache and redrawn only when the PDF changes.
# Other files in the folder are skipped.

folder="$1"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/quick-reference"

[[ -n $folder ]] || exit 0
mkdir -p "$folder" "$cache" 2>/dev/null

find -L "$folder" -maxdepth 1 -type f ! -name '.*' -print0 2>/dev/null | sort -z |
  while IFS= read -r -d '' file; do
    case "${file,,}" in
      *.md | *.markdown)
        printf '%s\tmarkdown\t\n' "$file"
        ;;
      *.txt)
        printf '%s\ttext\t\n' "$file"
        ;;
      *.png | *.jpg | *.jpeg | *.webp | *.gif)
        printf '%s\timage\t%s\n' "$file" "$file"
        ;;
      *.pdf)
        preview="$cache/$(printf '%s' "$file" | md5sum | cut -d ' ' -f 1).png"
        if [[ ! $preview -nt $file ]]; then
          pdftoppm -png -singlefile -f 1 -l 1 -scale-to 1024 "$file" "${preview%.png}" 2>/dev/null
        fi
        [[ -f $preview ]] && printf '%s\tpdf\t%s\n' "$file" "$preview"
        ;;
    esac
  done
