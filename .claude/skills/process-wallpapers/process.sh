#!/bin/zsh
# Crop to 21:9, resize and apply the repo's standard vignette.
# usage: process.sh [--no-vignette] [--force] <src> <dst> [yoffset]
#   yoffset: vertical crop position, 0 = keep top, 0.5 = center, 1 = keep bottom
#   --no-vignette: only crop/resize (for images that already have the vignette)
#   --force: allow overwriting an existing dst (e.g. reprocessing a tracked file in place)
set -e
vignette=1; force=0
while [[ $1 == --* ]]; do
  case $1 in
    --no-vignette) vignette=0 ;;
    --force) force=1 ;;
    *) echo "unknown option $1" >&2; exit 1 ;;
  esac; shift
done
src=$1; dst=$2; off=${3:-0.5}
[ -e "$dst" ] && (( ! force )) && { echo "refusing to overwrite $dst (use --force)" >&2; exit 1; }
tmp="${dst:r}.tmp.$$.${dst:e}"

W=$(magick identify -format %w "$src"); H=$(magick identify -format %h "$src")

# Largest 3440:1440 (21:9) crop that fits
CH=$(( W * 1440 / 3440 )); CW=$W
if (( CH > H )); then CH=$H; CW=$(( H * 3440 / 1440 )); fi
Y=$(printf "%.0f" $(( (H - CH) * off )))
X=$(( (W - CW) / 2 ))

# Nothing to gain from re-encoding an image that's already 21:9 when no vignette is wanted
if (( ! vignette && CW == W && CH == H )); then
  echo "$src: already 21:9 (${W}x${H}), skipped"
  [ "$src" != "$dst" ] && cp "$src" "$dst"
  exit 0
fi

# Keep native resolution, clamped to height 1440..2160
TH=$CH; (( TH > 2160 )) && TH=2160; (( TH < 1440 )) && TH=1440
TW=$(( TH * 3440 / 1440 ))

# Vignette mask built small and upscaled (fx at full res is slow):
#   top: 50% brightness at the top edge, easing to 100% at 30% of the height
#   radial: ~13% darker at the side/bottom edges, ~26% in the corners
MW=$(( TW / 8 )); MH=$(( TH / 8 ))
if (( vignette )); then
magick "$src" -auto-orient -crop ${CW}x${CH}+${X}+${Y} +repage -resize ${TW}x${TH}! \
  \( -size ${MW}x${MH} xc: -fx "vt=min(1,j/(0.3*h)); vx=(i/w-0.5)*2; vy=(j/h-0.5)*2; (0.5+0.5*(1-(1-vt)^2))*(1-0.13*(vx*vx+vy*vy))" -resize ${TW}x${TH}! \) \
  -compose multiply -composite -quality 92 -strip "$tmp"
else
magick "$src" -auto-orient -crop ${CW}x${CH}+${X}+${Y} +repage -resize ${TW}x${TH}! -quality 92 -strip "$tmp"
fi
mv "$tmp" "$dst"
echo "$dst: ${TW}x${TH} (crop ${CW}x${CH}+${X}+${Y})$( (( vignette )) || echo ', no vignette')"
