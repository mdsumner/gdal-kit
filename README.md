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
make install                 # to ~/.local/bin and ~/.local/share/gdal-kit
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
GDAL 3.14.0dev-9bb42f5a7b   curl 8.5.0  geos 3.12.1-CAPI-1.18.1  proj 9.9.0
drivers  216 (152 raster, 80 vector, 14 mdim; 108 writable)
tiff     NONE LZW PACKBITS JPEG CCITTRLE CCITTFAX3 CCITTFAX4 DEFLATE LZMA ZSTD WEBP LERC LERC_DEFLATE LERC_ZSTD JXL
zarr     blosc zlib gzip lzma zstd lz4 +pcodec
cloud    adls az curl gs oss s3 swift webhdfs
archive  7z gzip rar tar zip
refs     icechunk kerchunk_json_ref kerchunk_json_ref_cached kerchunk_parquet_ref pmtiles
```

`--details` adds the drivers that exist only because an optional library was
found at build time, with the library named — the "what did my build gain"
view, without the long tail of always-built formats:

```
from optional libraries (29; M=mdim R=raster V=vector, * writable):
  M Icechunk         zstd
  M netCDF*          netcdf
  R FITS*            cfitsio
  R JPEGXL*          jxl
  R PDF*             poppler
  R PostGISRaster*   postgresql
  V Parquet*         parquet
  V XLS              freexl
  ...
```

| flag | |
|---|---|
| `--details` | drivers gated on an optional (non-ubiquitous) library |
| `--all` | also the remaining drivers, grouped mdim / raster / vector |
| `--json` | same content as JSON; combine with the flags above |

Where the information comes from:

- version, libraries, drivers, codecs and `/vsi*` handlers: the GDAL Python
  bindings at run time;
- which library each driver needs (`--details`): GDAL's source tree, which
  declares it (`gdal_dependent_format(heif "HEIF" "GDAL_USE_HEIF")`), plus the
  build's `CMakeCache.txt` to tell external libraries from GDAL's vendored
  copies. Point at them with `GDAL_SRC` (default `~/gdal`) and `GDAL_BUILD`
  (default `$GDAL_SRC/build`). Without a source tree the summary still works
  and `--details` says what is missing.

Drivers whose only dependencies are near-universal (curl, sqlite3, expat,
tiff, jpeg, png, …) or vendored are left to `--all`.

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
