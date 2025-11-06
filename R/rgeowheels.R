#' Get or Set Python Path
#'
#' Set the path the Python binary used to run installation commands. May be a system or virtual/conda environment.
#'
#' @param x Path to `python` or `python3` binary.
#'
#' @return _character_ Value of option `"rgeowheels.python"`, or, if set, the value of the system environment variable `"R_RGEOWHEELS_PYTHON"`. If neither are set, then the result of `Sys.which("python")` (or `Sys.which("python3")` if the former fails).
#' @export
#'
#' @rdname rgeowheels_python
set_rgeowheels_python <- function(x) {
  stopifnot(length(x) == 1)
  options(rgeowheels.python = x)[[1]]
  y <- get_rgeowheels_python()
  if (y != x) {
    message("note: using Python binary ", shQuote(y))
  }
  y
}

#' @export
#' @rdname rgeowheels_python
get_rgeowheels_python <- function() {
  sp <- Sys.getenv("R_RGEOWHEELS_PYTHON")
  if (sp == "") {
    sp <- Sys.which("python")
    if (sp == "") {
      sp <- Sys.which("python3")
    }
  }
  res <- getOption("rgeowheels.python", default = sp)
  if (!file.exists(res)) {
    res <- sp
  }
  res
}

#' Detect Python Version
#'
#' Extract the major.minor Python version from a Python binary.
#'
#' @param python Path to Python executable. Default: `get_rgeowheels_python()`
#'
#' @return _character_ Python version in major.minor format (e.g., "3.11")
#' @export
#'
#' @examples
#' \dontrun{
#'   detect_python_version()
#'   detect_python_version("/path/to/venv/bin/python")
#' }
detect_python_version <- function(python = get_rgeowheels_python()) {
  stopifnot(length(python) == 1)
  if (!file.exists(python)) {
    stop("Python binary not found: ", shQuote(python), call. = FALSE)
  }
  res <- try(system(
    paste(shQuote(python), "-c \"import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')\""),
    intern = TRUE,
    ignore.stderr = TRUE,
    wait = TRUE
  ), silent = TRUE)
  if (inherits(res, 'try-error') || length(res) == 0) {
    stop("Failed to detect Python version from: ", shQuote(python), call. = FALSE)
  }
  trimws(res[1])
}

#' Detect Available Python Environments
#'
#' Scan the system for available Python environments including virtual environments, conda environments, and system Python.
#'
#' @param include_system Include system Python in results? Default: `TRUE`
#' @param project_root Directory to scan for project-local virtual environments. Default: current working directory
#'
#' @return A _data.frame_ with columns: `type` (venv/conda/system), `path`, `version`, `active`
#' @export
#'
#' @details
#' Scans for virtual environments in the following project-local directories (in order):
#' `.venv`, `venv`, `.virtualenv`, `env`
#'
#' Also detects active virtual environment via `VIRTUAL_ENV` environment variable and active conda environment via `CONDA_DEFAULT_ENV`.
#'
#' @examples
#' \dontrun{
#'   detect_python_envs()
#'   detect_python_envs(project_root = "/path/to/project")
#' }
detect_python_envs <- function(include_system = TRUE, project_root = getwd()) {
  envs <- data.frame(
    type = character(),
    path = character(),
    version = character(),
    active = logical(),
    stringsAsFactors = FALSE
  )

  active_venv <- Sys.getenv("VIRTUAL_ENV")
  active_conda <- Sys.getenv("CONDA_DEFAULT_ENV")
  active_python <- get_rgeowheels_python()

  # Scan for project-local venvs
  venv_patterns <- c(".venv", "venv", ".virtualenv", "env")
  for (pattern in venv_patterns) {
    venv_path <- file.path(project_root, pattern)
    if (dir.exists(venv_path)) {
      python_bin <- if (.Platform$OS.type == "windows") {
        file.path(venv_path, "Scripts", "python.exe")
      } else {
        file.path(venv_path, "bin", "python")
      }
      if (file.exists(python_bin)) {
        py_version <- try(detect_python_version(python_bin), silent = TRUE)
        if (!inherits(py_version, 'try-error')) {
          envs <- rbind(envs, data.frame(
            type = "venv",
            path = venv_path,
            version = py_version,
            active = venv_path == active_venv || python_bin == active_python,
            stringsAsFactors = FALSE
          ))
        }
      }
    }
  }

  # Detect active conda environment
  if (active_conda != "") {
    conda_python <- if (.Platform$OS.type == "windows") {
      file.path(active_conda, "python.exe")
    } else {
      file.path(active_conda, "bin", "python")
    }
    if (file.exists(conda_python)) {
      py_version <- try(detect_python_version(conda_python), silent = TRUE)
      if (!inherits(py_version, 'try-error')) {
        envs <- rbind(envs, data.frame(
          type = "conda",
          path = active_conda,
          version = py_version,
          active = TRUE,
          stringsAsFactors = FALSE
        ))
      }
    }
  }

  # Add system Python if requested
  if (isTRUE(include_system)) {
    sys_python <- get_rgeowheels_python()
    if (file.exists(sys_python)) {
      py_version <- try(detect_python_version(sys_python), silent = TRUE)
      if (!inherits(py_version, 'try-error')) {
        env_type <- if (active_venv == "") "system" else "system"
        is_active <- sys_python == active_python && active_venv == ""
        envs <- rbind(envs, data.frame(
          type = env_type,
          path = sys_python,
          version = py_version,
          active = is_active,
          stringsAsFactors = FALSE
        ))
      }
    }
  }

  envs
}

.get_release <- function(i = 1) {

  r <- try(readLines("https://github.com/cgohlke/geospatial-wheels/releases.atom"))
  if (inherits(r, 'try-error')) {
    r <- character()
  }
  r <- r[grep("https://github.com/cgohlke/geospatial-wheels/releases/tag", r, fixed = TRUE)]
  r <- gsub("^.*href=\"(.*)\"/>$", "\\1", r)

  if (any(i > length(r)))
    i <- i[i <= length(r)]
    #stop("invalid release index `i=", paste0(i[i > length(r)], collapse=','), "`", call. = FALSE)

  r[i]
}

#' List assets available from "geospatial-wheels" repository
#'
#' @param release Specify custom release to list assets for. Default: `NULL`
#' @param update_cache Force update of wheel download index? Default: `FALSE`
#'
#' @return A _data.frame_ containing  `package`, `version`, `pyversion`, `architecture` and other metadata about each asset in a release.
#' @export
#'
list_rgeowheels_assets <- function(release = NULL, update_cache = FALSE) {
  if (!is.null(release) && release == "latest") {
    l <- .get_latest(update_cache = update_cache)
  } else if (!is.null(release)) {
    l <- .tag(release, update_cache = update_cache)
  } else {
    r <- .get_release(1:1000)
    l <- .tag(r, update_cache = update_cache)
  }
  res <- l[, c("name", "content_type", "size",
               "download_count", "created_at", "browser_download_url")]
  package <- gsub("^(.*)-\\d+\\.\\d+.*$", "\\1", res$name)
  version <- gsub("^.*-(\\d+\\.\\d+[^\\-]+)-.*$", "\\1", res$name)
  architecture <- gsub(".*-\\d+\\.\\d+[^\\-]+-(.*)\\.whl$", "\\1", res$name)
  pyversion <- gsub(".*[cp]{2}([234])(\\d+).*", "\\1.\\2", architecture)
  architecture <- gsub("^.*(win.*)$", "\\1", architecture)
  cbind(data.frame(package = package,
                   version = version,
                   pyversion = pyversion,
                   architecture = architecture), res)
}

#' @importFrom jsonlite read_json
#' @importFrom utils write.csv read.csv
#' @importFrom tools R_user_dir
.get_latest <- function(update_cache = FALSE) {
  cache <- tools::R_user_dir("rgeowheels", "cache")
  cf <- file.path(cache, "assets.csv")
  if (!file.exists(cf) || isTRUE(update_cache)) {
    res <- jsonlite::read_json(
      "https://api.github.com/repos/cgohlke/geospatial-wheels/releases/latest",
      simplifyVector = TRUE
    )
    assets <- as.data.frame(res$assets)
    if (!dir.exists(cache)) {
      dir.create(cache, recursive = TRUE, showWarnings = FALSE)
    }
    write.csv(assets, cf, row.names = FALSE)
  } else {
    assets <- read.csv(cf)
  }
  assets
}

#' @importFrom jsonlite read_json
#' @importFrom utils write.csv read.csv
#' @importFrom tools R_user_dir
.tag <- function(x, update_cache = FALSE) {
  cache <- tools::R_user_dir("rgeowheels", "cache")
  cf <- file.path(cache, "assets.csv")
  if (!file.exists(cf) || isTRUE(update_cache)) {
    .f <- function(y) {
      res <- jsonlite::read_json(
        paste0("https://api.github.com/repos/cgohlke/geospatial-wheels/releases/tags/",
               gsub(".*tag/(.*)$", "\\1", y)),
        simplifyVector = TRUE
      )
      res2 <- as.data.frame(res$assets)
      res3 <- cbind(data.frame(release = y), res2)
      res3[[7]] <- NULL
      rownames(res3) <- NULL
      res3
    }
    assets <- data.frame(do.call('rbind', lapply(x, .f)))

    if (!dir.exists(cache)) {
      dir.create(cache, recursive = TRUE, showWarnings = FALSE)
    }
    write.csv(assets, cf, row.names = FALSE)
  } else {
    assets <- read.csv(cf)
  }
  assets
}

#' Install Python Wheels From 'geospatial-wheels' Repository
#'
#' Used to download and install the latest versions of wheels available from <https://github.com/cgohlke/geospatial-wheels>.
#'
#' @param package Python package name to install. e.g. `"rasterio"`
#' @param version Python package version to install. Default `"latest"` determines latest version available from asset list (considers `pyversion` if set).
#' @param pyversion Python version to install package for. Default `"latest"` determines latest version available from asset list. Use `"auto"` to detect the Python version from the specified Python binary.
#' @param architecture Python package version to install. Default `"win_amd64"`, alternatives include `"win_arm64`" and `"win32"`.
#' @param python Path to Python executable to use for install. Default: `get_rgeowheels_python()`
#' @param destdir Destination directory for downloaded wheel file. Default: `tempdir()`
#' @param url_only Return the URL of the .whl file without downloading? Default: `FALSE`
#' @param download_only Download .whl file without attempting install? Default: `FALSE`
#'
#' @return Called for side effects (download and install a Python wheel). Returns _character_ containing path to .whl file when `url_only=TRUE` or `download_only=TRUE`.
#' @export
#' @importFrom utils download.file
install_wheel <- function(package,
                          version = "latest",
                          pyversion = "latest",
                          architecture = "win_amd64",
                          python = get_rgeowheels_python(),
                          destdir = tempdir(),
                          url_only = FALSE,
                          download_only = FALSE) {

  stopifnot(length(package) == 1)

  architecture <- match.arg(tolower(trimws(architecture)), c("win32", "win_amd64", "win_arm64"))
  l <- list_rgeowheels_assets()

  # Handle auto-detection of Python version
  auto_detected_pyversion <- NA_character_
  if (pyversion == "auto") {
    auto_detected_pyversion <- detect_python_version(python)
    pyversion <- auto_detected_pyversion
    quiet_auto <- Sys.getenv("R_RGEOWHEELS_QUIET_AUTO", unset = "")
    quiet_auto <- quiet_auto == "TRUE" || quiet_auto == "true" || isTRUE(getOption("rgeowheels.quiet_auto"))
    if (!quiet_auto) {
      message("Auto-selected Python ", pyversion, " for ", package)
    }
  }

  if (pyversion == "latest" && package %in% l$package) {
    ll <- l[l$package == package, ]
    # TODO: package_version() is too strict for python versions
    pyversion <- max(package_version(ll$pyversion, strict = FALSE))
  }
  l <- l[l$pyversion == as.character(pyversion), ]

  if (version == "latest" && package %in% l$package) {
    ll <- l[l$package == package, ]
    # TODO: package_version() is too strict for python versions
    version <- max(package_version(ll$version, strict = FALSE))
  }
  l <- l[l$version == as.character(version), ]

  idx <- which(l$package == package &
                 l$version == version &
                 l$pyversion == pyversion &
                 l$architecture == architecture)

  if (length(idx) == 0) {
    # Generate helpful error message with available versions
    available_msg <- .get_available_versions_message(
      l, package, pyversion, architecture
    )
    stop("could not find wheels for:\n     - '", package, "' version '", version,
         "' for Python '", pyversion, "' (", architecture, ")",
         available_msg, call. = FALSE)
  } else {
    path <- l[idx[1], ]$browser_download_url
    if (url_only) {
      return(path)
    }
    tf <- file.path(destdir, basename(path))
    res <- try(utils::download.file(path, destfile = tf, mode = "wb"))
    if (inherits(res, 'try-error')) {
      tf <- res
    }
  }

  if (download_only || inherits(tf, 'try-error')) {
    return(tf)
  }

  system(
    paste(shQuote(python),
          "-m pip install",
          tf
    ),
    intern = TRUE,
    ignore.stderr = FALSE,
    ignore.stdout = FALSE,
    wait = TRUE
  )
}

.get_available_versions_message <- function(assets, package, pyversion, architecture) {
  msg <- ""
  
  # Try to find available Python versions for this package/architecture
  pkg_assets <- assets[assets$package == package & assets$architecture == architecture, ]
  if (nrow(pkg_assets) > 0) {
    avail_pyversions <- unique(pkg_assets$pyversion)
    avail_pyversions <- sort(avail_pyversions)
    msg <- paste0("\n     Available Python versions for '", package, "' (", architecture, "): ",
                  paste(avail_pyversions, collapse = ", "))
  }
  
  msg
}
