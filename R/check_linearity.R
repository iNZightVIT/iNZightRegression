#' Check Linearity Assumption
#'
#' Verifies that the relationship between predictors and the response is linear.
#' Uses the Ramsey RESET test for statistical verification and a Residuals vs Fitted
#' plot for visual inspection.
#'
#' @param model An object of class \code{lm}.
#' @param test Character string indicating the test method.
#'   Default is \code{"reset"}.
#' @param show_plot Character string indicating visualisation preference.
#'   Options: \code{"resid"} (Residuals vs Fitted) or \code{"none"}.
#'   If not provided, an interactive menu is displayed.
#'
#' @return A list of class \code{"inzcheck"} containing:
#' \describe{
#'   \item{check_name}{Name of the check ("Linearity").}
#'   \item{test_used}{Name of the test performed.}
#'   \item{p_value}{P-value from the selected test.}
#'   \item{status}{"OK" or "FAILED".}
#'   \item{action}{Suggestion to add polynomial terms if failed.}
#' }
#'
#' @importFrom lmtest resettest
#' @export
#'
check_linearity <- function(model, 
                            test = c("reset"), 
                            show_plot = c("resid", "none")) {
  
  # 1. RUN STATISTICAL TEST
  test_result <- run_linearity_test(model, test)
  
  # 2. SHOW VISUALISATIONS
  show_linearity_plot(model, show_plot)
  
  # 3. GET USER DECISION
  final_result <- get_linearity_decision(test_result)
  
  class(final_result) <- "inzcheck"
  return(final_result)
}

# --- HELPER FUNCTIONS ---

run_linearity_test <- function(model, method = c("reset")) {
  cat("\n--- Step 1: Statistical Test ---\n")
  
  # INTERACTIVE LOGIC
  if (length(method) > 1) {
    choice_idx <- menu(c("Ramsey RESET Test"),
                       title = "Select a linearity test:")
    if (choice_idx == 0) choice_idx <- 1
    method <- c("reset")[choice_idx]
  }
  
  method <- match.arg(method)
  
  # SWITCH LOGIC
  result <- switch(method,
                   "reset" = {
                     # install.packages("lmtest")
                     # Run Ramsey RESET Test (power=2:3 is standard)
                     res <- lmtest::resettest(model, power = 2:3, type = "fitted")
                     list(method = "Ramsey RESET Test", p_value = res$p.value)
                   }
  )
  
  return(result)
}

show_linearity_plot <- function(model, type = c("resid", "none")) {
  cat("\n--- Step 2: Visual Check ---\n")
  
  # INTERACTIVE LOGIC
  if (length(type) > 1) {
    choice_idx <- menu(c("Residuals vs Fitted Plot", "Skip Plot"),
                       title = "Which diagnostic plot would you like to see?")
    if (choice_idx == 0) choice_idx <- 1
    type <- c("resid", "none")[choice_idx]
  }
  
  type <- match.arg(type)
  
  switch(type,
         "resid" = {
           cat("Generating Residuals vs Fitted Plot...\n")
           cat("Look for the RED line. Is it straight (linear) or curved (U-shaped)?\n")
           
           # Standard R plot #1 is Residuals vs Fitted
           plot(model, which = 1) 
           
         },
         "none" = {
           cat("Skipping visualisation.\n")
         }
  )
}

get_linearity_decision <- function(test_result) {
  cat("\n--- Evidence Summary ---\n")
  cat(sprintf("Test Used: %s\n", test_result$method))
  cat(sprintf("P-Value:   %.4f\n", test_result$p_value))
  
  choice <- menu(c("Status: OK (Pass)", "Status: FAILED (Violated)"),
                 title = "Based on the Plot (Red Line) and P-value, what is your decision?")
  
  if (choice == 1 || choice == 0) {
    status <- "OK"
    action <- NULL
  } else {
    status <- "FAILED"
    # Suggest polynomial terms as a fix
    action <- "Linearity violation detected. Try adding polynomial terms (e.g., poly(x, 2)) or transforming variables."
  }
  
  list(check_name = "Linearity",
       test_used = test_result$method,
       p_value = test_result$p_value,
       status = status,
       action = action)
}