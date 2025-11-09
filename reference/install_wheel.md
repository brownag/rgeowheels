# Install Python Wheels From 'geospatial-wheels' Repository

Install Python Wheels From 'geospatial-wheels' Repository

## Usage

``` r
install_wheel(
  package,
  version = "latest",
  pyversion = "latest",
  architecture = "win_amd64",
  python = get_rgeowheels_python(),
  destdir = tempdir(),
  url_only = FALSE,
  download_only = FALSE
)
```

## Arguments

- package:

  Python package name to install. e.g. `"rasterio"`

- version:

  Python package version to install. Default `"latest"` determines
  latest version available from asset list (considers `pyversion` if
  set).

- pyversion:

  Python version to install package for. Default `"latest"` determines
  latest version available from asset list. Use `"auto"` to detect the
  Python version from the specified Python binary.

- architecture:

  Target architecture for the wheel to install. Default `"win_amd64"`,
  alternatives include `"win_arm64"` and `"win32"`.

- python:

  Path to Python executable to use for install. Default:
  [`get_rgeowheels_python()`](http://humus.rocks/rgeowheels/reference/rgeowheels_python.md)

- destdir:

  Destination directory for downloaded wheel file. Default:
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html)

- url_only:

  Return the URL of the .whl file without downloading? Default: `FALSE`

- download_only:

  Download .whl file without attempting install? Default: `FALSE`

## Value

Called for side effects (download and install a Python wheel). Returns
*character* containing path to .whl file when `url_only=TRUE` or
`download_only=TRUE`.
