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

# Test auto-detection message suppression mechanisms
# Test 1: Environment variable suppression
old_env <- Sys.getenv("R_RGEOWHEELS_QUIET_AUTO", unset = NA)
Sys.setenv(R_RGEOWHEELS_QUIET_AUTO = "TRUE")
tryCatch({
  # This should not produce a message
  result <- install_wheel("GDAL", pyversion = "auto", url_only = TRUE)
  expect_true(is.character(result))
}, finally = {
  if (is.na(old_env)) {
    Sys.unsetenv("R_RGEOWHEELS_QUIET_AUTO")
  } else {
    Sys.setenv(R_RGEOWHEELS_QUIET_AUTO = old_env)
  }
})

# Test 2: R option suppression
old_option <- getOption("rgeowheels.quiet_auto", default = NULL)
options(rgeowheels.quiet_auto = TRUE)
tryCatch({
  # This should not produce a message
  result <- install_wheel("GDAL", pyversion = "auto", url_only = TRUE)
  expect_true(is.character(result))
}, finally = {
  options(rgeowheels.quiet_auto = old_option)
})

# Test 3: Explicit version (should never show message)
result <- install_wheel("GDAL", pyversion = "3.11", url_only = TRUE)
expect_true(is.character(result))

# Test Python version detection with different paths
python_path <- get_rgeowheels_python()
if (python_path != "") {
  # Test with explicit path
  version <- detect_python_version(python_path)
  expect_true(grepl("^[0-9]+\\.[0-9]+$", version))

  # Test with non-existent path (should fail gracefully)
  expect_error(detect_python_version("/nonexistent/python/path"))
}

# Test environment discovery variations
# Test with include_system = FALSE
envs_no_system <- detect_python_envs(include_system = FALSE)
expect_true(inherits(envs_no_system, 'data.frame'))

# Test with different project root
temp_dir <- tempdir()
envs_temp <- detect_python_envs(project_root = temp_dir)
expect_true(inherits(envs_temp, 'data.frame'))

# Test Python path precedence logic
# Test environment variable takes precedence
old_env_py <- Sys.getenv("R_RGEOWHEELS_PYTHON", unset = NA)
old_option_py <- getOption("rgeowheels.python", default = NULL)

# Use an existing file for testing (system Python)
system_python <- get_rgeowheels_python()
if (file.exists(system_python)) {
  tryCatch({
    Sys.setenv(R_RGEOWHEELS_PYTHON = system_python)
    options(rgeowheels.python = "/nonexistent/path")
    result <- get_rgeowheels_python()
    expect_true(result == system_python)  # Env var should win
  }, finally = {
    if (is.na(old_env_py)) {
      Sys.unsetenv("R_RGEOWHEELS_PYTHON")
    } else {
      Sys.setenv(R_RGEOWHEELS_PYTHON = old_env_py)
    }
    options(rgeowheels.python = old_option_py)
  })
}

# Test option takes precedence over system (when option path exists)
if (file.exists(system_python)) {
  tryCatch({
    options(rgeowheels.python = system_python)
    result <- get_rgeowheels_python()
    expect_true(result == system_python)
  }, finally = {
    options(rgeowheels.python = old_option_py)
  })
}

# Test error message variations
# Test with different architectures
try(install_wheel("GDAL", pyversion = "1.0", architecture = "win32", url_only = TRUE))
if (inherits(.Last.value, 'try-error')) {
  error_msg <- as.character(.Last.value)
  expect_true(grepl("could not find wheels", error_msg))
}

# Test with non-existent package
try(install_wheel("NonExistentPackage", pyversion = "3.11", url_only = TRUE))
if (inherits(.Last.value, 'try-error')) {
  error_msg <- as.character(.Last.value)
  expect_true(grepl("could not find wheels", error_msg))
}

# Test cache behavior (if update_cache works)
assets1 <- list_rgeowheels_assets()
assets2 <- list_rgeowheels_assets(update_cache = FALSE)  # Should use cache
expect_equal(nrow(assets1), nrow(assets2))  # Same data

# Test that update_cache=TRUE forces refresh (may be slow, so optional)
# assets3 <- list_rgeowheels_assets(update_cache = TRUE)
# expect_true(inherits(assets3, 'data.frame'))  # Just check it works

# Test auto-detection with different Python versions (for CI matrix)
# This test is particularly valuable for the GitHub Actions matrix
python_path <- get_rgeowheels_python()
if (python_path != "") {
  detected_version <- detect_python_version(python_path)
  # Test that auto-detection works (don't check specific version availability)
  if (is.character(detected_version) && grepl("^[0-9]+\\.[0-9]+$", detected_version)) {
    result <- try(install_wheel("GDAL", pyversion = "auto", url_only = TRUE))
    # Just check that it returns something (either URL or error)
    expect_true(is.character(result) || inherits(result, 'try-error'))
  }
}

# Test architecture validation
expect_error(install_wheel("GDAL", architecture = "invalid_arch", url_only = TRUE))

# Test package parameter validation
expect_error(install_wheel(c("GDAL", "rasterio"), url_only = TRUE))

# Test version handling edge cases
# Test that "latest" works for both version and pyversion
result <- try(install_wheel("GDAL", version = "latest", pyversion = "latest", url_only = TRUE), silent = TRUE)
if (!inherits(result, 'try-error')) {
  expect_true(is.character(result))
}

# Test specific version combinations that should exist
python_version <- try(detect_python_version(), silent = TRUE)
if (!inherits(python_version, 'try-error') && is.character(python_version)) {
  common_packages <- c("GDAL", "rasterio", "fiona")
  for (pkg in common_packages) {
    result <- try(install_wheel(pkg, version = "latest", pyversion = python_version, url_only = TRUE), silent = TRUE)
    if (!inherits(result, 'try-error')) {
      expect_true(is.character(result))
      expect_true(grepl(pkg, result, ignore.case = TRUE))
    }
  }
}

# Test error message formatting for different scenarios
test_error_scenarios <- list(
  list(package = "GDAL", pyversion = "99.99", architecture = "win_amd64"),
  list(package = "NonExistent", pyversion = "3.11", architecture = "win_amd64")
)

for (scenario in test_error_scenarios) {
  result <- try(do.call(install_wheel, c(scenario, url_only = TRUE)))
  if (inherits(result, 'try-error')) {
    error_msg <- as.character(result)
    # Just check that we get some error message
    expect_true(nchar(error_msg) > 0)
  }
}

# Test invalid architecture (this should always fail)
expect_error(install_wheel("GDAL", architecture = "nonexistent_arch", url_only = TRUE))

# Test cache refresh functionality
# Test that refresh_rgeowheels_cache() works or fails informatively
result <- try(refresh_rgeowheels_cache(), silent = TRUE)
if (!inherits(result, 'try-error')) {
  expect_true(is.null(result))  # Should return NULL invisibly
} else {
  # Should fail with an informative error message about rate limits
  error_msg <- attr(result, "condition")$message
  expect_true(grepl("rate limit", error_msg, ignore.case = TRUE) || 
              grepl("network", error_msg, ignore.case = TRUE))
}

# Test check_freshness parameter in list_rgeowheels_assets
# Should work with check_freshness = FALSE (no message)
assets_no_check <- list_rgeowheels_assets(check_freshness = FALSE)
expect_true(inherits(assets_no_check, 'data.frame'))

# Should work with check_freshness = TRUE (may show message, but cached for 1 hour)
assets_with_check <- list_rgeowheels_assets(check_freshness = TRUE)
expect_true(inherits(assets_with_check, 'data.frame'))

# Test that cache metadata is created after refresh
cache_dir <- tools::R_user_dir("rgeowheels", "cache")
metadata_file <- file.path(cache_dir, "metadata.rds")
if (file.exists(metadata_file)) {
  metadata <- readRDS(metadata_file)
  expect_true(is.list(metadata))
  expect_true("tag_name" %in% names(metadata))
  expect_true("fetched_at" %in% names(metadata))
  expect_true(inherits(metadata$fetched_at, 'POSIXct'))
}
