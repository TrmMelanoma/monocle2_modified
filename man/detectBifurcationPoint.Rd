% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/BEAM.R
\name{detectBifurcationPoint}
\alias{detectBifurcationPoint}
\title{Calculate divergence times for branch-dependent genes}
\usage{
detectBifurcationPoint(
  str_log_df = NULL,
  ILRs_threshold = 0.1,
  detect_all = T,
  cds = cds,
  Branch = "Branch",
  branch_point = NULL,
  branch_states = c(2, 3),
  stretch = T,
  cores = 1,
  trend_formula = "~sm.ns(Pseudotime, df = 3)",
  ILRs_limit = 3,
  relative_expr = TRUE,
  label_by_short_name = TRUE,
  useVST = FALSE,
  round_exprs = FALSE,
  output_type = "all",
  return_cross_point = T,
  file = "bifurcation_heatmap",
  verbose = FALSE,
  ...
)
}
\arguments{
\item{str_log_df}{the ILRs dataframe calculated from calILRs function. If this data.frame is provided, all the following parameters are ignored. Note that we need to only use the ILRs after the bifurcation point if we duplicated the progenitor cell state.}

\item{ILRs_threshold}{the ILR value used to determine the earliest divergence time point}

\item{detect_all}{a logic flag to determine whether or not genes without ILRs pass the threshold will still report a bifurcation point}

\item{cds}{CellDataSet for the experiment}

\item{Branch}{The column in pData used for calculating the ILRs (If not equal to "Branch", a warning will report)}

\item{branch_point}{The ID of the branch point to analyze. Can only be used when reduceDimension is called with method = "DDRTree".}

\item{branch_states}{The states for two branching branchs}

\item{stretch}{a logic flag to determine whether or not each branch should be stretched}

\item{cores}{Number of cores when fitting the spline curves}

\item{trend_formula}{the model formula to be used for fitting the expression trend over pseudotime}

\item{ILRs_limit}{the minimum Instant Log Ratio used to make the heatmap plot}

\item{relative_expr}{A logic flag to determine whether or not the relative expressed should be used when we fitting the spline curves}

\item{label_by_short_name}{label the rows of the returned matrix by gene_short_name (TRUE) or feature id (FALSE)}

\item{useVST}{A logic flag to determine whether or not the Variance Stablization Transformation should be used to stablize the gene expression.
When VST is used, the difference between two branchs are used instead of the log-ratio.}

\item{round_exprs}{A logic flag to determine whether or not the expression value should be rounded into integer}

\item{output_type}{A character either of "all" or "after_bifurcation". If "after_bifurcation" is used, only the time points after the bifurcation point will be selected. Note that, if Branch is set to "Branch", we will only use "after_bifurcation" since we duplicated the progenitor cells and the bifurcation should only happen after the largest mature level from the progenitor cells}

\item{return_cross_point}{A logic flag to determine whether or not only return the cross point}

\item{file}{the name for storing the data. Since the calculation of the Instant Log Ratio is very time consuming, so by default the result will be stored}

\item{verbose}{Whether to report verbose output}

\item{...}{Additional arguments passed to calILRs}
}
\value{
a vector containing the time for the bifurcation point with gene names for each value
}
\description{
Branch-dependent genes may diverge at different points in pseudotime. \code{detectBifurcationPoint()}
calculates these times. Although the branch times will be shaped by and distributed
around the branch point in the trajectory, upstream regulators tend to branch
earlier in pseudotime than their targets.
}
