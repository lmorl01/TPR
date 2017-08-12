#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: clusterKmds.R
# Version: 	0002 (21/05/17)
#			0003 (11/08/17) Updated to draw and save plots for a range of numbers
#							of clusters
#			0004 (12/08/17) Fully commented
#
# Purpose: 	Read a symmetric similarity matrix, perform clustering using kmeans
# 			Clustering is run with 2-7 clusters with a cluster plot drawn and
#			saved for each case 
#
#####################################################################################

# Read the pairwise matrix
pw <- read.table("pairs1.matrix", header=TRUE, check.names =FALSE);
# Assign column names to be the same as row names
rownames(pw) <- colnames(pw);
# Convert it into a 'distance' matrix
pw_dist <- as.dist(pw, diag=FALSE, upper=FALSE);
# Define a range of cluster numbers to generate graphs for
range <- seq(2, 7, 1)
# Define enough colours for the different clusters
colors <- c("red", "blue", "green", "black", "orange", "purple", "yellow")
# Set window size
win.graph(width=22, height=11)
# Iterate through the clustering process for different numbers of clusters
for (i in range){
	# Perform k-means clustering
	kclus <- kmeans(pw,centers= i, iter.max=100, nstart=100);
	cmd <- cmdscale(pw_dist)
	# Create a plot to add clusters to
	plot(cmd, type="n", main=paste("Pairwise component analysis (PCA) of RMSD between Unitary TPRs:", i, " clusters"))
	# Iterate through the clusters
	subrange <- seq(1,i,1)
	for (j in subrange){
		# Plot the points for the cluster
		points(cmd[factor(kclus$cluster) == j, ], pch=16, col=colors[j])
	}
	# Save the plot
	savePlot(filename=paste("1TPR-",i,"Clusters", sep=""), type="jpg")
}


