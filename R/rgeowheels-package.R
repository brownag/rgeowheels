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
    mu <- gsub("(.*)T.*", "\\1", x$updated_at[1])
    re <- x$release[1]
  } else {
    mu <- "<not found>"
    re <- "<not found>"
  }
  packageStartupMessage(
    "rgeowheels ",
    packageVersion("rgeowheels"),
    "\n",
    ifelse(
      mu == "<not found>",
      " - Cached release asset list not found, run `list_assets()` to begin.",
      paste0("Latest cached release: ", mu, "\n <", re, ">")
    )
  )
}
