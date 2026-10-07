# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-coastal-flooding/index.html>  \
  sha256 `49403d2bfc3efb45266ecd58cd5228f552fe228e56433024849ace819ef834cf`

Technical documentation: <https://19january2025snapshot.epa.gov/system/files/documents/2024-09/coastal-flooding_documentation.pdf>

## Figure data

- `coastal-flooding_fig-1.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-09/coastal-flooding_fig-1.csv>  \
  sha256 `d89ebf67ab0d4fd62730e11d4b21f95afed5a9c9a456a570703bf221a4f6ecd2`  \
  encoding windows-1252, 42 data rows, columns: `Site name`, `Latitude`, `Longitude`, `1950-1959 avg`, `2014-2023 avg`  \
  title: Figure 1. Frequency of Flooding Along U.S. Coasts, 2014–2023 Versus 1950–1959  \
  data source: NOAA, 2024; web update: September 2024; units: degrees; degrees; average number of flood days per year; average number of flood days per year

- `coastal-flooding_fig-2.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-09/coastal-flooding_fig-2.csv>  \
  sha256 `60af11e9f05a8fb39f04a23c9dbe5459ba9e656e8230fa2d26066838e4fe6966`  \
  encoding windows-1252, 42 data rows, columns: (blank, site name), `1950-1969`, `1970-1989`, `1990-2009`, `2010-2023`  \
  title: Figure 2. Average Number of Coastal Flood Events per Year, 1950–2023  \
  data source: NOAA, 2024; web update: September 2024; units: average number of flood events per year  \
  EPA renders this figure as an interactive chart with no download link on the page; the file was downloaded by hand from the chart and confirmed byte-identical to the URL above.
