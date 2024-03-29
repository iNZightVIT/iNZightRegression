% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model_comp.R
\name{compare_models}
\alias{compare_models}
\alias{compare_models.default}
\alias{compare_models.svyglm}
\title{Compare regression models using AIC and BIC.}
\usage{
compare_models(x, ...)

\method{compare_models}{default}(x, ...)

\method{compare_models}{svyglm}(x, ...)
}
\arguments{
\item{x}{a regression model (lm, glm, svyglm, ...)}

\item{...}{other models}
}
\value{
an `inzmodelcomp` object containing model comparison statistics
}
\description{
Obtain a quick model comparison matrix for a selection of models
}
\section{Methods (by class)}{
\itemize{
\item \code{compare_models(default)}: default method

\item \code{compare_models(svyglm)}: method for survey GLMs

}}
\examples{
m0 <- lm(Sepal.Length ~ 1, data = iris)
m1 <- lm(Sepal.Length ~ Sepal.Width, data = iris)
m2 <- lm(Sepal.Length ~ Sepal.Width + Species, data = iris)
compare_models(m0, m1, m2)
}
\author{
Tom Elliott
}
