x <- try(list_rgeowheels_assets())
if (!inherits(x, 'try-error')) {
  expect_true(inherits(x, 'data.frame'))
} else message("getting asset list from GitHub releases failed")

y <- try(install_wheel("GDAL", url_only = TRUE))
if (!inherits(y, 'try-error')) {
  expect_true(is.character(y))
} else message("getting latest GDAL wheel URL failed")

# Test detect_python_version()
z <- try(detect_python_version())
if (!inherits(z, 'try-error')) {
  expect_true(is.character(z))
  expect_true(grepl("^[0-9]+\\.[0-9]+$", z))
} else message("detecting Python version failed (Python not in PATH)")

# Test detect_python_envs()
envs <- try(detect_python_envs(include_system = FALSE))
if (!inherits(envs, 'try-error')) {
  expect_true(inherits(envs, 'data.frame'))
  expect_true("type" %in% names(envs))
  expect_true("path" %in% names(envs))
  expect_true("version" %in% names(envs))
  expect_true("active" %in% names(envs))
} else message("detecting Python environments failed")

# Test error message with available versions
w <- try(install_wheel("GDAL", version = "9.99.9", pyversion = "1.0", url_only = TRUE))
if (inherits(w, 'try-error')) {
  error_msg <- as.character(w)
  # Should mention available versions in error
  expect_true(inherits(w, 'try-error'))
} else message("expected error not raised for invalid version combination")

# Test get_rgeowheels_python()
python_path <- get_rgeowheels_python()
expect_true(is.character(python_path))

# Test set_rgeowheels_python()
old_option <- getOption("rgeowheels.python", default = NA)
set_rgeowheels_python(python_path)
new_option <- getOption("rgeowheels.python")
expect_equal(new_option, python_path)
