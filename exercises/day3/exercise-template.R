# Day 3 · Exercise (graded)
# Topic: Basic statistics with R
# Author: Ilona Maier
# GitHub: @ilonamaier
# Date: 2026-05-29

library(tidyverse)
library(janitor)
library(here)


# ---- Data --------------------------------------------------------------
# Load and join the two Eurostat tables you already used on Day 2.
# Filter to hotels (nace_r2 == "I551"), 2024, residency total. The
# time column is `TIME_PERIOD`, the value column is `values`. Full
# code reference is in `exercises/day2/exercise-template.R`.

# Load hotel nights data
nights <- read_csv(here("datasets", "raw", "eurostat-nights_monthly.csv")) |>
  filter(c_resid == "TOTAL", unit == "NR", nace_r2 == "I551") |>
  mutate(year = lubridate::year(TIME_PERIOD)) |>
  filter(year == 2024) |>
  select(geo, year, time = TIME_PERIOD, nights = values)

# Load hotel capacity data
capacity <- read_csv(here("datasets", "raw", "eurostat-capacity_annual.csv")) |>
  filter(accomunit == "BEDPL", unit == "NR", nace_r2 == "I551") |>
  mutate(year = lubridate::year(TIME_PERIOD)) |>
  filter(year == 2024) |>
  select(geo, year, bed_places = values)

# Join both datasets and create occupancy index
joined <- nights |>
  left_join(capacity, by = c("geo", "year")) |>
  mutate(occupancy_index = nights / bed_places)


# ---- 1. Descriptives ---------------------------------------------------
# From `joined`, produce a summary table with n, mean, SD, median, Q1,
# Q3 and count of missing values for both `nights` and
# `occupancy_index`, grouped by country (`geo`). Keep only countries
# with at least 6 monthly observations and sort by mean nights
# descending.

# your code here

hotels <- tibble(
  island = c("Gran Canaria", "Tenerife", "Lanzarote",
             "Fuerteventura", "La Palma"),
  stars  = c(4L, 5L, 4L, 3L, 3L),
  price  = c(82, 95, 110, 100, 78),
  nights = c(12.5, 18.3, 9.8, 11.2, 6.4)
)

# Create summary statistics by country
summary_table <- joined |>
  group_by(geo) |>
  summarise(

    # Count rows
    n = n(),

    # Statistics for nights
    mean_nights = mean(nights, na.rm = TRUE),
    sd_nights = sd(nights, na.rm = TRUE),
    median_nights = median(nights, na.rm = TRUE),
    q1_nights = quantile(nights, 0.25, na.rm = TRUE),
    q3_nights = quantile(nights, 0.75, na.rm = TRUE),

    # Statistics for occupancy index
    mean_occ = mean(occupancy_index, na.rm = TRUE),
    sd_occ = sd(occupancy_index, na.rm = TRUE),
    median_occ = median(occupancy_index, na.rm = TRUE),
    q1_occ = quantile(occupancy_index, 0.25, na.rm = TRUE),
    q3_occ = quantile(occupancy_index, 0.75, na.rm = TRUE),

    # Count missing values
    missing_nights = sum(is.na(nights)),
    missing_occ = sum(is.na(occupancy_index))
  ) |>

  # Keep countries with at least 6 months of data
  filter(n >= 6) |>

  # Sort by highest average nights
  arrange(desc(mean_nights))

summary_table


# ---- 2. Cross-tabulation ----------------------------------------------
# Eurostat data comes pre-aggregated, so a true cross-tab needs to be
# built manually. Re-load the monthly nights file, this time keeping
# c_resid == "DOM" (residents only) and c_resid == "FOR" (non-residents
# only) instead of TOTAL, with nace_r2 == "I551" for 2024.
# Sum nights per (geo, c_resid), pivot wider so each residency type is
# a column, and compute row percentages so each country sums to 100 %.
# Print the result for 6-10 EU countries of your choice. In one or two
# lines, comment on a striking cell — e.g. a country with overwhelmingly
# domestic tourism, or one dominated by foreign visitors.

# your code here

# Load only domestic and foreign tourists
residency_data <- read_csv(here("datasets", "raw", "eurostat-nights_monthly.csv")) |>
  filter(
    c_resid %in% c("DOM", "FOR"),
    nace_r2 == "I551"
  ) |>
  mutate(year = lubridate::year(TIME_PERIOD)) |>
  filter(year == 2024)

# Sum nights by country and residency type
cross_tab <- residency_data |>
  group_by(geo, c_resid) |>
  summarise(total_nights = sum(values, na.rm = TRUE)) |>
  ungroup() |>

  # Convert DOM and FOR into columns
  pivot_wider(
    names_from = c_resid,
    values_from = total_nights
  ) |>

  # Calculate row percentages
  mutate(
    total = DOM + FOR,
    dom_percent = 100 * DOM / total,
    for_percent = 100 * FOR / total
  ) |>

  # Select some countries
  filter(geo %in% c("ES", "FR", "DE", "IT", "PT", "BE")) |>
  print()

# your comment here

# Portugal (PT) stands out because about 71% of hotel nights
# come from foreign visitors. This suggests that Portugal is
# highly dependent on international tourism.


# ---- 3. Correlation ---------------------------------------------------
# Collapse `joined` to one row per country in 2024 with three numeric
# indicators:
#   - annual_nights  = sum(nights)
#   - bed_places     = mean(bed_places)   # constant within a country-year
#   - nights_per_bed = annual_nights / bed_places
# Compute the correlation matrix of those three columns with
# cor(use = "pairwise.complete.obs") and identify the strongest and
# weakest pairs.

# your code here

# Create country-level indicators
country_data <- joined |>
  group_by(geo) |>
  summarise(

    # Total nights in 2024
    annual_nights = sum(nights, na.rm = TRUE),

    # Average bed places
    bed_places = mean(bed_places, na.rm = TRUE),

    # Nights per bed
    nights_per_bed = annual_nights / bed_places
  )

# Compute correlation matrix
correlation_matrix <- country_data |>
  select(annual_nights, bed_places, nights_per_bed) |>
  cor(use = "pairwise.complete.obs")

correlation_matrix

# Strongest correlation:
# annual_nights and bed_places (r = 0.999)

# Weakest correlation:
# bed_places and nights_per_bed (r = 0.119)

# ---- 4. Interpretation -------------------------------------------------
# In 4-6 sentences, describe the strongest correlation you found:
# direction, magnitude, and a plausible substantive reason. Note
# explicitly that correlation is NOT causation — Module III with Juan
# covers how to test causal claims formally.

# your comments here

# The strongest correlation is between annual_nights and bed_places
# (r = 0.999). The relationship is very strong and positive, meaning
# countries with larger hotel capacity also tend to have more tourist
# nights. This is reasonable because countries with strong tourism
# sectors usually build more accommodation infrastructure. The weakest
# relationship is between bed_places and nights_per_bed, which suggests
# that having more hotel beds does not necessarily mean they are used
# more efficiently.
