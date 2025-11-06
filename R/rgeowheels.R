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
        env_type <- "system"
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
  r <- try(readLines("https://github.com/cgohlke/geospatial-wheels/releases.atom"), silent = TRUE)
  if (inherits(r, 'try-error')) {
    if (grepl("403", as.character(r)) || grepl("Forbidden", as.character(r))) {
      stop("GitHub API rate limit exceeded. Unable to fetch release information from Atom feed. Please try again later or use cached data.", call. = FALSE)
    } else {
      r <- character()
    }
  }
  r <- r[grep("https://github.com/cgohlke/geospatial-wheels/releases/tag", r, fixed = TRUE)]
  r <- gsub("^.*href=\"(.*)\"/>$", "\\1", r)

  if (any(i > length(r)))
    i <- i[i <= length(r)]

  r[i]
}

#' Refresh rgeowheels cache
#'
#' Force update of the cached wheel download index from the latest GitHub release.
#'
#' @return Called for side effects. Updates the local cache with the latest available wheels.
#' @export
refresh_rgeowheels_cache <- function() {
  message("Refreshing rgeowheels cache...")
  tryCatch({
    .get_latest(update_cache = TRUE)
    message("Cache refresh completed successfully.")
  }, error = function(e) {
    if (grepl("rate limit", e$message, ignore.case = TRUE)) {
      # Re-throw rate limit errors with the informative message
      stop(e$message, call. = FALSE)
    } else {
      # For other errors, provide a generic message
      stop("Cache refresh failed: ", conditionMessage(e), call. = FALSE)
    }
  })
  invisible(NULL)
}

#' @importFrom httr RETRY content status_code headers
#' @importFrom jsonlite fromJSON
.safe_api_call <- function(url) {
  response <- httr::RETRY(
    verb = "GET",
    url = url,
    max_tries = 3,
    pause_base = 1,
    pause_cap = 60,
    terminate_on = c(403, 429)  # Don't retry on rate limit errors
  )
  
  if (httr::status_code(response) == 403) {
    # Try to parse rate limit information from response
    response_content <- httr::content(response, as = "text", encoding = "UTF-8")
    
    # Parse JSON response if possible
    rate_info <- tryCatch({
      jsonlite::fromJSON(response_content)
    }, error = function(e) {
      list(message = "API rate limit exceeded")
    })
    
    # Get rate limit headers if available
    rate_limit <- httr::headers(response)$`x-ratelimit-limit`
    rate_remaining <- httr::headers(response)$`x-ratelimit-remaining`
    rate_reset <- httr::headers(response)$`x-ratelimit-reset`
    
    # Build informative message
    msg <- "GitHub API rate limit exceeded"
    if (!is.null(rate_limit) && !is.null(rate_remaining) && !is.null(rate_reset)) {
      reset_time <- as.POSIXct(as.numeric(rate_reset), origin = "1970-01-01", tz = "UTC")
      msg <- sprintf(
        "GitHub API rate limit exceeded (limit: %s, remaining: %s, resets at: %s UTC). %s",
        rate_limit, rate_remaining, format(reset_time, "%H:%M:%S"), 
        rate_info$message %||% ""
      )
    } else if (!is.null(rate_info$message)) {
      msg <- paste0("GitHub API rate limit exceeded: ", rate_info$message)
    }
    
    stop(msg, call. = FALSE)
  } else if (httr::status_code(response) >= 400) {
    stop(sprintf("GitHub API request failed with status %d", httr::status_code(response)), call. = FALSE)
  }
  
  # Parse successful response
  httr::content(response, as = "parsed", simplifyVector = TRUE)
}

# Helper function for null coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x

#' @importFrom jsonlite read_json
#' @importFrom utils write.csv read.csv
#' @importFrom tools R_user_dir
.check_cache_freshness <- function() {
  cache <- tools::R_user_dir("rgeowheels", "cache")
  cf <- file.path(cache, "assets.csv")
  mf <- file.path(cache, "metadata.rds")
  ff <- file.path(cache, "freshness.rds")

  if (!file.exists(cf)) {
    return(list(fresh = FALSE, current_tag = NULL, latest_tag = NULL))
  }

  if (file.exists(ff)) {
    freshness_cache <- readRDS(ff)
    if (difftime(Sys.time(), freshness_cache$checked_at, units = "hours") < 1) {
      return(freshness_cache$result)
    }
  }

  latest_res <- try(.safe_api_call(
    "https://api.github.com/repos/cgohlke/geospatial-wheels/releases/latest"
  ), silent = TRUE)

  if (inherits(latest_res, 'try-error')) {
    result <- list(fresh = NA, current_tag = NULL, latest_tag = NULL)
  } else {
    latest_tag <- latest_res$tag_name

    if (file.exists(mf)) {
      metadata <- readRDS(mf)
      current_tag <- metadata$tag_name
    } else {
      current_tag <- NULL
    }

    result <- list(
      fresh = identical(current_tag, latest_tag),
      current_tag = current_tag,
      latest_tag = latest_tag
    )

    freshness_cache <- list(
      checked_at = Sys.time(),
      result = result
    )
    saveRDS(freshness_cache, ff)
  }

  result
}

#' List assets available from "geospatial-wheels" repository
#'
#' @param release Specify custom release to list assets for. Default: `NULL`
#' @param update_cache Force update of wheel download index? Default: `FALSE`
#' @param check_freshness Check if cached data is from the latest release? Default: `FALSE`
#'
#' @return A _data.frame_ containing  `package`, `version`, `pyversion`, `architecture` and other metadata about each asset in a release.
#' @export
#'
list_rgeowheels_assets <- function(release = NULL, update_cache = FALSE, check_freshness = FALSE) {
  # Check cache freshness if requested and not forcing update
  if (isTRUE(check_freshness) && !isTRUE(update_cache)) {
    freshness <- .check_cache_freshness()
    if (isFALSE(freshness$fresh) && !is.null(freshness$current_tag) && !is.null(freshness$latest_tag)) {
      message("rgeowheels cache is outdated (current: ", freshness$current_tag,
              ", latest: ", freshness$latest_tag, "). Consider running refresh_rgeowheels_cache().")
    }
  }

  if (!is.null(release) && release == "latest") {
    l <- .get_latest(update_cache = update_cache)
  } else if (!is.null(release)) {
    l <- .tag(release, update_cache = update_cache)
  } else {
    cache <- tools::R_user_dir("rgeowheels", "cache")
    cf <- file.path(cache, "assets.csv")
    if (file.exists(cf) && !isTRUE(update_cache)) {
      l <- read.csv(cf)
    } else {
      r <- .get_release(1:1000)
      l <- .tag(r, update_cache = update_cache)
    }
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

#' @importFrom httr RETRY content status_code headers
#' @importFrom jsonlite fromJSON
#' @importFrom utils write.csv read.csv
#' @importFrom tools R_user_dir
.get_latest <- function(update_cache = FALSE) {
  cache <- tools::R_user_dir("rgeowheels", "cache")
  cf <- file.path(cache, "assets.csv")
  mf <- file.path(cache, "metadata.rds")

  if (!file.exists(cf) || isTRUE(update_cache)) {
    res <- .safe_api_call(
      "https://api.github.com/repos/cgohlke/geospatial-wheels/releases/latest"
    )
    assets <- as.data.frame(res$assets)
    if (!dir.exists(cache)) {
      dir.create(cache, recursive = TRUE, showWarnings = FALSE)
    }
    write.csv(assets, cf, row.names = FALSE)

    # Store metadata with release tag
    metadata <- list(
      tag_name = res$tag_name,
      fetched_at = Sys.time()
    )
    saveRDS(metadata, mf)
  } else {
    assets <- read.csv(cf)
  }
  assets
}

#' @importFrom httr RETRY content status_code headers
#' @importFrom jsonlite fromJSON
#' @importFrom utils write.csv read.csv
#' @importFrom tools R_user_dir
.tag <- function(x, update_cache = FALSE) {
  cache <- tools::R_user_dir("rgeowheels", "cache")
  cf <- file.path(cache, "assets.csv")
  if (!file.exists(cf) || isTRUE(update_cache)) {
    .f <- function(y) {
      res <- .safe_api_call(
        paste0("https://api.github.com/repos/cgohlke/geospatial-wheels/releases/tags/",
               gsub(".*tag/(.*)$", "\\1", y))
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
#` Used to download and install the latest versions of wheels available from <https://github.com/cgohlke/geospatial-wheels>.
#'
#' @param package Python package name to install. e.g. `"rasterio"`
#' @param version Python package version to install. Default `"latest"` determines latest version available from asset list (considers `pyversion` if set).
#' @param pyversion Python version to install package for. Default `"latest"` determines latest version available from asset list. Use `"auto"` to detect the Python version from the specified Python binary.
#' @param architecture Target architecture for the wheel to install. Default \code{"win_amd64"}, alternatives include \code{"win_arm64"} and \code{"win32"}.
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
  l_full <- l  # Store full asset list for error messages

  # Handle auto-detection of Python version
  if (pyversion == "auto") {
    pyversion <- detect_python_version(python)
    quiet_auto <- Sys.getenv("R_RGEOWHEELS_QUIET_AUTO", unset = "")
    quiet_auto <- quiet_auto == "TRUE" || quiet_auto == "true" || isTRUE(getOption("rgeowheels.quiet_auto"))
    if (!quiet_auto) {
      message("Auto-selected Python ", pyversion, " for ", package)
    }
  }

  if (pyversion == "latest" && tolower(package) %in% tolower(l$package)) {
    ll <- l[tolower(l$package) == tolower(package), ]
    pyversion <- max(package_version(ll$pyversion, strict = FALSE))
  }
  l <- l[l$pyversion == as.character(pyversion), ]

  if (version == "latest" && tolower(package) %in% tolower(l$package)) {
    ll <- l[tolower(l$package) == tolower(package), ]
    version <- max(package_version(ll$version, strict = FALSE))
  }
  l <- l[l$version == as.character(version), ]

  idx <- which(tolower(l$package) == tolower(package) &
                 l$version == version &
                 l$pyversion == pyversion &
                 l$architecture == architecture)

  if (length(idx) == 0) {
    # Generate helpful error message with available versions
    available_msg <- .get_available_versions_message(
      l_full, package, pyversion, architecture
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
  pkg_assets <- assets[tolower(assets$package) == tolower(package) & assets$architecture == architecture, ]
  if (nrow(pkg_assets) > 0) {
    avail_pyversions <- unique(pkg_assets$pyversion)
    
    pv <- package_version(avail_pyversions, strict = FALSE)
    na_mask <- is.na(pv)
    if (any(na_mask)) {
      valid_order <- order(pv[!na_mask])
      na_order <- order(avail_pyversions[na_mask])
      combined_order <- c(which(!na_mask)[valid_order], which(na_mask)[na_order])
    } else {
      combined_order <- order(pv)
    }
    avail_pyversions <- avail_pyversions[combined_order]
    
    msg <- paste0("\n     Available Python versions for '", package, "' (", architecture, "): ",
                  paste(avail_pyversions, collapse = ", "))
  }
  
  msg
}
