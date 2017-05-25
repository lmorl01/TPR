#################################################################################
# David Morley, MSc Bioinformatics 2015-2017 
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: cluster.R
# Version: 0002 (21/05/17 19:37)
#
# Purpose: 	Read a symmetric similarity matrix, perform clustering using kmeans
#			and draw dendrogram
#
# Assumptions:
#
# Strategy: 
#
# Algorithm:
#
# Error Behaviour:
#
# Usage: 
#			
# Arguments: 
#
#####################################################################################
pw <- read.table("1a17_TPR_1-3_pw2.matrix", header=TRUE, check.names =FALSE);
rownames(pw) <- colnames(pw);
pw_dist <- as.dist(pw, diag=FALSE, upper=FALSE);
kclus <- kmeans(pw,centers= 3, iter.max=100, nstart=100);
cmd <- cmdscale(pw_dist);
plot(cmd, type="n");
points(cmd[factor(kclus$cluster) == 1, ], pch=2)
points(cmd[factor(kclus$cluster) == 2, ], pch=3)
points(cmd[factor(kclus$cluster) == 3, ], pch=1)

