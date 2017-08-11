#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: clusterKmds.R
# Version: 	0002 (21/05/17)
#			0003 (11/08/17) Updated to draw and save plots for a range of numbers
#							of clusters
#
# Purpose: 	Read a symmetric similarity matrix, perform clustering using kmeans
# 			Clustering is run with 2-7 clusters with a cluster plot drawn and
#			saved for each case 
#
#####################################################################################
pw <- read.table("pairs3.matrix", header=TRUE, check.names =FALSE);
rownames(pw) <- colnames(pw);
pw_dist <- as.dist(pw, diag=FALSE, upper=FALSE);
range <- seq(2, 7, 1)
colors <- c("red", "blue", "green", "black", "orange", "purple", "yellow")
for (i in range){
	kclus <- kmeans(pw,centers= i, iter.max=100, nstart=100);
	cmd <- cmdscale(pw_dist)
	plot(cmd, type="n", main=paste("Pairwise component analysis (PCA) of RMSD between Tripartite TPRs:", i, " clusters"))
	subrange <- seq(1,i,1)
	for (j in subrange){
		points(cmd[factor(kclus$cluster) == j, ], pch=16, col=colors[j])
	}
	savePlot(filename=paste("3TPRs-",i,"Clusters", sep=""), type="jpg")
}


