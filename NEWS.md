# rgeowheels 0.1.0

* Add automatic Python version detection with `pyversion = "auto"`
* Add `detect_python_version()` to extract Python version from binary
* Add `detect_python_envs()` to discover available Python environments
* Add message suppression for auto-detection via environment variable and R options
* Add improved error messages showing available Python versions
* Add comprehensive vignette for installing GDAL on Windows with reticulate integration
* Add `refresh_rgeowheels_cache()` for explicit cache updates
* Add informative GitHub API rate limit error messages with reset times
* Add smart retry logic with `httr::RETRY` for server errors only
* Add cache freshness checking with 1-hour result caching

# rgeowheels 0.0.5

* Rename `list_assets()` to `list_rgeowheels_assets()`

# rgeowheels 0.0.4

* Add basic tests for core functions

# rgeowheels 0.0.3

* Remove rvest dependency; use jsonlite and base R instead
* Consolidate R source files

# rgeowheels 0.0.2

* Add `get_rgeowheels_python()` and `set_rgeowheels_python()` for Python binary management

# rgeowheels 0.0.1

* Initial release
* Download and install wheels from geospatial-wheels repository
* `install_wheel()` function for downloading/installing wheels
* `list_assets()` function (renamed to `list_rgeowheels_assets()` in 0.0.5)
* Support for multiple architectures (win32, win_amd64, win_arm64)
