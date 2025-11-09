# Detect Available Python Environments

Scan the system for available Python environments including virtual
environments, conda environments, and system Python.

## Usage

``` r
detect_python_envs(include_system = TRUE, project_root = getwd())
```

## Arguments

- include_system:

  Include system Python in results? Default: `TRUE`

- project_root:

  Directory to scan for project-local virtual environments. Default:
  current working directory

## Value

A *data.frame* with columns: `type` (venv/conda/system), `path`,
`version`, `active`

## Details

Scans for virtual environments in the following project-local
directories (in order): `.venv`, `venv`, `.virtualenv`, `env`

Also detects active virtual environment via `VIRTUAL_ENV` environment
variable and active conda environment via `CONDA_DEFAULT_ENV`.

## Examples

``` r
if (FALSE) { # \dontrun{
  detect_python_envs()
  detect_python_envs(project_root = "/path/to/project")
} # }
```
