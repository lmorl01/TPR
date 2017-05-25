#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: cluster.R
# Version: 0002 (21/05/17 19:37)
#
# Purpose: 	Read a symmetric similarity matrix, perform clustering using hclust
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
hc <- hclust(pw_dist, method="average");
plot(hc, cex=0.7);