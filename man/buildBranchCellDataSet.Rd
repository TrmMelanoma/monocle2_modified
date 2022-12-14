% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/BEAM.R
\name{buildBranchCellDataSet}
\alias{buildBranchCellDataSet}
\title{Build a CellDataSet that splits cells among two branches}
\usage{
buildBranchCellDataSet(
  cds,
  progenitor_method = c("sequential_split", "duplicate"),
  branch_states = NULL,
  branch_point = 1,
  branch_labels = NULL,
  stretch = TRUE
)
}
\arguments{
\item{cds}{CellDataSet for the experiment}

\item{progenitor_method}{The method to use for dealing with the cells prior to the branch}

\item{branch_states}{The states for two branching branches}

\item{branch_point}{The ID of the branch point to analyze. Can only be used
when \code{\link{reduceDimension}()} is called with \code{reduction_method
= "DDRTree"}.}

\item{branch_labels}{The names for each branching branch}

\item{stretch}{A logical flag to determine whether or not the pseudotime trajectory for each branch should be stretched to the same range or not}
}
\value{
a CellDataSet with the duplicated cells and stretched branches
}
\description{
Analyzing branches with \code{\link{BEAM}()} requires fitting two models to
the expression data for each gene. The full model assigns each cell to one of
the two outcomes of the branch, and the reduced model excludes this
assignment. \code{buildBranchBranchCellDataSet()} takes a CellDataSet object
and returns a version where the cells are assigned to one of two branches.
The branch for each cell is encoded in a new column, "Branch", in the pData
table in the returned CellDataSet.
}
