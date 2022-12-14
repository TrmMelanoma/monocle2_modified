% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/BEAM.R
\name{calABCs}
\alias{calABCs}
\title{Compute the area between curves (ABC) for branch-dependent genes}
\usage{
calABCs(
  cds,
  trend_formula = "~sm.ns(Pseudotime, df = 3)*Branch",
  branch_point = 1,
  trajectory_states = NULL,
  relative_expr = TRUE,
  stretch = TRUE,
  cores = 1,
  verbose = F,
  min_expr = 0.5,
  integer_expression = FALSE,
  num = 5000,
  branch_labels = NULL,
  ...
)
}
\arguments{
\item{cds}{a CellDataSet object upon which to perform this operation}

\item{trend_formula}{a formula string specifying the full model in differential expression tests (i.e. likelihood ratio tests) for each gene/feature.}

\item{branch_point}{the point where two branches diverge}

\item{trajectory_states}{States corresponding to two branches}

\item{relative_expr}{a logic flag to determine whether or not the relative gene expression should be used}

\item{stretch}{a logic flag to determine whether or not each branch should be stretched}

\item{cores}{the number of cores to be used while testing each gene for differential expression}

\item{verbose}{a logic flag to determine whether or not we should output detailed running information}

\item{min_expr}{the lower limit for the expressed gene}

\item{integer_expression}{the logic flag to determine whether or not the integer numbers are used for calculating the ABCs. Default is False.}

\item{num}{number of points on the fitted branch trajectories used for calculating the ABCs. Default is 5000.}

\item{branch_labels}{the name for each branch, for example, AT1 or AT2}

\item{...}{Additional arguments passed to buildBranchCellDataSet}
}
\value{
a data frame containing the ABCs (Area under curves) score as the first column and other meta information from fData
}
\description{
This function is used to calculate the ABC score based on the the nature spline curves fitted for each branch. ABC score is used to 
quantify the total magnitude of divergence between two branchs. By default, the ABC score is the area between two fitted spline curves. 
The ABC score can be used to rank gene divergence. When coupled with p-val calculated from the branchTest, it can be used to identify
potential major regulators for branch bifurcation.
}
