# Quick Start script for Evaluator workflow
# Process documented at https://evaluator.severski.net/articles/usage.html

# This script is intended as a starting point for taking a directory of
# inputs as created by evaluator::create_templates(), running simulations,
# saving the result details & summary files, and preparing the default static
# reports. The analyst MUST edit the template input files before running
# this script to produce valid results.

# Committing this script, along with the other contents of the base evaluator
# directory, to source control provides a reproducable set of inputs & outputs
# for a single analysis.

# Setup -------------------------------------------------------------------
library(evaluator)
if (!exists("base_dir") || !dir.exists(base_dir)) {
  stop("Set base_dir to your evaluator working directory before running this script.")
}

inputs_dir <- file.path(base_dir, "inputs")
results_dir <- file.path(base_dir, "results")

message("Beginning analysis run with input directory (", inputs_dir, ")",
        " and results directory (", results_dir, ")...")

# Load and Validate -------------------------------------------------------
message("Loading and validating inputs...")

domains <-  readr::read_csv(file.path(inputs_dir, "domains.csv"),
                            col_types = readr::cols(.default = readr::col_character()))
import_spreadsheet(file.path(inputs_dir, "survey.xlsx"), domains, inputs_dir)

qualitative_scenarios <- readr::read_csv(file.path(inputs_dir,
                                                   "qualitative_scenarios.csv"),
                                         col_types = readr::cols(.default = readr::col_character(),
                                                          scenario_id = readr::col_integer()))
mappings <- readr::read_csv(file.path(inputs_dir, "qualitative_mappings.csv"),
                            col_types = readr::cols(.default = readr::col_integer(),
                                             type = readr::col_character(),
                                             label = readr::col_character(),
                                             ml = readr::col_double()))
capabilities <- readr::read_csv(file.path(inputs_dir, "capabilities.csv"),
                                col_types = readr::cols(.default = readr::col_character(),
                                                 id = readr::col_integer()))
validate_scenarios(qualitative_scenarios, capabilities, domains, mappings)

# Encode ------------------------------------------------------------------
message("Encoding qualitative scenarios...")
quantitative_scenarios <- encode_scenarios(qualitative_scenarios, capabilities,
                                           mappings)

# Simulate ----------------------------------------------------------------
message("Running simulations...")
simulation_results <- run_simulations(quantitative_scenarios,
                                      simulation_count = 10000L)
save(simulation_results, file = file.path(results_dir, "simulation_results.rda"))

# Summarize ---------------------------------------------------------------
message("Summarizing results...")
summarize_to_disk(simulation_results = simulation_results,
                  domains = domains, results_dir)

# Report ---------------------------------------------------------------
message("Generating reports...")

## Risk Dashboard
risk_dashboard(inputs_dir, results_dir,
               file.path(results_dir, "risk_dashboard.html"))

## Long Form Report
generate_report(inputs_dir, results_dir,
                file.path(results_dir, "risk_report.docx"),
                format = "word")

message("Analysis complete.")
