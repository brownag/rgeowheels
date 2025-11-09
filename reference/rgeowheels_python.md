# Get or Set Python Path

Set the path the Python binary used to run installation commands. May be
a system or virtual/conda environment.

## Usage

``` r
set_rgeowheels_python(x)

get_rgeowheels_python()
```

## Arguments

- x:

  Path to `python` or `python3` binary.

## Value

*character* Value of option `"rgeowheels.python"`, or, if set, the value
of the system environment variable `"R_RGEOWHEELS_PYTHON"`. If neither
are set, then the result of `Sys.which("python")` (or
`Sys.which("python3")` if the former fails).
