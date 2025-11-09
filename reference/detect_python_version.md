# Detect Python Version

Extract the major.minor Python version from a Python binary.

## Usage

``` r
detect_python_version(python = get_rgeowheels_python())
```

## Arguments

- python:

  Path to Python executable. Default:
  [`get_rgeowheels_python()`](http://humus.rocks/rgeowheels/reference/rgeowheels_python.md)

## Value

*character* Python version in major.minor format (e.g., "3.11")

## Examples

``` r
if (FALSE) { # \dontrun{
  detect_python_version()
  detect_python_version("/path/to/venv/bin/python")
} # }
```
