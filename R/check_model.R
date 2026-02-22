#' Check Regression Assumptions (Generic)
#'
#' A generic wrapper that detects the model type (Linear vs. Generalised Linear)
#' and dispatches the appropriate diagnostic checks.
#'
#' @param model A model object (e.g., from \code{lm} or \code{glm}).
#' @param ... Additional arguments passed to the specific model checker
#'   (e.g., \code{checks}).
#'
#' @return A list of results from the performed checks (invisible).
#' @export
#'
check_model <- function(model, ...) {
  
  # 1. Check for GLM first (because GLM objects also have class 'lm')
  if (inherits(model, "glm")) {
    return(check_model_glm(model, ...))
  }
  
  # 2. Check for LM
  if (inherits(model, "lm")) {
    return(check_model_lm(model, ...))
  }
  
  # 3. Fallback
  stop("Unsupported model class. Please provide an object of class 'lm' or 'glm'.")
}