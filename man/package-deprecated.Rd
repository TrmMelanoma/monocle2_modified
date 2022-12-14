% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotting.R
\name{plot_spanning_tree}
\alias{plot_spanning_tree}
\title{Plots the minimum spanning tree on cells.
This function is deprecated.}
\usage{
plot_spanning_tree(
  cds,
  x = 1,
  y = 2,
  color_by = "State",
  show_tree = TRUE,
  show_backbone = TRUE,
  backbone_color = "black",
  markers = NULL,
  show_cell_names = FALSE,
  cell_size = 1.5,
  cell_link_size = 0.75,
  cell_name_size = 2,
  show_branch_points = TRUE
)
}
\arguments{
\item{cds}{CellDataSet for the experiment}

\item{x}{the column of reducedDimS(cds) to plot on the horizontal axis}

\item{y}{the column of reducedDimS(cds) to plot on the vertical axis}

\item{color_by}{the cell attribute (e.g. the column of pData(cds)) to map to each cell's color}

\item{show_tree}{whether to show the links between cells connected in the minimum spanning tree}

\item{show_backbone}{whether to show the diameter path of the MST used to order the cells}

\item{backbone_color}{the color used to render the backbone.}

\item{markers}{a gene name or gene id to use for setting the size of each cell in the plot}

\item{show_cell_names}{draw the name of each cell in the plot}

\item{cell_size}{The size of the point for each cell}

\item{cell_link_size}{The size of the line segments connecting cells (when used with ICA) or the principal graph (when used with DDRTree)}

\item{cell_name_size}{the size of cell name labels}

\item{show_branch_points}{Whether to show icons for each branch point (only available when reduceDimension was called with DDRTree)}
}
\value{
a ggplot2 plot object
}
\description{
This function arranges all of the cells in the cds in a tree and
predicts their location based on their pseudotime value
}
\examples{
\dontrun{
library(HSMMSingleCell)
HSMM <- load_HSMM()
plot_cell_trajectory(HSMM)
plot_cell_trajectory(HSMM, color_by="Pseudotime", show_backbone=FALSE)
plot_cell_trajectory(HSMM, markers="MYH3")
}
}
\seealso{
plot_cell_trajectory
}
