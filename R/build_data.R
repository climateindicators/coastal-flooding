# Build tidy long-format data for the Coastal Flooding indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Coastal Flooding",
  slug                    = "costal-flooding",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-coastal-flooding/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-09/coastal-flooding_documentation.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: Frequency of Flooding Along U.S. Coasts, 2014–2023 Versus 1950–1959 ----

f1_path <- file.path(raw_dir, "coastal-flooding_fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f1_raw,
  id_cols          = c("Site name", "Latitude", "Longitude"),
  expected_headers = c("1950-1959 avg", "2014-2023 avg"),
  what             = "coastal-flooding_fig-1.csv"
)

# One row per site per period. The Units: line's two "degrees" belong to the
# coordinate columns; both value series are flood days per year, so meta.yml
# carries that single unit. Values stay character so the source digits survive
# byte for byte.
f1 <- bind_rows(
  transmute(f1_raw, site = `Site name`, latitude = Latitude, longitude = Longitude,
            period = "1950-1959", value = `1950-1959 avg`),
  transmute(f1_raw, site = `Site name`, latitude = Latitude, longitude = Longitude,
            period = "2014-2023", value = `2014-2023 avg`)
)

write_csv_stable(f1, file.path(out_dir, "coastal_flood_days_by_site.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

# One entry per output column, in order, filled from the data frame itself so it
# cannot drift. `type` and `description` are deliberately blank: tests/test-data.R
# fails while either is empty, so every column has to be documented by hand.
describe <- function(df) {
  docs <- list(
    site      = col("site", "string", "NOAA tide gauge site name as published by EPA"),
    latitude  = col("latitude", "number", "Latitude of the tide gauge, decimal degrees north"),
    longitude = col("longitude", "number", "Longitude of the tide gauge, decimal degrees (negative = west)"),
    period    = col("period", "string", "Decade the average covers: 1950-1959 or 2014-2023"),
    value     = col("value", "number", "Average number of flood days per year at the site over the period")
  )
  unname(docs[names(df)])
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "coastal_flood_days_by_site.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "coastal-flooding_fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "windows-1252",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = "average number of flood days per year",
      rows            = nrow(f1),
      columns         = describe(f1)
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
