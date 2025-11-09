# rgeowheels: Pre-compiled Python Geospatial Wheels for Windows

Access and install pre-compiled Python geospatial wheels from Christoph
Gohlke's repository. Automatically detects Python versions and
simplifies installation of complex packages like GDAL on Windows.

## Main Functions

- [`install_wheel()`](http://humus.rocks/rgeowheels/reference/install_wheel.md):
  Download and install wheels with automatic Python version detection

- [`list_rgeowheels_assets()`](http://humus.rocks/rgeowheels/reference/list_rgeowheels_assets.md):
  List available wheels from geospatial-wheels repository

- [`detect_python_version()`](http://humus.rocks/rgeowheels/reference/detect_python_version.md):
  Extract Python version from a binary

- [`detect_python_envs()`](http://humus.rocks/rgeowheels/reference/detect_python_envs.md):
  Discover available Python environments (venv/conda/system)

- [`get_rgeowheels_python()`](http://humus.rocks/rgeowheels/reference/rgeowheels_python.md)
  /
  [`set_rgeowheels_python()`](http://humus.rocks/rgeowheels/reference/rgeowheels_python.md):
  Manage Python binary path

## Auto-Detection Features

Use `pyversion = "auto"` in
[`install_wheel()`](http://humus.rocks/rgeowheels/reference/install_wheel.md)
to automatically detect and match the current Python version. Suppress
informational messages with:

- Environment variable: `Sys.setenv(R_RGEOWHEELS_QUIET_AUTO = "TRUE")`

- R option: `options(rgeowheels.quiet_auto = TRUE)`

- Explicit version specification: `pyversion = "3.11"`

## Virtual Environment Support

Full support for Python virtual environments and conda environments. Use
[`detect_python_envs()`](http://humus.rocks/rgeowheels/reference/detect_python_envs.md)
to discover environments, then activate with reticulate:

    library(reticulate)
    use_virtualenv(".venv")
    install_wheel("GDAL", pyversion = "auto")

## See also

Useful links:

- <https://github.com/brownag/rgeowheels>

- <https://humus.rocks/rgeowheels/>

- Report bugs at <https://github.com/brownag/rgeowheels/issues>
