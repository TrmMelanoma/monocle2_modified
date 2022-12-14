#' Clusters genes by pseudotime trend.
#'
#' This function takes a matrix of expression values and performs k-means 
#' clustering on the genes. 
#'
#' @param expr_matrix A matrix of expression values to cluster together. Rows 
#' are genes, columns are cells.
#' @param k How many clusters to create
#' @param method The distance function to use during clustering
#' @param ... Extra parameters to pass to pam() during clustering
#' @return a pam cluster object
#' @importFrom cluster pam
#' @importFrom stats as.dist cor
#' @export
#' @examples
#' \dontrun{
#' full_model_fits <- fitModel(HSMM[sample(nrow(fData(HSMM_filtered)), 100),],  
#'    modelFormulaStr="~sm.ns(Pseudotime)")
#' expression_curve_matrix <- responseMatrix(full_model_fits)
#' clusters <- clusterGenes(expression_curve_matrix, k=4)
#' plot_clusters(HSMM_filtered[ordering_genes,], clusters)
#' }
clusterGenes<-function(expr_matrix, k, method=function(x){as.dist((1 - cor(Matrix::t(x)))/2)}, ...){
  expr_matrix <- expr_matrix[rowSums(is.na(expr_matrix)) == 0,]
  expr_matrix <- expr_matrix[is.nan(rowSums(expr_matrix)) == FALSE,] 
  expr_matrix[is.na(expr_matrix)] <- 0
  n<-method(expr_matrix)
  clusters<-cluster::pam(n,k, ...)
  class(clusters)<-"list"
  clusters$exprs <- expr_matrix
  clusters
}

#' Cluster cells into a specified number of groups based on .
#' 
#' Unsupervised clustering of cells is a common step in many single-cell expression
#' workflows. In an experiment containing a mixture of cell types, each cluster might
#' correspond to a different cell type. This method takes a CellDataSet as input
#' along with a requested number of clusters, clusters them with an unsupervised 
#' algorithm (by default, density peak clustering), and then returns the CellDataSet with the 
#' cluster assignments stored in the pData table. When number of clusters is set 
#' to NULL (num_clusters = NULL), the decision plot as introduced in the reference 
#' will be plotted and the users are required to check the decision plot to select 
#' the rho and delta to determine the number of clusters to cluster. When the dataset 
#' is big, for example > 50 k, we recommend the user to use the Leiden or Louvain clustering 
#' algorithm which is inspired from phenograph paper. Note Louvain doesn't support the 
#' num_cluster argument but the k (number of k-nearest neighbors) is relevant to the final 
#' clustering number. The implementation of Louvain clustering is based on the Rphenograph
#' package but updated based on our requirement (for example, changed the jaccard_coeff 
#' function as well as adding louvain_iter argument, etc.)  The density peak clustering
#' method was removed because CRAN removed the densityClust package. Consequently,
#' the parameters skip_rho_sigma, inspect_rho_sigma, rho_threshold, delta_threshold,
#' peaks, and gaussian no longer have an effect.
#' @param cds the CellDataSet upon which to perform this operation
#' @param skip_rho_sigma A logic flag to determine whether or not you want to skip the calculation of rho / sigma 
#' @param num_clusters Number of clusters. The algorithm use 0.5 of the rho as the threshold of rho and the delta 
#' corresponding to the number_clusters sample with the highest delta as the density peaks and for assigning clusters
#' @param inspect_rho_sigma A logical flag to determine whether or not you want to interactively select the rho and sigma for assigning up clusters
#' @param rho_threshold The threshold of local density (rho) used to select the density peaks 
#' @param delta_threshold The threshold of local distance (delta) used to select the density peaks 
#' @param peaks A numeric vector indicates the index of density peaks used for clustering. This vector should be retrieved from the decision plot with caution. No checking involved.  
#' will automatically calculated based on the top num_cluster product of rho and sigma. 
#' @param gaussian A logic flag passed to densityClust function in densityClust package to determine whether or not Gaussian kernel will be used for calculating the local density
#' @param cell_type_hierarchy A data structure used for organizing functions that can be used for organizing cells 
#' @param frequency_thresh When a CellTypeHierarchy is provided, cluster cells will impute cell types in clusters that are composed of at least this much of exactly one cell type.
#' @param enrichment_thresh fraction to be multipled by each cell type percentage. Only used if frequency_thresh is NULL, both cannot be NULL
#' @param clustering_genes a vector of feature ids (from the CellDataSet's featureData) used for ordering cells
#' @param k number of kNN used in creating the k nearest neighbor graph for Leiden and Louvain clustering. The number of kNN is related to the resolution of the clustering result, bigger number of kNN gives low resolution and vice versa. Default to be 50
#' @param louvain_iter number of iterations used for Leiden and Louvain clustering. The clustering result gives the largest modularity score will be used as the final clustering result.  Default to be 1. 
#' @param weight A logic argument to determine whether or not we will use Jaccard coefficent for two nearest neighbors (based on the overlapping of their kNN) as the weight used for Louvain clustering. Default to be FALSE.
#' @param method method for clustering cells. Three methods are available, including leiden, louvian and DDRTree. By default, we use the leiden algorithm for clustering. 
#' @param verbose Verbose A logic flag to determine whether or not we should print the running details. 
#' @param resolution_parameter A real value that controls the resolution of the leiden clustering. Default is .1.
#' @param ... Additional arguments passed to densityClust
#' @return an updated CellDataSet object, in which phenoData contains values for Cluster for each cell
#' @importFrom igraph graph.data.frame cluster_louvain modularity membership
#' @import ggplot2
#' @importFrom RANN nn2
#' @references Rodriguez, A., & Laio, A. (2014). Clustering by fast search and find of density peaks. Science, 344(6191), 1492-1496. doi:10.1126/science.1242072
#' @references Vincent D. Blondel, Jean-Loup Guillaume, Renaud Lambiotte, Etienne Lefebvre: Fast unfolding of communities in large networks. J. Stat. Mech. (2008) P10008
#' @references Jacob H. Levine and et.al. Data-Driven Phenotypic Dissection of AML Reveals Progenitor-like Cells that Correlate with Prognosis. Cell, 2015. 
#' 
#' @useDynLib monocle
#' 
#' @importFrom leidenbase leiden_find_partition
#' @export

clusterCells <- function(cds, 
                         skip_rho_sigma = F, 
                         num_clusters = NULL, 
                         inspect_rho_sigma = F, 
                         rho_threshold = NULL, 
                         delta_threshold = NULL, 
                         peaks = NULL,
                         gaussian = T, 
                         cell_type_hierarchy=NULL,
                         frequency_thresh=NULL,
                         enrichment_thresh=NULL,
                         clustering_genes=NULL,
                         k = 50, 
                         louvain_iter = 1, 
                         weight = FALSE,
                         method = c('leiden', 'louvain', 'DDRTree'),
                         verbose = F,
                         resolution_parameter=.1,
                         ...) {
  method <- match.arg(method)
  
  if(ncol(cds) > 500000) {
    if(method %in% c('densityPeak', "DDRTree")) {
      warning('Number of cells in your data is larger than 50 k, clusterCells with densityPeak or DDRTree may crash. Please try to use the newly added Louvain clustering algorithm!')
    }
  }
    
  if(method == 'DDRTree') { # this option will be removed in future
    ################### DDRTREE START ###################
    # disp_table <- dispersionTable(cds)
    # ordering_genes <- row.names(subset(disp_table, dispersion_empirical >= 2 * dispersion_fit))
    # cds <- setOrderingFilter(cds, ordering_genes)
    use_for_ordering <- NA
    if (is.null(fData(cds)$use_for_ordering) == FALSE)
      old_ordering_genes <- row.names(subset(fData(cds), use_for_ordering)) 
    else
      old_ordering_genes <- NULL
    
    if (is.null(clustering_genes) == FALSE) 
      cds <- setOrderingFilter(cds, clustering_genes)
    
    cds <- reduceDimension(cds, 
                           max_components=2, #
                           residualModelFormulaStr=NULL,
                           reduction_method = "DDRTree",
                           verbose=verbose,
                           param.gamma=100,
                           ncenter=num_clusters, 
                           ...)
    pData(cds)$Cluster <- as.factor(cds@auxOrderingData[["DDRTree"]]$pr_graph_cell_proj_closest_vertex)
    
    if (is.null(old_ordering_genes) == FALSE)
      cds <- setOrderingFilter(cds, old_ordering_genes)
    
    if (is.null(cell_type_hierarchy) == FALSE)
      cds <- classifyCells(cds, cell_type_hierarchy, frequency_thresh, enrichment_thresh, "Cluster")
    
    return(cds)
   ################### DDRTREE END ###################
  } else if(method == 'leiden') { 
   ################### LEIDENALG START ###################
    data <- t(reducedDimA(cds))
    
    if(is.data.frame(data))
      data <- as.matrix(data)
    
    if(!is.matrix(data))
      stop("Wrong input data, should be a data frame of matrix!")
    
    if(k<1){
      stop("k must be a positive integer!")
    }else if (k > nrow(data)-2){
      stop("k must be smaller than the total number of points!")
    }
    
    if(verbose) {
      message("Run phenograph starts:","\n", 
          "  -Input data of ", nrow(data)," rows and ", ncol(data), " columns","\n",
          "  -k is set to ", k)
    }
    
    if(verbose) {
      cat("  Finding nearest neighbors...")
    }
    t1 <- system.time(neighborMatrix <- nn2(data, data, k + 1, searchtype = "standard")[[1]][,-1])
    if(verbose) {
      cat("DONE ~",t1[3],"s\n", " Compute jaccard coefficient between nearest-neighbor sets...")
    }
    
    t2 <- system.time(links <- jaccard_coeff(neighborMatrix, weight))
    
    if(verbose) {
      cat("DONE ~",t2[3],"s\n", " Build undirected graph from the weighted links...")
    }
    
    links <- links[links[,1]>0, ]
    relations <- as.data.frame(links)
    colnames(relations)<- c("from","to","weight")
    t3 <- system.time(g <- graph.data.frame(relations, directed=FALSE))
    
    if(verbose) {
      cat("DONE ~",t3[3],"s\n", " Run leiden clustering on the graph ...")
    }
    
    t_start <- Sys.time() 
    
    Q <- leidenbase::leiden_find_partition(g,
                                           partition_type='CPMVertexPartition',
                                           initial_membership=NULL,
                                           edge_weights=NULL,
                                           node_sizes=NULL,
                                           seed=NULL,
                                           resolution_parameter=resolution_parameter,
                                           num_iter=louvain_iter,
                                           verbose=verbose)
    optim_res <- list(membership=Q[['membership']], modularity=Q[['modularity']])
    
    t_end <- Sys.time()
    
    if(verbose) {
      message("Run phenograph DONE, totally takes ", t_end - t_start, " s.")
      cat("  Return a community class\n  -Modularity value:", optim_res[['modularity']],"\n")
      cat("  -Number of clusters:", length(unique(optim_res[['membership']])))
      cat("\n")
    }
      
    pData(cds)$Cluster <- factor(optim_res[['membership']]) 

    cds@auxClusteringData[["leiden"]] <- list(g = g, community = optim_res)

    return(cds)    
    
   ################### LEIDENALG END ###################
  }  else if(method == 'louvain'){
   ################### LOUVAIN START ###################
    data <- t(reducedDimA(cds))

    if(is.data.frame(data))
      data <- as.matrix(data)
    
    if(!is.matrix(data))
      stop("Wrong input data, should be a data frame of matrix!")
    
    if(k<1){
      stop("k must be a positive integer!")
    }else if (k > nrow(data)-2){
      stop("k must be smaller than the total number of points!")
    }
    
    if(verbose) {
      message("Run phenograph starts:","\n", 
              "  -Input data of ", nrow(data)," rows and ", ncol(data), " columns","\n",
              "  -k is set to ", k)
    }
    
    if(verbose) {
      cat("  Finding nearest neighbors...")
    }
    t1 <- system.time(neighborMatrix <- nn2(data, data, k + 1, searchtype = "standard")[[1]][,-1])
    if(verbose) {
      cat("DONE ~",t1[3],"s\n", " Compute jaccard coefficient between nearest-neighbor sets...")
    }
    
    t2 <- system.time(links <- jaccard_coeff(neighborMatrix, weight))
    
    if(verbose) {
      cat("DONE ~",t2[3],"s\n", " Build undirected graph from the weighted links...")
    }
    
    links <- links[links[,1]>0, ]
    relations <- as.data.frame(links)
    colnames(relations)<- c("from","to","weight")
    t3 <- system.time(g <- graph.data.frame(relations, directed=FALSE))
    
    # Other community detection algorithms: 
    #    cluster_walktrap, cluster_spinglass, 
    #    cluster_leading_eigen, cluster_edge_betweenness, 
    #    cluster_fast_greedy, cluster_label_prop  
    if(verbose) {
      cat("DONE ~",t3[3],"s\n", " Run louvain clustering on the graph ...")
    }
    
    t_start <- Sys.time() 
    Qp <- -1 # highest modularity score 
    optim_res <- NULL 
    
    for(iter in 1:louvain_iter) {
      Q <- cluster_louvain(g)
      
      if(verbose) {
        cat("Running louvain iteration ", iter, "...")
      }
      
      if(is.null(optim_res)) {
        Qp <- max(Q$modularity)
        optim_res <- Q
        
      } else {
        Qt <- max(Q$modularity)
        if(Qt > Qp){ #use the highest values for clustering 
          optim_res <- Q
          Qp <- Qt
        }
      }
    }
    
    t_end <- Sys.time()
    
    if(verbose) {
      message("Run phenograph DONE, totally takes ", t_end - t_start, " s.")
      cat("  Return a community class\n  -Modularity value:", modularity(optim_res),"\n")
      cat("  -Number of clusters:", length(unique(membership(optim_res))))
    }
    
    pData(cds)$Cluster <- factor(membership(optim_res)) 

    cds@auxClusteringData[["louvian"]] <- list(g = g, community = optim_res)

    return(cds)
   ################### LOUVAIN END ###################
  }
  else {
    stop('Cluster method ', method, ' is not implemented')
  }
}

#' #' Select features for constructing the developmental trajectory 
#' #' 
#' #' @param cds the CellDataSet upon which to perform this operation
#' #' @param num_cells_expressed A logic flag to determine whether or not you want to skip the calculation of rho / sigma 
#' #' @param num_dim Number of clusters. The algorithm use 0.5 of the rho as the threshold of rho and the delta 
#' #' corresponding to the number_clusters sample with the highest delta as the density peaks and for assigning clusters
#' #' @param rho_threshold The threshold of local density (rho) used to select the density peaks 
#' #' @param delta_threshold The threshold of local distance (delta) used to select the density peaks 
#' #' @param qval_threshold A logic flag passed to densityClust function in desnityClust package to determine whether or not Gaussian kernel will be used for calculating the local density
#' #' @param verbose Verbose parameter for DDRTree
#' #' @return an list contains a updated CellDataSet object after clustering and tree construction as well as a vector including the selected top significant differentially expressed genes across clusters of cells  
#' #' @references Rodriguez, A., & Laio, A. (2014). Clustering by fast search and find of density peaks. Science, 344(6191), 1492-1496. doi:10.1126/science.1242072
#' #' @export
#' dpFeature <- function(cds, num_cells_expressed = 5, num_dim = 5, rho_threshold = NULL, delta_threshold = NULL, qval_threshold = 0.01, verbose = F){
#'   #1. determine how many pca dimension you want:
#'   cds <- detectGenes(cds)
#'   fData(cds)$use_for_ordering[fData(cds)$num_cells_expressed > num_cells_expressed] <- T
#'   
#'   if(is.null(num_dim)){
#'     lung_pc_variance <- plot_pc_variance_explained(cds, return_all = T)
#'     ratio_to_first_diff <- diff(lung_pc_variance$variance_explained) / diff(lung_pc_variance$variance_explained)[1]
#'     num_dim <- which(ratio_to_first_diff < 0.1) + 1
#'   }
#'   
#'   #2. run reduceDimension with tSNE as the reduction_method
#'   # absolute_cds <- setOrderingFilter(absolute_cds, quake_id)
#'   cds <- reduceDimension(cds, return_all = F, max_components=2, norm_method = 'log', reduction_method = 'tSNE', num_dim = num_dim,  verbose = verbose)
#'   
#'   #3. initial run of clusterCells_Density_Peak
#'   cds <- clusterCells_Density_Peak(cds, rho_threshold = rho_threshold, delta_threshold = delta_threshold, verbose = verbose)
#'   
#'   #perform DEG test across clusters: 
#'   cds@expressionFamily <- negbinomial.size()
#'   pData(cds)$Cluster <- factor(pData(cds)$Cluster)
#'   clustering_DEG_genes <- differentialGeneTest(cds, fullModelFormulaStr = '~Cluster', cores = detectCores() - 2)
#'   clustering_DEG_genes_subset <- lung_clustering_DEG_genes[fData(cds)$num_cells_expressed > num_cells_expressed, ]
#'   
#'   #use all DEG gene from the clusters
#'   clustering_DEG_genes_subset <- clustering_DEG_genes_subset[order(clustering_DEG_genes_subset$qval), ]
#'   ordering_genes <- row.names(subset(clustering_DEG_genes, qval < qval_threshold))
#'   
#'   cds <- setOrderingFilter(cds, ordering_genes = lung_ordering_genes)
#'   cds <- reduceDimension(cds, norm_method = 'log', verbose = T)
#'   plot_cell_trajectory(cds, color_by = 'Time')
#'   
#'   return(list(new_cds = cds, ordering_genes = ordering_genes))
#' }
