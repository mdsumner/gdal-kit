#!/bin/sh
# Summarise a multidimensional dataset with the GDAL inside an image:
# `gdal mdim info` runs in the container, formatting happens on the host
# (the images don't ship jq). Local files are mounted read-only; URLs and
# /vsi paths are passed through.
#
#   examples/mdim-in-image.sh IMAGE FILE|URL
#   examples/mdim-in-image.sh ghcr.io/hypertidy/gdal-system:dev data/ocean.nc
#   examples/mdim-in-image.sh ghcr.io/hypertidy/gdal-system:latest \
#     /vsicurl/https://thredds.nci.org.au/thredds/fileServer/gb6/BRAN/BRAN2023/daily/ocean_temp_2010_01.nc
set -e
[ $# -eq 2 ] || { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
kit=$(cd "$(dirname "$0")/.." && pwd)
img=$1; src=$2; mount=
if [ -e "$src" ]; then
  dir=$(cd "$(dirname "$src")" && pwd)
  mount="-v $dir:/data:ro"; src=/data/$(basename "$src")
fi
docker run --rm $mount "$img" sh -c '
  if gdal mdim info --help 2>&1 | grep -q OUTPUT-FORMAT; then gdal mdim info --format=json "$1"
  else gdal mdim info "$1"; fi' sh "$src" \
  | "$kit/bin/mdim-summary" -
