
<!-- This file is read-only. README.md is generated from README.Rmd. Please edit README.Rmd and render with rmarkdown::render() -->

# {rgeowheels}

<!-- badges: start -->

[![R-CMD-check](https://github.com/brownag/rgeowheels/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/brownag/rgeowheels/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Downloads pre-compiled Windows ‘wheel’ files (.whl) for Python
geospatial packages from <https://github.com/cgohlke/geospatial-wheels>.
These are unofficial binary installers for some Python geospatial
libraries on Windows prepared by Christoph Gohlke. Wheels for various
packages, Python versions, and architectures are made available via
GitHub releases, providing the ability to revert to prior versions when
needed.

**Key Features:**

- **Automatic Python Version Detection**: Use `pyversion = "auto"` to
  automatically detect and match your Python version
- **Virtual Environment Support**: Works seamlessly with Python virtual
  environments and conda environments
- **Environment Discovery**: Discover available Python environments with
  `detect_python_envs()`
- **CI/CD Friendly**: Perfect for GitHub Actions and other CI workflows
  on Windows
- **Simplified Installation**: Install complex geospatial libraries in
  seconds

## Installation

You can install the development version of {rgeowheels} like so:

``` r
# install.packages("remotes")
remotes::install_github("brownag/rgeowheels")
```

## Quick Start

The simplest way to install a wheel is to use automatic Python version
detection:

``` r
library(rgeowheels)

# Auto-detect Python version and install GDAL
install_wheel("GDAL", pyversion = "auto")
#> Display a message: "Auto-selected Python 3.11 for GDAL"
```

For more details, see the vignette:
`vignette("installing-gdal-windows")`

## Examples

### List available packages and versions

``` r
library(rgeowheels)
#> rgeowheels 0.1.0
#>  - Latest cached release: 2025-10-26
#>  <https://github.com/cgohlke/geospatial-wheels/releases/tag/v2025.10.25>

# See all available wheels
assets <- list_rgeowheels_assets()

# Filter for specific package
gdal_wheels <- subset(assets, package == "gdal")
head(gdal_wheels[, c("package", "version", "pyversion", "architecture")])
#>    package version pyversion architecture
#> 61    gdal  3.11.4      3.11        win32
#> 62    gdal  3.11.4      3.11    win_amd64
#> 63    gdal  3.11.4      3.11    win_arm64
#> 64    gdal  3.11.4      3.12        win32
#> 65    gdal  3.11.4      3.12    win_amd64
#> 66    gdal  3.11.4      3.12    win_arm64
```

# Get URL to Wheel File

``` r
# Auto-detect your Python version and return URL
install_wheel("gdal", pyversion = "auto", url_only = TRUE)
#> Auto-selected Python 3.12 for gdal
#> [1] "https://github.com/cgohlke/geospatial-wheels/releases/download/v2025.10.25/gdal-3.11.4-cp312-cp312-win_amd64.whl"
```

### Install with automatic Python version detection

``` r
# Auto-detect your Python version and install
install_wheel("gdal", pyversion = "auto")

# Suppress the info message
Sys.setenv(R_RGEOWHEELS_QUIET_AUTO = "TRUE")
install_wheel("rasterio", pyversion = "auto")

# Or specify Python explicitly (suppresses message)
install_wheel("fiona", pyversion = "3.11")
```

### Discover available Python environments

``` r
# Find available Python environments
detect_python_envs()
#>          type            path version active
#> python system /usr/bin/python    3.12   TRUE
```

### Install with specific versions

``` r
# Latest version of GDAL, latest cpython, available for win_amd64 architecture
install_wheel("GDAL", url_only = TRUE)

# Specific GDAL version for Python 3.10
install_wheel("rasterio", version = "1.3.4", pyversion = "3.10", url_only = TRUE)

# Most recent version of rasterio for Python 3.8
install_wheel("rasterio", pyversion = "3.8", url_only = TRUE)
```

### Use with reticulate

``` r
library(reticulate)
library(rgeowheels)

# Create and activate a virtual environment
venv_path <- file.path(getwd(), ".venv")
virtualenv_create(venv_path, python = Sys.which("python"))
use_virtualenv(venv_path)

# Install geospatial packages
install_wheel("GDAL", pyversion = "auto")
install_wheel("rasterio", pyversion = "auto")

# Verify installation
py_run_string("import gdal; print(f'GDAL {gdal.__version__}')")
```
