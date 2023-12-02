
<!-- README.md is generated from README.Rmd. Please edit that file -->

# {rgeowheels}

<!-- badges: start -->
<!-- badges: end -->

Downloads pre-compiled Windows ‘wheel’ files (.whl) for Python
geospatial packages from <https://github.com/cgohlke/geospatial-wheels>.
These are unofficial binary installers for some Python geospatial
libraries on Windows prepared by Christoph Gohlke. Wheels for various
packages, Python versions, and architectures are made available via
GitHub releases, providing the ability to revert to prior versions when
needed.

## Installation

You can install the development version of {rgeowheels} like so:

``` r
# install.packages("remotes")
remotes::install_github("brownag/rgeowheels")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(rgeowheels)
#> rgeowheels 0.0.1
#> Latest cached release: 2023-11-03
#>  <https://github.com/cgohlke/geospatial-wheels/releases/tag/v2023.11.3>

if (Sys.info()["sysname"] == "Windows")
  install_wheel("GDAL")

install_wheel("rasterio", pyversion = "3.8", url_only = TRUE)
#> Loading required namespace: rvest
#> [1] "https://github.com/cgohlke/geospatial-wheels/releases/download/v2023.1.10.1/rasterio-1.3.4-cp38-cp38-win_amd64.whl"
```
