# List assets available from "geospatial-wheels" repository

List assets available from "geospatial-wheels" repository

## Usage

``` r
list_rgeowheels_assets(
  release = NULL,
  update_cache = FALSE,
  check_freshness = FALSE
)
```

## Arguments

- release:

  Specify custom release to list assets for. Default: `NULL`

- update_cache:

  Force update of wheel download index? Default: `FALSE`

- check_freshness:

  Check if cached data is from the latest release? Default: `FALSE`

## Value

A *data.frame* containing `package`, `version`, `pyversion`,
`architecture` and other metadata about each asset in a release.
