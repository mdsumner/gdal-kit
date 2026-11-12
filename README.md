# gdal-kit

Small command-line tools for getting a compact, at-a-glance view of GDAL
itself and of what it can read.

| tool | what it summarises |
|---|---|
| [`gdalcaps`](#gdalcaps) | the GDAL build: libraries, codecs, cloud/archive access, notable drivers |
| [`mdim-summary`](docs/mdim-summary.md) | a multidimensional dataset (netCDF, HDF5, Zarr, …) via `gdal mdim info` |

Both are thin presentation layers over what GDAL already exposes; GDAL's own
JSON stays the contract.

## Install

```sh
git clone https://github.com/mdsumner/gdal-kit
cd gdal-kit
make install                     # to ~/.local/bin and ~/.local/share/gdal-kit
make install PREFIX=/usr/local   # or anywhere else
make uninstall
```

Requirements: GDAL 3.10+ with the `gdal` CLI; the GDAL Python bindings
(`from osgeo import gdal`) for `gdalcaps`; `jq` 1.6+ for `mdim-summary`.
Nothing is pip-installed: the tools use whatever GDAL is on the machine,
which is the point.

## gdalcaps

```
$ gdalcaps
GDAL 3.14.0dev-9bb42f5a7b

  libs      proj 9.9.0 · geos 3.12.1 · curl 8.5.0
  drivers   216 total · 152 raster · 80 vector · 14 mdim · 108 writable

  tiff      NONE LZW PACKBITS JPEG CCITTRLE CCITTFAX3 CCITTFAX4 DEFLATE LZMA ZSTD WEBP LERC
            LERC_DEFLATE LERC_ZSTD JXL
  zarr      blosc zlib gzip lzma zstd lz4 + pcodec

  cloud     s3 gs az adls oss swift webhdfs curl
  archive   zip tar gzip 7z rar
  refs      icechunk · kerchunk (json, json cached, parquet) · pmtiles
```

`--details` adds the drivers that exist only because an optional library was
found at build time, grouped by that library — the "what did my build gain"
view, without the long tail of always-built formats:

```
drivers from optional libraries (28; * = writable)
  arrow       Arrow*
  cfitsio     FITS*
  hdf5        BAG*  HDF5  HDF5Image  S102*  S104*  S111*
  jxl         JPEGXL*
  poppler     PDF*
  postgresql  PostGISRaster*  PostgreSQL*
  xercesc     GMLAS*  Interlis 1  Interlis 2  NAS
  zstd        Icechunk
  ...
```

| flag | |
|---|---|
| `--details` | drivers gated on an optional (non-ubiquitous) library |
| `--all` | also the remaining drivers, grouped multidim / raster / vector |
| `--json` | same content as JSON; combine with the flags above |
| `--write-snapshot` | refresh the shipped driver map from a source tree (`make snapshot`) |

Where the information comes from:

- version, libraries, drivers, codecs and `/vsi*` handlers: the GDAL Python
  bindings at run time;
- which library each driver needs (`--details`): GDAL's source tree declares
  it (`gdal_dependent_format(heif "HEIF" "GDAL_USE_HEIF")`). gdalcaps reads
  `$GDAL_SRC` (default `~/gdal`) when present, else the snapshot shipped in
  `share/gdal-kit/driver-libs.json` — so `--details` works in containers and
  on machines without a GDAL checkout. With a build tree (`$GDAL_BUILD`,
  default `$GDAL_SRC/build`) its `CMakeCache.txt` also tells external
  libraries from GDAL's vendored copies.

Drivers whose only dependencies are near-universal (curl, sqlite3, expat,
tiff, jpeg, png, …) or vendored are left to `--all`.

## Examples with gdal-r-ci images

The [gdal-r-ci](https://github.com/hypertidy/gdal-r-ci) images
(`ghcr.io/hypertidy/gdal-system`, `gdal-r`, `gdal-r-python`, … in `:latest`
release and `:dev` GDAL-HEAD channels) ship the GDAL Python bindings, so the
tools run in them straight from a read-only mount of this checkout:

```sh
# summary inside one or more images (default: gdal-system :latest and :dev)
examples/caps-in-image.sh
examples/caps-in-image.sh ghcr.io/hypertidy/gdal-r-python:dev -- --details

# what does one GDAL have that the other lacks? ("host" = this machine)
examples/caps-diff.sh host ghcr.io/hypertidy/gdal-system:dev
examples/caps-diff.sh ghcr.io/hypertidy/gdal-system:latest ghcr.io/hypertidy/gdal-system:dev

# summarise a dataset with an image's GDAL (formatting runs on the host)
examples/mdim-in-image.sh ghcr.io/hypertidy/gdal-system:dev data/ocean.nc
```

`caps-diff.sh` prints one fact per line, only-in-A (`<`) and only-in-B (`>`):

```
< host  (GDAL 3.14.0dev-9bb42f5a7b-dirty)
> ghcr.io/hypertidy/gdal-system:dev  (GDAL 3.14.0dev-8b3b63fb30)
< archive   7z
< driver    JPEGXL  [jxl]
< tiff      JXL
> driver    KEA  [kea, hdf5]
> lib       geos 3.15.0
...
```

The bare equivalents, if you'd rather type them:

```sh
docker run --rm -v "$PWD":/kit:ro ghcr.io/hypertidy/gdal-system:dev /kit/bin/gdalcaps --details
docker run --rm -v "$PWD/data":/data:ro ghcr.io/hypertidy/gdal-system:dev \
  gdal mdim info --format=json /data/ocean.nc | bin/mdim-summary -
```

## mdim-summary

```
$ mdim-summary /vsicurl/https://thredds.nci.org.au/thredds/fileServer/gb6/BRAN/BRAN2023/daily/ocean_temp_2010_01.nc
<gdal.mdim: /> (netCDF/NETCDF4)

Dimensions:
  /xt_ocean        3600  HORIZONTAL_X
  /yt_ocean        1500  HORIZONTAL_Y
  /st_ocean        51    VERTICAL DOWN
  /Time            31    TEMPORAL
  ...
Data variables:
  (Time, st_ocean, yt_ocean, xt_ocean [31,51,1500,3600]):
    /temp        Int16    degrees C  [packed: scale=0.0077822 offset=245]  chunks=[1,1,300,300]
```

Full description, examples and comparisons: [docs/mdim-summary.md](docs/mdim-summary.md).
Originally published as
[mdsumner/gdal-mdim-summary](https://github.com/mdsumner/gdal-mdim-summary).

## License

MIT. See `LICENSE`.
