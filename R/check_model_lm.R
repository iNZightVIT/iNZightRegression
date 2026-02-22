#' Check All Regression Assumptions
#'
#' The master wrapper function that runs a full diagnostic suite on a linear model.
#' It checks assumptions in a hierarchical order:
#' 1. Linear Independence (Multicollinearity)
#' 2. Linearity
#' 3. Constant Variance
#' 4. Normality of Residuals
#'
#' If an earlier check fails (e.g., Linearity), the process stops immediately to
#' prevent misleading results in subsequent checks.
#'
#' @inheritParams check_model
#' @param model An object of class \code{lm}.
#' @param checks Character vector indicating which checks to run.
#'   Choices: \code{"all"} (default), \code{"linear_independence"},
#'   \code{"linearity"}, \code{"variance"}, \code{"normality"}.
#'
#' @return A list of results from all performed checks (invisible).
#' @export
#'
check_model_lm <- function(model, 
                        checks = c("all", "linear_independence", "linearity", "variance", "normality")) {

  # 1. Handle "All" shortcut
  if ("all" %in% checks) {
    checks <- c("linear_independence", "linearity", "variance", "normality")
  }
  
  # 2. Validate arguments
  checks <- match.arg(checks, 
                      choices = c("linear_independence", "linearity", "variance", "normality"), 
                      several.ok = TRUE)
  
  # 3. Enforce execution order
  # VIF -> Linearity -> Variance -> Normality
  execution_order <- c("linear_independence", "linearity", "variance", "normality")
  checks <- intersect(execution_order, checks)
  
  # Container for results
  all_results <- list()
  
  cat("=================================================\n")
  cat("   iNZight Regression Diagnostic Suite\n")
  cat("=================================================\n")
  
  # --- CONFIGURATION MAP ---
  check_map <- list(
    linear_independence = list(
      title = "CHECK: LINEAR INDEPENDENCE (Multicollinearity)",
      fun   = check_linear_independence
    ),
    linearity = list(
      title = "CHECK: LINEARITY",
      fun   = check_linearity
    ),
    variance = list(
      title = "CHECK: CONSTANT VARIANCE",
      fun   = check_variance
    ),
    normality = list(
      title = "CHECK: NORMALITY OF RESIDUALS",
      fun   = check_normality
    )
  )

  # 4. Run checks
  stop_triggered <- FALSE
  
  for (i in seq_along(checks)) {
    
    check_name <- checks[i]
    config <- check_map[[check_name]]
    
    # Print Title
    cat(sprintf("\n>> CHECK %d: %s\n", i, gsub("CHECK: ", "", config$title)))
    
    # Execute Function
    res <- config$fun(model)
    all_results[[check_name]] <- res
    
    # --- FAILURE CHECK ---
    # Check if the status is "FAILED"
    if (!is.null(res$status) && res$status == "FAILED" && i < length(checks)) {
      
      cat("\n[!] ASSUMPTION VIOLATION DETECTED.\n")
      
      # Print the suggestion if available
      if (!is.null(res$action)) {
        cat(sprintf("    Fix: %s\n", res$action))
      }
      
      # INTERACTIVE CHOICE: Stop or Continue?
      if (interactive()) {
        choice <- menu(c("Stop checks (Recommended)", "Continue anyway"),
                       title = "Assumption failed. Subsequent tests may be invalid. How would you like to proceed?")
        
        if (choice == 1 || choice == 0) {
          cat("[!] Process terminated by user.\n")
          stop_triggered <- TRUE
          break # EXIT THE LOOP
        } else {
          cat("[!] Proceeding with caution...\n")
        }
      } else {
        # Non-interactive mode (e.g., knitting): Just warn and continue
        cat("[!] Non-interactive mode: Continuing with caution.\n")
      }
      
    } else {
      # If passed (or not failed), standard pause
      pause_if_needed(checks, check_name)
    }
  }
  
  # 5. Summary Table
  print_summary_table(all_results)
  
  if (stop_triggered) {
    cat("\nNOTE: Process terminated early due to assumption failure.\n")
  }
  
  invisible(all_results)
}

# --- INTERNAL HELPERS ---

pause_if_needed <- function(selected_checks, current_check) {
  current_index <- match(current_check, selected_checks)
  if (current_index < length(selected_checks)) {
    readline(prompt = "\n  [Press <Enter> to continue to the next check] ")
  }
}

print_summary_table <- function(results) {
  cat("\n=================================================\n")
  cat("               FINAL SUMMARY\n")
  cat("=================================================\n")
  
  for (check_name in names(results)) {
    res <- results[[check_name]]
    status <- res$status
    if (is.null(status)) status <- "Unknown"
    
    # Print Status
    cat(sprintf("%-20s : %s\n", check_name, status))
    
    # If Failed, Print Action (Indented)
    if (status == "FAILED" && !is.null(res$action)) {
      cat(sprintf("   -> Fix: %s\n", res$action))
    }
  }
  cat("=================================================\n")
}