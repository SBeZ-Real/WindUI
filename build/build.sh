#!/bin/bash
set -euo pipefail

MODE=${1:-"build"}
P='\033[38;2;48;255;106m'
D='\033[38;2;255;210;50m'
B='\033[38;2;50;231;255m'
E='\033[38;2;255;74;50m'
R='\033[0m'

{
    echo "-- Generated from package.json | build/build.sh"
    echo ""
    echo "return [["
    cat package.json
    echo "]]"
} > build/package.lua

if [ "$MODE" = "dev" ]; then
    INPUT=${2:-"./main.lua"}
    PREFIX="${D}[ DEV ]${R}"
else
    INPUT="src/Init.lua"
    PREFIX="${B}[ BUILD ]${R}"
fi

OUTPUT="dist/main.lua"
CONFIG="build/darklua.dev.config.json"
mkdir -p dist
trap 'rm -f dist/temp.lua' EXIT
PKG=$(node -e "console.log(JSON.stringify(require('./package.json')))")
VER=$(node -p "require('./package.json').version")
BUILD_EPOCH=${SOURCE_DATE_EPOCH:-$(git log -1 --format=%ct 2>/dev/null || date +%s)}
DATE=$(date -u -d "@$BUILD_EPOCH" '+%Y-%m-%d')
HEADER=$(node - "$DATE" <<'JS'
const fs = require('fs');
const pkg = require('./package.json');
const values = { VERSION: pkg.version, BUILD_DATE: process.argv[2], DESCRIPTION: pkg.description, REPOSITORY: pkg.repository, DISCORD: pkg.discord, LICENSE: pkg.license };
process.stdout.write(fs.readFileSync('build/header.lua', 'utf8').replace(/{{([A-Z_]+)}}/g, (_, key) => String(values[key] || '')));
JS
)
START=$(date +%s%N)
if DARKLUA_OUT=$(darklua process "$INPUT" dist/temp.lua --config "$CONFIG" 2>&1); then
    DARKLUA_EXIT=0
else
    DARKLUA_EXIT=$?
    echo "$DARKLUA_OUT" >&2
    exit "$DARKLUA_EXIT"
fi
END=$(date +%s%N)
TIME=$(( (END - START) / 1000000 ))
printf '%s\n\n' "$HEADER" > "$OUTPUT"
cat dist/temp.lua >> "$OUTPUT"
SIZE=$(( $(wc -c < "$OUTPUT") / 1024 ))
printf 'WindUI %s built in %sms (%sKB): %s\n' "$VER" "$TIME" "$SIZE" "$OUTPUT"
