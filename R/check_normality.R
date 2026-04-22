#' Check Normality of Residuals
#'
#' Assesses whether the residuals of a linear model follow a normal distribution.
#' It combines a statistical test (Shapiro-Wilk or Kolmogorov-Smirnov) with
#' diagnostic plots (Q-Q Plot or Histogram).
#'
#' @param model An object of class \code{lm}.
#' @param test Character string indicating which statistical test to use.
#'   Options: \code{"shapiro"} (default) or \code{"ks"}.
#'   If not provided, an interactive menu is displayed.
#' @param show_plot Character string indicating visualisation preference.
#'   Options: \code{"qq"}, \code{"hist"}, or \code{"both"}.
#'   If not provided, an interactive menu is displayed.
#'
#' @return A list of class \code{"inzcheck"} containing:
#' \describe{
#'   \item{check_name}{Name of the check ("Normality").}
#'   \item{test_used}{Name of the test performed.}
#'   \item{p_value}{P-value from the selected test.}
#'   \item{status}{"OK" or "FAILED" based on user decision.}
#'   \item{action}{Suggested fix action if the check fails.}
#' }
#'
#' @importFrom iNZightRegression iNZightQQplot histogramArray
#' @export
#'
check_normality <- function(model, 
                            test = c("shapiro", "ks"), 
                            show_plot = c("qq", "hist", "both")) {
  
  # 1. RUN STATISTICAL TEST
  # We pass the 'test' argument down to the helper
  test_result <- run_normality_test(residuals(model), test)
  
  # 2. SHOW VISUALISATIONS
  # We pass the 'show_plot' argument down
  show_normality_plots(model, show_plot)
  
  # 3. GET USER DECISION
  final_result <- get_user_decision(test_result)
  
  class(final_result) <- "inzcheck"
  return(final_result)
}

# --- HELPER FUNCTIONS ---

run_normality_test <- function(resids, method = c("shapiro", "ks")) {
  cat("\n--- Step 1: Statistical Test ---\n")
  
  # FEEDBACK: Check if user provided a specific choice
  # If 'method' has length > 1, it means the user stuck with the default vector
  # so we show the menu.
  if (length(method) > 1) {
    choice_idx <- menu(c("Shapiro-Wilk Test", "Kolmogorov-Smirnov Test"),
                       title = "Select a normality test:")
    # Map menu number back to string name
    if (choice_idx == 0) choice_idx <- 1
    method <- c("shapiro", "ks")[choice_idx]
  }
  
  # Validate the choice
  method <- match.arg(method)
  
  # FEEDBACK: Use switch() instead of if-else chain
  # FEEDBACK: Extract p-value inside the block
  result <- switch(method,
                   "shapiro" = {
                     res <- shapiro.test(resids)
                     list(method = "Shapiro-Wilk", p_value = res$p.value)
                   },
                   "ks" = {
                     # jitter used to handle ties safely
                     res <- ks.test(jitter(resids), "pnorm", mean(resids), sd(resids))
                     list(method = "Kolmogorov-Smirnov", p_value = res$p.value)
                   }
  )
  
  return(result)
}

show_normality_plots <- function(model, type = c("qq", "hist", "both")) {
  cat("\n--- Step 2: Visual Check ---\n")
  
  # Interactive Logic: If default (length > 1), show menu
  if (length(type) > 1) {
    choice_idx <- menu(c("iNZight Q-Q Plot", "Histogram Array", "Both"),
                       title = "Which plot would you like to see?")
    if (choice_idx == 0) choice_idx <- 1
    type <- c("qq", "hist", "both")[choice_idx]
  }
  
  # Validate choice
  type <- match.arg(type)
  
  if (type == "qq" || type == "both") {
    cat("Generating Q-Q Plot...\n")
    iNZightRegression::iNZightQQplot(model)
  }
  
  if (type == "both") {
    readline("  >> Press [Enter] for Histogram...")
  }
  
  if (type == "hist" || type == "both") {
    cat("Generating Histogram Array...\n")
    iNZightRegression::histogramArray(model)
  }
}

get_user_decision <- function(test_result) {
  cat("\n--- Evidence Summary ---\n")
  cat(sprintf("Test Used: %s\n", test_result$method))
  cat(sprintf("P-Value:   %.4f\n", test_result$p_value))
  
  choice <- menu(c("Status: OK (Pass)", "Status: FAILED (Violated)"),
                 title = "Based on the Evidence, what is your decision?")
  
  if (choice == 1 || choice == 0) {
    status <- "OK"
    action <- NULL
  } else {
    status <- "FAILED"
    action <- "WARNING: Normality violation. P-values and CI may be inaccurate."
  }
  
  list(check_name = "Normality",
       test_used = test_result$method,
       p_value = test_result$p_value,
       status = status,
       action = action)
}