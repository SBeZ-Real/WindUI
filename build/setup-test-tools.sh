#!/bin/bash
set -euo pipefail
TOOL_DIRECTORY=${1:-"$PWD/.test-tools"}
mkdir -p "$TOOL_DIRECTORY"
curl --fail --location --retry 3 'https://github.com/luau-lang/luau/releases/download/0.746/luau-ubuntu.zip' -o "$TOOL_DIRECTORY/luau.zip"
printf '%s  %s\n' '30f11c9cde8be2dc0e3066d210705532aac3726a2db89a6c5078080b6faa6cf8' "$TOOL_DIRECTORY/luau.zip" | sha256sum --check
unzip -oq "$TOOL_DIRECTORY/luau.zip" -d "$TOOL_DIRECTORY"
chmod +x "$TOOL_DIRECTORY/luau" "$TOOL_DIRECTORY/luau-compile"
if [ -n "${GITHUB_PATH:-}" ]; then printf '%s\n' "$TOOL_DIRECTORY" >> "$GITHUB_PATH"; fi
