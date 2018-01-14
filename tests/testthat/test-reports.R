context("Reports")
tmpdir <- tempdir()
tmpdata <- file.path(tmpdir, "data")
tmpinputs <- file.path(tmpdir, "inputs")
dir.create(tmpdata)
dir.create(tmpinputs)

data("simulation_results", package = "evaluator", envir = environment())
save(simulation_results, file = file.path(tmpdata, "simulation_results.rda"))
data("scenario_summary", package = "evaluator", envir = environment())
save(scenario_summary, file = file.path(tmpdata, "scenario_summary.rda"))
data("domain_summary", package = "evaluator", envir = environment())
save(domain_summary, file = file.path(tmpdata, "domain_summary.rda"))

res <- c("domains.csv", "qualitative_mappings.csv", "risk_tolerances.csv") %>%
  purrr::map(~ file.copy(system.file("extdata", .x, package = "evaluator"),
                         tmpinputs))
data("capabilities", envir = environment())
readr::write_csv(capabilities, file.path(tmpinputs, "capabilities.csv"))
data("qualitative_scenarios", envir = environment())
readr::write_csv(qualitative_scenarios, file.path(tmpinputs, "qualitative_scenarios.csv"))

file <- tempfile(fileext = ".html")

test_that("Analyze report renders", {

  result <- evaluate_promise(generate_report(input_directory = tmpinputs,
                                             results_directory = tmpdata,
                                             output_file = file, quiet = TRUE))
  expect_equivalent(normalizePath(result$result), normalizePath(file))
})

test_that("Risk Dashboard renders", {
  result <- evaluate_promise(risk_dashboard(input_directory = tmpinputs,
                                            results_directory = tmpdata,
                                            output_file = file,
                                            quiet = FALSE))
  expect_equivalent(normalizePath(result$result), normalizePath(file))
  # there should be no warnings
  expect_condition(result$warnings, regexp = NA)
})

unlink(c(tmpdata, tmpinputs), recursive = TRUE)