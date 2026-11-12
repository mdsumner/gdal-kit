#!/bin/sh
# Run gdalcaps inside gdal-r-ci images, mounting this checkout read-only.
#
#   examples/caps-in-image.sh [IMAGE...] [-- gdalcaps options]
#   examples/caps-in-image.sh                                   # gdal-system :latest and :dev
#   examples/caps-in-image.sh ghcr.io/hypertidy/gdal-r-python:dev -- --details
#
# Images: https://github.com/hypertidy/gdal-r-ci (they ship the GDAL Python
# bindings, so gdalcaps needs nothing extra; --details uses the driver map
# snapshot in share/gdal-kit since the images carry no GDAL source tree).
set -e
kit=$(cd "$(dirname "$0")/.." && pwd)
images=; opts=
while [ $# -gt 0 ]; do
  case $1 in --) shift; opts=$*; break ;; *) images="$images $1"; shift ;; esac
done
: "${images:=ghcr.io/hypertidy/gdal-system:latest ghcr.io/hypertidy/gdal-system:dev}"
for img in $images; do
  echo "### $img"
  docker run --rm -v "$kit":/kit:ro "$img" /kit/bin/gdalcaps $opts
  echo
done
