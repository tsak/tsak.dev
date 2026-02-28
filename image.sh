#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -le 2 ]; then
    echo "Usage: $0 <input_image> <output_image> <colours>"
    exit 1
fi

input="$1"
output="$2"
colours="$3"

# My go to image style for this blog, slightly reminiscent of the good old EGA days

if [[ $colours == "loop" ]]; then
  echo "Generating $output images from $input in for 2-16 colours, EGA and CGA palettes"
  # Colours
  for c in 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do
    p="c${c}"
    $0 "${input}" "${output/.png/_${p}.png}" ${c}
  done

  # EGA
  p="ega"
  $0 "${input}" "${output/.png/_${p}.png}" ega

  # CGA
  for c in 1h 1l 2h 2l 3; do
    p="cga${c}"
    $0 "${input}" "${output/.png/_${p}.png}" cga ${c}
  done

  # CGA
  exit 0
fi

echo "Generating $output from $input using $3 colours"

if [[ "$colours" == "ega" ]]; then
  magick "$input" \
      -resize 1920x \
      -gravity Center -crop 1920x1080+0+0 +repage \
      -filter Cubic -resize 25% -sharpen 0x1 \
      -dither FloydSteinberg -remap ./static/images/palettes/ega.png \
      -filter Point -resize 400% \
      "$output"
elif [[ "$colours" == "cga" ]]; then
  palette_image="cga_${4:-"1h"}.png"
  magick "$input" \
      -resize 1920x \
      -gravity Center -crop 1920x1080+0+0 +repage \
      -filter Cubic -resize 25% -sharpen 0x1 \
      -ordered-dither o2x2,4 -remap "./static/images/palettes/${palette_image}" \
      -filter Point -resize 400% \
      "$output"
else
  magick "$input" \
      -resize 1920x \
      -gravity Center -crop 1920x1080+0+0 +repage \
      -filter Cubic -resize 25% \
      -dither FloydSteinberg -colors "$colours" \
      -filter Point -resize 400% \
      "$output"
fi
