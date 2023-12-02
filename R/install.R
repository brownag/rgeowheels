#' Install Python Wheels From 'geospatial-wheels' Repository
#'
#' Used to download and install the latest versions of wheels available from <https://github.com/cgohlke/geospatial-wheels>.
#'
#' @param package Python package name to install. e.g. `"rasterio"`
#' @param version Python package version to install. Default `"latest"` determines latest version available from asset list (considers `pyversion` if set).
#' @param pyversion Python version to install package for. Default `"latest"` determines latest version available from asset list.
#' @param architecture Python package version to install. Default `"win_amd64"`, alternatives include `"win_arm64`" and `"win32"`.
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
                          destdir = tempdir(),
                          url_only = FALSE,
                          download_only = FALSE) {

  stopifnot(length(package) == 1)

  architecture <- match.arg(tolower(trimws(architecture)), c("win32", "win_amd64", "win_arm64"))
  l <- list_assets()

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
    stop("could not find wheels for:\n     - '", package, "' version '", version,
         "' for Python '", pyversion, "' (", architecture, ")", call. = FALSE)
  } else {
    path <- l[idx[1], ]$browser_download_url
    if (url_only) {
      return(path)
    }
    tf <- file.path(destdir, basename(path))
    res <- try(utils::download.file(path, destfile = tf))
    if (inherits(res, 'try-error')) {
      tf <- res
    }
  }

  if (download_only || inherits(tf, 'try-error')) {
    return(tf)
  }

  system(
    paste(
      getOption("rgeowheels.python", default = Sys.which("python")),
      "-m pip install",
      tf
    ),
    intern = TRUE,
    ignore.stderr = FALSE,
    ignore.stdout = FALSE,
    wait = TRUE
  )
}
