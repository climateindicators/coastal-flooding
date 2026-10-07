# Regression checks on the generated data for the Coastal Flooding indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 1 dataset(s)", length(meta$datasets) == 1L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")
# Pinned from coastal-flooding_fig-1.csv (NOAA, 2024; web update September 2024).
# A legitimate data update fails here and says exactly what changed.
f1 <- rd("coastal_flood_days_by_site.csv")
row_str <- function(df, i) paste(unlist(df[i, ]), collapse = "|")
extreme <- function(df, p, fn) {
  x <- df[df$period == p, ]
  x$value[fn(as.numeric(x$value))]
}

check("flood days: 84 rows (42 sites x 2 periods)", nrow(f1) == 84L)
check("flood days: 42 distinct sites", length(unique(f1$site)) == 42L)
check("flood days: every site appears in both periods",
      all(table(f1$site) == 2L) && setequal(f1$period, c("1950-1959", "2014-2023")))
check("flood days: first row",
      row_str(f1, 1) == "Adak Island, AK|51.86331|-176.632|1950-1959|5.7")
check("flood days: last row",
      row_str(f1, 84) == "Wilmington, NC|34.2267|-77.9533|2014-2023|4.3")
check("flood days: Annapolis 1950-1959 keeps full source precision",
      f1$value[f1$site == "Annapolis, MD" & f1$period == "1950-1959"] == "1.111111111")
check("flood days: 1950-1959 min is 0",       extreme(f1, "1950-1959", which.min) == "0")
check("flood days: 1950-1959 max is 13.125 (Neah Bay, WA)",
      extreme(f1, "1950-1959", which.max) == "13.125" &&
        f1$site[f1$period == "1950-1959" & f1$value == "13.125"] == "Neah Bay, WA")
check("flood days: 2014-2023 min is 0.1",     extreme(f1, "2014-2023", which.min) == "0.1")
check("flood days: 2014-2023 max is 18 (Hilo, HI)",
      extreme(f1, "2014-2023", which.max) == "18" &&
        f1$site[f1$period == "2014-2023" & f1$value == "18"] == "Hilo, HI")
check("flood days: no blank values", all(nzchar(f1$value)))

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
