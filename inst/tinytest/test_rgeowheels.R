x <- try(list_rgeowheels_assets())
if (!inherits(x, 'try-error')) {
  expect_true(inherits(x, 'data.frame'))
} else message("getting asset list from GitHub releases failed")

y <- try(install_wheel("GDAL", url_only = TRUE))
if (!inherits(y, 'try-error')) {
  expect_true(is.character(y))
} else message("getting latest GDAL wheel URL failed")
