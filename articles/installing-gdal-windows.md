# Installing GDAL on Windows with rgeowheels

## Overview

Installing geospatial Python packages on Windows can be challenging due
to complex binary dependencies and the need for pre-compiled wheels. The
**rgeowheels** package dramatically simplifies this process by providing
convenient access to Christoph Gohlke’s curated collection of
pre-compiled geospatial wheels, especially for GDAL and related
libraries.

**Note:** This vignette demonstrates Windows-specific workflows. The
code examples will only execute successfully on Windows systems, as
rgeowheels provides pre-compiled wheels specifically for Windows
architectures (win32, win_amd64, win_arm64).

This vignette demonstrates how to:

1.  Create and activate a virtual environment for Python development
2.  Detect available Python versions in your environment
3.  Use rgeowheels to install geospatial wheels (like GDAL) into that
    environment
4.  Verify the installation works with reticulate

This workflow is particularly useful for:

- **Continuous Integration (CI) workflows** where you need reproducible
  Python environments
- **Reticulate-based R packages** that require specific geospatial
  dependencies
- **Development workflows** where you want isolated Python environments
  per project

## Getting Started: Creating a Virtual Environment

The recommended approach is to create a dedicated Python virtual
environment for your project. This isolates your project dependencies
from system Python and other projects.

### Using reticulate to Create a Venv

If you already have Python installed, you can create a virtual
environment directly in R using **reticulate**:

``` r
library(reticulate)

# Create a virtual environment in your project directory
venv_path <- file.path(getwd(), ".venv")
virtualenv_create(venv_path, python = Sys.which("python"))

# Activate the virtual environment
use_virtualenv(venv_path, required = TRUE)
```

Alternatively, create the venv from the command line:

``` bash
# Windows Command Prompt
python -m venv .venv
.venv\Scripts\activate.bat

# Or PowerShell
python -m venv .venv
.venv\Scripts\Activate.ps1

# Or using conda
conda create -n myenv python=3.11
conda activate myenv
```

## Detecting Available Python Versions

Before installing wheels, it’s helpful to understand what Python
environments are available. The
[`detect_python_envs()`](http://humus.rocks/rgeowheels/reference/detect_python_envs.md)
function scans your system for virtual environments and conda
environments:

``` r
library(rgeowheels)
#> rgeowheels 0.1.0
#>  - Cached release asset list not found, run `list_rgeowheels_assets()` to begin.

# Discover available Python environments
envs <- detect_python_envs()
envs
#>          type                                                    path version
#> python system C:\\HOSTED~1\\windows\\Python\\314~1.0\\x64\\python.exe    3.14
#>        active
#> python   TRUE
```

You can also check the Python version of a specific environment:

``` r
# Get the version of the currently active Python
current_version <- detect_python_version()
current_version

# Or check a specific Python binary (wrapped in try to handle venv if not present)
venv_python <- file.path(".venv", "Scripts", "python.exe")  # Windows
if (file.exists(venv_python)) {
  venv_version <- detect_python_version(venv_python)
  venv_version
}
```

## Installing GDAL via rgeowheels

Once you have a Python environment set up and activated, installing GDAL
is straightforward:

### Basic Installation (Auto-Detect Python Version)

The simplest approach is to use `pyversion = "auto"` to automatically
detect your Python version and match it to available wheels:

``` r
library(rgeowheels)
library(reticulate)

# Ensure your virtual environment is active
use_virtualenv(".venv", required = TRUE)

# Install GDAL - automatically detects Python version
install_wheel("GDAL", version = "latest", pyversion = "auto")
```

This will:

1.  Detect your active Python version (e.g., “3.11”)
2.  Display a message: `"Auto-selected Python 3.11 for GDAL"`
3.  Find and download the matching GDAL wheel
4.  Install it via `pip`

### Suppressing the Auto-Detect Message

If you want to use auto-detection but suppress the informational message
(useful in scripts or CI), you have three options:

**Option 1: Set an environment variable**

``` r
Sys.setenv(R_RGEOWHEELS_QUIET_AUTO = "TRUE")
install_wheel("GDAL", pyversion = "auto")
```

**Option 2: Set an R option**

``` r
options(rgeowheels.quiet_auto = TRUE)
install_wheel("GDAL", pyversion = "auto")
```

**Option 3: Explicitly specify the Python version**

``` r
# Once you know the version, you can pin it explicitly (message is suppressed)
install_wheel("GDAL", pyversion = "3.11")
```

### Explicit Version Specification

If you need a specific version of GDAL for a specific Python version:

``` r
install_wheel(
  package = "GDAL",
  version = "3.8.4",        # Specific GDAL version
  pyversion = "3.11",       # Specific Python version
  architecture = "win_amd64" # Windows 64-bit (default)
)
```

### Check Available Versions

Before installing, you can see what versions are available:

``` r
# List all available wheels
assets <- list_rgeowheels_assets()

# Filter for GDAL
gdal_wheels <- assets[assets$package == "GDAL", ]
print(gdal_wheels[, c("package", "version", "pyversion", "architecture")])
#>      package version pyversion architecture
#> 478     GDAL  3.10.1      3.10        win32
#> 479     GDAL  3.10.1      3.10    win_amd64
#> 480     GDAL  3.10.1      3.11        win32
#> 481     GDAL  3.10.1      3.11    win_amd64
#> 482     GDAL  3.10.1      3.11    win_arm64
#> 483     GDAL  3.10.1      3.12        win32
#> 484     GDAL  3.10.1      3.12    win_amd64
#> 485     GDAL  3.10.1      3.12    win_arm64
#> 486     GDAL  3.10.1      3.13        win32
#> 487     GDAL  3.10.1      3.13    win_amd64
#> 488     GDAL  3.10.1      3.13    win_arm64
#> 489     GDAL  3.10.1      3.10    win_amd64
#> 617     GDAL   3.9.2      3.10        win32
#> 618     GDAL   3.9.2      3.10    win_amd64
#> 619     GDAL   3.9.2      3.11        win32
#> 620     GDAL   3.9.2      3.11    win_amd64
#> 621     GDAL   3.9.2      3.11    win_arm64
#> 622     GDAL   3.9.2      3.12        win32
#> 623     GDAL   3.9.2      3.12    win_amd64
#> 624     GDAL   3.9.2      3.12    win_arm64
#> 625     GDAL   3.9.2      3.13        win32
#> 626     GDAL   3.9.2      3.13    win_amd64
#> 627     GDAL   3.9.2      3.13    win_arm64
#> 628     GDAL   3.9.2       3.9        win32
#> 629     GDAL   3.9.2       3.9    win_amd64
#> 630     GDAL   3.9.2      3.10    win_amd64
#> 759     GDAL   3.8.4      3.10        win32
#> 760     GDAL   3.8.4      3.10    win_amd64
#> 761     GDAL   3.8.4      3.11        win32
#> 762     GDAL   3.8.4      3.11    win_amd64
#> 763     GDAL   3.8.4      3.11    win_arm64
#> 764     GDAL   3.8.4      3.12        win32
#> 765     GDAL   3.8.4      3.12    win_amd64
#> 766     GDAL   3.8.4      3.12    win_arm64
#> 767     GDAL   3.8.4       3.9        win32
#> 768     GDAL   3.8.4       3.9    win_amd64
#> 769     GDAL   3.8.4      3.10    win_amd64
#> 880     GDAL   3.8.2      3.10        win32
#> 881     GDAL   3.8.2      3.10    win_amd64
#> 882     GDAL   3.8.2      3.11        win32
#> 883     GDAL   3.8.2      3.11    win_amd64
#> 884     GDAL   3.8.2      3.11    win_arm64
#> 885     GDAL   3.8.2      3.12        win32
#> 886     GDAL   3.8.2      3.12    win_amd64
#> 887     GDAL   3.8.2      3.12    win_arm64
#> 888     GDAL   3.8.2       3.9        win32
#> 889     GDAL   3.8.2       3.9    win_amd64
#> 890     GDAL   3.8.2      3.10    win_amd64
#> 1001    GDAL   3.7.3      3.10        win32
#> 1002    GDAL   3.7.3      3.10    win_amd64
#> 1003    GDAL   3.7.3      3.11        win32
#> 1004    GDAL   3.7.3      3.11    win_amd64
#> 1005    GDAL   3.7.3      3.11    win_arm64
#> 1006    GDAL   3.7.3      3.12        win32
#> 1007    GDAL   3.7.3      3.12    win_amd64
#> 1008    GDAL   3.7.3      3.12    win_arm64
#> 1009    GDAL   3.7.3       3.9        win32
#> 1010    GDAL   3.7.3       3.9    win_amd64
#> 1011    GDAL   3.7.3      3.10    win_amd64
#> 1122    GDAL   3.7.2      3.10        win32
#> 1123    GDAL   3.7.2      3.10    win_amd64
#> 1124    GDAL   3.7.2      3.11        win32
#> 1125    GDAL   3.7.2      3.11    win_amd64
#> 1126    GDAL   3.7.2      3.11    win_arm64
#> 1127    GDAL   3.7.2      3.12        win32
#> 1128    GDAL   3.7.2      3.12    win_amd64
#> 1129    GDAL   3.7.2      3.12    win_arm64
#> 1130    GDAL   3.7.2       3.9        win32
#> 1131    GDAL   3.7.2       3.9    win_amd64
#> 1132    GDAL   3.7.2      3.10    win_amd64
#> 1243    GDAL   3.7.1      3.10        win32
#> 1244    GDAL   3.7.1      3.10    win_amd64
#> 1245    GDAL   3.7.1      3.11        win32
#> 1246    GDAL   3.7.1      3.11    win_amd64
#> 1247    GDAL   3.7.1      3.11    win_arm64
#> 1248    GDAL   3.7.1      3.12        win32
#> 1249    GDAL   3.7.1      3.12    win_amd64
#> 1250    GDAL   3.7.1      3.12    win_arm64
#> 1251    GDAL   3.7.1       3.9        win32
#> 1252    GDAL   3.7.1       3.9    win_amd64
#> 1253    GDAL   3.7.1      3.10    win_amd64

# Or with a specific Python version
gdal_py311 <- assets[assets$package == "GDAL" & assets$pyversion == "3.11", ]
```

## Complete Workflow Example: CI/CD Integration with Reticulate

Here’s a complete workflow combining reticulate venv creation with
rgeowheels installation:

``` r
library(reticulate)
library(rgeowheels)

# 1. Create a virtual environment
venv_path <- file.path(getwd(), ".venv")
if (!dir.exists(venv_path)) {
  virtualenv_create(venv_path, python = Sys.which("python"))
}

# 2. Activate it
use_virtualenv(venv_path, required = TRUE)

# 3. Detect available Python in this venv
detect_python_envs()

# 4. Install geospatial wheels
install_wheel("GDAL", version = "latest", pyversion = "auto")
install_wheel("rasterio", version = "latest", pyversion = "auto")
install_wheel("fiona", version = "latest", pyversion = "auto")

# 5. Verify installations
py_run_string("from osgeo import gdal; print(f'GDAL {gdal.__version__}')")
py_run_string("import rasterio; print(f'Rasterio {rasterio.__version__}')")

# 6. Use Python objects in R
py_run_string("
import rasterio
from rasterio.plot import show
# ... your geospatial Python code here
")
```

## Troubleshooting

### “Could not find wheels for…” Error

If you see an error like:

    could not find wheels for:
         - 'GDAL' version 'latest' for Python '3.9' (win_amd64)
         Available Python versions for 'GDAL' (win_amd64): 3.10, 3.11, 3.12

This means GDAL wheels aren’t available for Python 3.9. You have two
options:

1.  **Update Python**: Upgrade to a supported version (3.10, 3.11, or
    3.12)
2.  **Explicit version**: Specify an available Python version

``` r
# Upgrade your venv to Python 3.11
virtualenv_create(".venv_311", python = "C:/Python311/python.exe")
use_virtualenv(".venv_311")

# Or explicitly request 3.11
install_wheel("GDAL", pyversion = "3.11")
```

### Python Binary Not Found

If
[`detect_python_version()`](http://humus.rocks/rgeowheels/reference/detect_python_version.md)
fails with “Python binary not found”, ensure:

1.  Python is installed and in your PATH: `Sys.which("python")`
2.  Your virtual environment is activated: `use_virtualenv(".venv")`
3.  You’ve set the Python path explicitly:

``` r
set_rgeowheels_python("C:/path/to/venv/Scripts/python.exe")
detect_python_version()
```

### Setting Custom Python Path

If you have multiple Python installations, you can explicitly set which
one rgeowheels uses:

``` r
# Set for this session
set_rgeowheels_python("C:/Python311/python.exe")

# Or via environment variable (persists across R sessions)
Sys.setenv(R_RGEOWHEELS_PYTHON = "C:/Python311/python.exe")
```

## CI/CD Integration Examples

### GitHub Actions Workflow

Here’s a sample abbreviated YAML configuration for using rgeowheels in
GitHub Actions CI:

``` yaml
name: Test with GDAL

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    strategy:
      matrix:
        python-version: ['3.10', '3.11', '3.12']
        r-version: ['4.2', '4.3']

    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      
      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: ${{ matrix.r-version }}
      
      - name: Install R packages
        run: |
          install.packages(c("reticulate", "rgeowheels"))
        shell: Rscript {0}
      
      - name: Install Python geospatial wheels
        run: |
          library(rgeowheels)
          library(reticulate)
          use_python(Sys.which("python"))
          install_wheel("GDAL", pyversion = "auto")
          install_wheel("rasterio", pyversion = "auto")
        shell: Rscript {0}
      
      - name: Run tests
        run: |
          Rscript -e 'tinytest::test_all()'
```

## Performance Benefits

The rgeowheels workflow provides significant advantages on Windows:

1.  **Speed**: Pre-compiled wheels install in seconds (vs. compilation
    time)
2.  **Reliability**: No compiler requirements or build failures
3.  **Reproducibility**: Exact versions specified and matched
    consistently
4.  **Simplicity**: One-line installation via
    [`install_wheel()`](http://humus.rocks/rgeowheels/reference/install_wheel.md)
5.  **CI/CD-friendly**: Works seamlessly in headless environments

## Summary

By combining **rgeowheels** with **reticulate**’s virtual environment
management, you can create reproducible, isolated Python development
environments on Windows with geospatial dependencies installed in
seconds. This is especially valuable for:

- Complex R packages that bridge to geospatial Python libraries
- Data science workflows requiring both R and Python geospatial tools
- CI/CD pipelines where consistent environments are critical
- Teams working on Windows systems without compiler infrastructure

For more information, see
[`?install_wheel`](http://humus.rocks/rgeowheels/reference/install_wheel.md),
[`?detect_python_version`](http://humus.rocks/rgeowheels/reference/detect_python_version.md),
and
[`?detect_python_envs`](http://humus.rocks/rgeowheels/reference/detect_python_envs.md).
