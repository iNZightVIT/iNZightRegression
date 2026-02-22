#' Check Linear Independence (Multicollinearity)
#'
#' Checks for high correlation between predictor variables using Variance Inflation
#' Factors (VIF). Handles both continuous predictors (standard VIF) and categorical
#' predictors (Generalised VIF).
#'
#' @param model An object of class \code{lm}.
#' @param show_plot Character string indicating whether to show a pairs plot.
#'   Options: \code{"pairs"} or \code{"none"}.
#'   If not provided, an interactive menu is displayed.
#'
#' @return A list of class \code{"inzcheck"} containing:
#' \describe{
#'   \item{check_name}{Name of the check ("Linear Independence").}
#'   \item{max_vif}{The maximum VIF score detected in the model.}
#'   \item{status}{"OK" or "FAILED".}
#'   \item{action}{Suggestion to remove correlated variables if failed.}
#' }
#'
#' @importFrom car vif
#' @export
#'
check_linear_independence <- function(model, show_plot = c("pairs", "none")) {
  
  # 1. PRE-CHECK: COUNT PREDICTORS
  if (length(variable.names(model)) < 3) {
    return(list(status = "N/A", message = "Only one predictor. Check not applicable."))
  }
  
  # 2. RUN NUMERICAL CHECK (VIF)
  vif_results <- run_vif_check(model)
  
  # 3. SHOW VISUALISATION (Interactive/Argument Logic)
  # We pass the argument down to the helper
  show_multicollinearity_plot(model, show_plot)
  
  # 4. GET USER DECISION
  final_result <- get_vif_decision(vif_results)
  
  class(final_result) <- "inzcheck"
  return(final_result)
}

# --- HELPER FUNCTIONS ---

run_vif_check <- function(model) {
  
  cat("\n--- Step 1: Numerical Check (VIF) ---\n")
  vif_vals <- car::vif(model)
  
  cat("Variance Inflation Factors:\n")
  print(vif_vals)
  
  # Check for Categorical variables
  # Check if result is a Matrix (meaning we have Factors/GVIF)
  if (is.matrix(vif_vals)) {
    # For GVIF, we look at the last column: GVIF^(1/(2*Df))
    # To make it comparable to standard VIF thresholds (5 or 10), we square it
    # Comparable VIF = (GVIF^(1/(2*Df)))^2
    standardised_vif <- vif_vals[, "GVIF^(1/(2*Df))"]^2
    max_vif <- max(standardised_vif)
    
    cat("\n(Note: Model contains factors. Using standardised GVIF^2.)\n")
    
  } else {
    # Standard Case (Numeric only)
    max_vif <- max(vif_vals)
  }
  
  list(scores = vif_vals, max_vif = max_vif)
}

show_multicollinearity_plot <- function(model, type = c("pairs", "none")) {
  cat("\n--- Step 2: Visual Check ---\n")
  
  # INTERACTIVE LOGIC:
  # If user didn't specify an argument (length > 1), ask them.
  if (length(type) > 1) {
    choice_idx <- menu(c("Pairs Plot (Scatterplot Matrix)", "Skip Plot"),
                       title = "Would you like to see the correlation plot?")
    if (choice_idx == 0) choice_idx <- 1
    type <- c("pairs", "none")[choice_idx]
  }
  
  # Validate
  type <- match.arg(type)
  
  # SWITCH LOGIC:
  switch(type,
         "pairs" = {
           # Extract predictors only
           model_data <- model$model
           predictors_only <- model_data[, -1, drop = FALSE]
           
           cat("Generating Pairs Plot...\n")
           pairs(predictors_only, main = "Predictor Correlation Matrix")
           
         },
         "none" = {
           cat("Skipping visualisation.\n")
         }
  )
}

get_vif_decision <- function(vif_results) {
  cat("\n--- Evidence Summary ---\n")
  cat(sprintf("Max VIF Detected: %.2f\n", vif_results$max_vif))
  
  choice <- menu(c("Status: OK (Pass)", "Status: FAILED (Violated)"),
                 title = "Do you see high correlations (VIF > 10)?")
  
  if (choice == 1 || choice == 0) {
    status <- "OK"
    action <- NULL
  } else {
    status <- "FAILED"
    # Identify bad variable (simple logic)
    # Note: This might need adjustment for the matrix case (GVIF)
    if (is.matrix(vif_results$scores)) {
      bad_var <- "variables with high GVIF"
    } else {
      bad_var <- names(which.max(vif_results$scores))
    }
    action <- sprintf("Multicollinearity detected. Consider removing %s.", bad_var)
  }
  
  list(check_name = "Linear Independence",
       max_vif = vif_results$max_vif,
       status = status,
       action = action)
}