#!/usr/bin/env bash
# PostToolUse hook: strip trailing whitespace and ensure a final newline on edited .lua files.
input=$(cat)
file=$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/\\\\/\//g')

case "$file" in
    *.lua) ;;
    *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

sed -i 's/[ \t]*$//' "$file"
[ -n "$(tail -c 1 "$file")" ] && printf '\n' >> "$file"
exit 0
