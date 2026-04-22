#' Check Constant Variance
#'
#' Checks if the variance of the error terms is constant across all levels of the
#' independent variables.
#' It combines a statistical test (Breusch-Pagan or White) with
#' diagnostic plots (Residuals vs Fitted or Scale-Location plot).
#' If the check fails, it suggests a Box-Cox transformation.
#'
#' @param model An object of class \code{lm}.
#' @param test Character string indicating the test method.
#'   Options: \code{"bp"} (default) or \code{"white"}.
#'   If not provided, an interactive menu is displayed.
#' @param show_plot Character string indicating visualisation preference.
#'   Options: \code{"residual"}, \code{"scale"}, or \code{"none"}.
#'   If not provided, an interactive menu is displayed.
#'
#' @return A list of class \code{"inzcheck"} containing:
#' \describe{
#'   \item{check_name}{Name of the check ("Constant Variance").}
#'   \item{test_used}{Name of the test performed.}
#'   \item{p_value}{P-value from the selected test.}
#'   \item{status}{"OK" or "FAILED".}
#'   \item{action}{Specific Box-Cox suggestion (e.g., "Log Transformation") if failed.}
#' }
#'
#' @importFrom lmtest bptest
#' @importFrom skedastic white
#' @importFrom MASS boxcox
#' @export
#'
check_variance <- function(model, 
                                   test = c("bp", "white"), 
                                   show_plot = c("residual", "scale", "none")) {
  
  # 1. RUN STATISTICAL TEST
  test_result <- run_variance_test(model, test)
  
  # 2. SHOW VISUALISATIONS
  show_variance_plot(model, show_plot)
  
  # 3. GET USER DECISION
  final_result <- get_variance_decision(model, test_result)
  
  class(final_result) <- "inzcheck"
  return(final_result)
}

# --- HELPER FUNCTIONS ---

run_variance_test <- function(model, method = c("bp", "white")) {
  cat("\n--- Step 1: Statistical Test ---\n")
  
  if (length(method) > 1) {
    choice_idx <- menu(c("Breusch-Pagan Test (Recommended)", "White's Test"),
                       title = "Select a variance test:")
    if (choice_idx == 0) choice_idx <- 1
    method <- c("bp", "white")[choice_idx]
  }
  
  method <- match.arg(method)
  
  result <- switch(method,
                   "bp" = {
                     #if (!requireNamespace("lmtest", quietly = TRUE)) {
                       #stop("Package 'lmtest' is required for the Breusch-Pagan test.")
                     #}
                     res <- lmtest::bptest(model)
                     list(method = "Breusch-Pagan Test", p_value = res$p.value)
                   },
                   "white" = {
                     #if (!requireNamespace("skedastic", quietly = TRUE)) {
                       #stop("Package 'skedastic' is required for White's test.")
                     #}
                     res <- skedastic::white(model, interactions = TRUE)
                     list(method = "White's Test", p_value = res$p.value)
                   }
  )
  return(result)
}

show_variance_plot <- function(model, type = c("residual", "scale", "none")) {
  cat("\n--- Step 2: Visual Check ---\n")
  
  if (length(type) > 1) {
    choice_idx <- menu(c("Residuals vs Fitted (Classic)", 
                         "Scale-Location (Specific for Variance)", 
                         "Skip Plot"),
                       title = "Which diagnostic plot would you like to see?")
    if (choice_idx == 0) choice_idx <- 1
    type <- c("residual", "scale", "none")[choice_idx]
  }
  
  type <- match.arg(type)
  
  switch(type,
         "residual" = {
           cat("Generating Residuals vs Fitted Plot...\n")
           cat("Check for 'Fan Shape': Variance shouldn't grow as Fitted Values increase.\n")
           # Plot 1: Residuals vs Fitted
           plot(model, which = 1)
         },
         "scale" = {
           cat("Generating Scale-Location Plot...\n")
           cat("Check for upward trend: The red line should be roughly horizontal.\n")
           # Plot 2: Scale-Location (sqrt of standardised residuals)
           plot(model, which = 3)
         },
         "none" = {
           cat("Skipping visualisation.\n")
         }
  )
}

get_variance_decision <- function(model, test_result) {
  cat("\n--- Evidence Summary ---\n")
  cat(sprintf("Test Used: %s\n", test_result$method))
  cat(sprintf("P-Value:   %.4f\n", test_result$p_value))
  
  choice <- menu(c("Status: OK (Pass)", "Status: FAILED (Violated)"),
                 title = "Based on the Plot and P-value, what is your decision?")
  
  if (choice == 1 || choice == 0) {
    status <- "OK"
    action <- NULL
  } else {
    status <- "FAILED"
    cat("\nCalculating suggested remedy (Box-Cox)...\n")
    action <- get_boxcox_suggestion(model)
  }
  
  list(check_name = "Constant Variance",
       test_used = test_result$method,
       p_value = test_result$p_value,
       status = status,
       action = action)
}

# Fix Suggestion

get_boxcox_suggestion <- function(model) {
  #if (!requireNamespace("MASS", quietly = TRUE)) {
    #return("Constant Variance Violated (Install 'MASS' package for specific fix suggestions).")
  #}
  
  # Safety check: Box-Cox requires strictly positive Y
  y_vals <- model.response(model.frame(model))
  
  if (any(y_vals <= 0)) {
    return("Constant Variance Violated. (Box-Cox skipped: Response variable contains non-positive values).")
  }
  
  bc <- MASS::boxcox(model, plotit = FALSE, lambda = seq(-2, 2, 1/10))
  max_idx <- which.max(bc$y)
  optimal_lambda <- bc$x[max_idx]
  
  suggestion <- "Null"
  
  if (abs(optimal_lambda - 1) < 0.25) {
    suggestion <- "None needed (Lambda approx 1)"
  } else if (abs(optimal_lambda - 0.5) < 0.25) {
    suggestion <- "Square Root Transformation (sqrt(Y))"
  } else if (abs(optimal_lambda - 0) < 0.25) {
    suggestion <- "Log Transformation (log(Y))"
  } else if (abs(optimal_lambda - (-1)) < 0.25) {
    suggestion <- "Inverse Transformation (1/Y)"
  } else {
    suggestion <- sprintf("Power Transformation (Y^%.2f)", optimal_lambda)
  }
  
  return(paste("Constant Variance Violated Suggested Fix: Apply", suggestion))
}