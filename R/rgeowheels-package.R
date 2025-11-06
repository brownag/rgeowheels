#' rgeowheels: Pre-compiled Python Geospatial Wheels for Windows
#'
#' Access and install pre-compiled Python geospatial wheels from Christoph Gohlke's
#' repository. Automatically detects Python versions and simplifies installation of
#' complex packages like GDAL on Windows.
#'
#' @section Main Functions:
#' - `install_wheel()`: Download and install wheels with automatic Python version detection
#' - `list_rgeowheels_assets()`: List available wheels from geospatial-wheels repository
#' - `detect_python_version()`: Extract Python version from a binary
#' - `detect_python_envs()`: Discover available Python environments (venv/conda/system)
#' - `get_rgeowheels_python()` / `set_rgeowheels_python()`: Manage Python binary path
#'
#' @section Auto-Detection Features:
#' Use `pyversion = "auto"` in `install_wheel()` to automatically detect and match
#' the current Python version. Suppress informational messages with:
#' - Environment variable: `Sys.setenv(R_RGEOWHEELS_QUIET_AUTO = "TRUE")`
#' - R option: `options(rgeowheels.quiet_auto = TRUE)`
#' - Explicit version specification: `pyversion = "3.11"`
#'
#' @section Virtual Environment Support:
#' Full support for Python virtual environments and conda environments. Use
#' `detect_python_envs()` to discover environments, then activate with reticulate:
#' 
#' ```
#' library(reticulate)
#' use_virtualenv(".venv")
#' install_wheel("GDAL", pyversion = "auto")
#' ```
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

#' @importFrom utils packageVersion
#' @importFrom tools R_user_dir
.onAttach <- function(lib, pkg) {
  cp <- file.path(tools::R_user_dir("rgeowheels", "cache"), "assets.csv")
  if (file.exists(cp)) {
    x <- read.csv(cp)
    mu <- if ("updated_at" %in% names(x)) {
      gsub("(.*)T.*", "\\1", x$updated_at[1])
    } else {
      "<unknown>"
    }
    re <- if ("release" %in% names(x)) {
      x$release[1]
    } else {
      # For latest release, construct URL from metadata if available
      mf <- file.path(tools::R_user_dir("rgeowheels", "cache"), "metadata.rds")
      if (file.exists(mf)) {
        metadata <- readRDS(mf)
        paste0("https://github.com/cgohlke/geospatial-wheels/releases/tag/", metadata$tag_name)
      } else {
        "<latest>"
      }
    }

    # Only check freshness if cache is more than 24 hours old
    stale_msg <- ""
    cache_age_hours <- difftime(Sys.time(), file.mtime(cp), units = "hours")
    if (cache_age_hours > 24) {
      freshness <- tryCatch(
        .check_cache_freshness(),
        error = function(e) {
          # Network error or offline: skip freshness check
          NULL
        }
      )
      if (!is.null(freshness) && !freshness$fresh && !is.null(freshness$current_tag) && !is.null(freshness$latest_tag)) {
        stale_msg <- paste0("\n - Cache is outdated (current: ", freshness$current_tag,
                           ", latest: ", freshness$latest_tag, ")")
      }
    }
  } else {
    mu <- "<not found>"
    re <- "<not found>"
    stale_msg <- ""
  }

  packageStartupMessage(
    "rgeowheels ",
    packageVersion("rgeowheels"),
    "\n",
    ifelse(
      mu == "<not found>",
      " - Cached release asset list not found, run `list_rgeowheels_assets()` to begin.",
      paste0(" - Latest cached release: ", mu, "\n <", re, ">", stale_msg)
    )
  )
}
