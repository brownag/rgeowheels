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
list_assets <- function(release = NULL, update_cache = FALSE) {
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
