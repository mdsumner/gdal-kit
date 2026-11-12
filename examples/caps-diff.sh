#!/bin/sh
# What does one GDAL have that another lacks? Compares gdalcaps between two
# targets, each either "host" (the GDAL on this machine) or a docker image.
#
#   examples/caps-diff.sh A B
#   examples/caps-diff.sh host ghcr.io/hypertidy/gdal-system:dev
#   examples/caps-diff.sh ghcr.io/hypertidy/gdal-system:latest ghcr.io/hypertidy/gdal-system:dev
#
# Needs jq on the host. Prints items only in A ("<") and only in B (">").
set -e
[ $# -eq 2 ] || { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
kit=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

caps() {
  if [ "$1" = host ]; then "$kit/bin/gdalcaps" --json --all
  else docker run --rm -v "$kit":/kit:ro "$1" /kit/bin/gdalcaps --json --all; fi
}
# one comparable fact per line
flat='(.libs | to_entries[] | "lib       \(.key) \(.value | split("-")[0])"),
      (.tiff_compress[] | "tiff      \(.)"),
      (.zarr // {} | (.compressors[]? | "zarr      \(.)"), (if .pcodec then "zarr      pcodec" else empty end)),
      (.cloud[] | "cloud     \(.)"), (.archives[] | "archive   \(.)"), (.refs[] | "refs      \(.)"),
      (.optional_lib_drivers[]? | "driver    \(.name)  [\(.libs | join(", "))]"),
      (.other_drivers[]? | "driver    \(.name)")'

caps "$1" > "$tmp/a.json"; caps "$2" > "$tmp/b.json"
echo "< $1  (GDAL $(jq -r .gdal "$tmp/a.json"))"
echo "> $2  (GDAL $(jq -r .gdal "$tmp/b.json"))"
jq -r "$flat" "$tmp/a.json" | sort -u > "$tmp/a"
jq -r "$flat" "$tmp/b.json" | sort -u > "$tmp/b"
comm -23 "$tmp/a" "$tmp/b" | sed 's/^/< /'
comm -13 "$tmp/a" "$tmp/b" | sed 's/^/> /'
