#!/usr/bin/env bash
# Ensure the exercise images (JPG) and animations (GIF) exist under ./media.
# Safe to run before every Phoenix start: a complete catalogue exits immediately.
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
media_dir="${MEDIA_DIR:-$project_dir/media}"

mkdir -p "$media_dir/img" "$media_dir/gif"
img_count="$(find "$media_dir/img" -maxdepth 1 -type f -name '*.jpg' | wc -l)"
gif_count="$(find "$media_dir/gif" -maxdepth 1 -type f -name '*.gif' | wc -l)"

# The upstream catalogue contains more than 1,300 of each. A threshold makes an interrupted or
# partial copy self-heal on the next startup without requiring a generated marker file.
if [ "$img_count" -ge 1000 ] && [ "$gif_count" -ge 1000 ]; then
  echo "✓ Exercise media ready (${img_count} images, ${gif_count} GIFs)"
  exit 0
fi

if ! command -v git >/dev/null 2>&1; then
  echo "⚠ Exercise media is missing and git is not installed; continuing without images." >&2
  exit 0
fi

tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp" "$media_dir/img.new" "$media_dir/gif.new"; }
trap cleanup EXIT
cat <<'EOF'
↓ Exercise media is missing — downloading ~140 MB from github.com/hasaneyldrm/exercises-dataset
  Metadata and instruction text: MIT.
  Images and animations: © Gym visual — https://gymvisual.com/
  Used under that dataset's terms, not tamagym's AGPL; tamagym does not redistribute them.
  Terms: https://gymvisual.com/content/3-terms-and-conditions-of-use
  Reusing this media yourself, commercially or not, needs your own licence from Gym visual.
  Details in NOTICE.md.
EOF

if ! git clone --depth 1 https://github.com/hasaneyldrm/exercises-dataset "$tmp/dataset"; then
  echo "⚠ Could not download exercise media; Phoenix will continue and retry next start." >&2
  exit 0
fi

# Stage the complete download before touching the live catalogues. If the final copy is interrupted,
# the count check retries it next startup. Keep the tracked .gitkeep files in place.
rm -rf "$media_dir/img.new" "$media_dir/gif.new"
mkdir -p "$media_dir/img.new" "$media_dir/gif.new"
cp "$tmp"/dataset/images/*.jpg "$media_dir/img.new/"
cp "$tmp"/dataset/videos/*.gif "$media_dir/gif.new/"
find "$media_dir/img" -maxdepth 1 -type f -name '*.jpg' -delete
find "$media_dir/gif" -maxdepth 1 -type f -name '*.gif' -delete
cp "$media_dir"/img.new/*.jpg "$media_dir/img/"
cp "$media_dir"/gif.new/*.gif "$media_dir/gif/"
rm -rf "$media_dir/img.new" "$media_dir/gif.new"

img_count="$(find "$media_dir/img" -maxdepth 1 -type f -name '*.jpg' | wc -l)"
gif_count="$(find "$media_dir/gif" -maxdepth 1 -type f -name '*.gif' | wc -l)"
echo "✓ Exercise media ready (${img_count} images, ${gif_count} GIFs)"
