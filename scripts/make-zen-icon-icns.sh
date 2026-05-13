#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/make-zen-icon-icns.sh [source-png] [output-icns]

Defaults:
  source-png:  configs/zen/icon.png
  output-icns: configs/zen/icon.icns

Use a square PNG, ideally 1024x1024 with transparency if desired.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: this script uses macOS sips/iconutil and must run on Darwin" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_PNG="${1:-$REPO_ROOT/configs/zen/icon.png}"
OUTPUT_ICNS="${2:-$REPO_ROOT/configs/zen/icon.icns}"

if [[ ! -f "$SOURCE_PNG" ]]; then
  echo "error: source PNG not found: $SOURCE_PNG" >&2
  echo "Put your icon at configs/zen/icon.png or pass a source PNG path." >&2
  exit 1
fi

width="$(/usr/bin/sips -g pixelWidth "$SOURCE_PNG" | awk '/pixelWidth/ { print $2 }')"
height="$(/usr/bin/sips -g pixelHeight "$SOURCE_PNG" | awk '/pixelHeight/ { print $2 }')"

if [[ "$width" != "$height" ]]; then
  echo "warning: source PNG is ${width}x${height}; square input is recommended" >&2
fi

mkdir -p "$(dirname "$OUTPUT_ICNS")"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

iconset="$workdir/Zen.iconset"
mkdir -p "$iconset"

make_icon() {
  local size="$1"
  local filename="$2"
  /usr/bin/sips -z "$size" "$size" "$SOURCE_PNG" --out "$iconset/$filename" >/dev/null
}

make_icon 16 icon_16x16.png
make_icon 32 icon_16x16@2x.png
make_icon 32 icon_32x32.png
make_icon 64 icon_32x32@2x.png
make_icon 128 icon_128x128.png
make_icon 256 icon_128x128@2x.png
make_icon 256 icon_256x256.png
make_icon 512 icon_256x256@2x.png
make_icon 512 icon_512x512.png
make_icon 1024 icon_512x512@2x.png

/usr/bin/iconutil -c icns "$iconset" -o "$OUTPUT_ICNS"

echo "Wrote $OUTPUT_ICNS"
