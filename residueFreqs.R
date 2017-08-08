
##########################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: residueFreqs.R
# Version: 0001 (06/08/17)
#
# Purpose: 	Generate residue frequency graphs that show the frequency with which 
#			each residue from the query TPR got aligned to a residue in a corresponding
#			significant result
#
# Assumptions:
#	1. 	TPR Regions contain 3 TPRs (where this isn't the case, the labels don't display 
#		correctly). This should be updated in a later version
#
# Strategy: 
#
# Error Behaviour:
#
# Usage: source("residueFreqs.R")
#
#	The working directory should contain:
#			
#	resFreq_1Blk.csv		
#	Extract from the DB with the following fields:
#	CONCAT(queryPdb, TPRR.chain, '_', TPRR.regionOrdinal) AS 'PDBChainRegion', 
#	A.queryResidueNo, COUNT(*)
#	
#	tprBoundaries.csv
#	Extract from the DB with the following fields:
#	CONCAT(TPRR.pdbCode, TPRR.chain, '_', TPRR.regionOrdinal) AS 'PDBChainRegion', 
#	TPR.startResidue, TPR.endResidue
#
##########################################################################################

# Read in a comma separated dataframe of residue frequencies
freqs <- read.csv("resFreq_1Blk5.csv", header=FALSE)
# Define the column names
colnames(freqs) <- c("PDBChainRegion","Residue","Frequency")
# Read in a comma separated dataframe of TPR boundaries
boundaries <- read.csv("tprBoundaries.csv", header=FALSE)
# Define the column names
colnames(boundaries) <- c("PDBChainRegion","Start","End")
# Set window size
win.graph(width=22, height=11)
# Loop through all factors (TPR Chain Regions)
for (i in levels(freqs$PDBChainRegion)){
	print(i)
	# Plot residue frequencies with title, axes, blue filled points
	plot(freqs[freqs$PDBChainRegion==i,2],freqs[freqs$PDBChainRegion==i,3], main = paste("Frequency with which residues of ", i, "featured in significant alignments for 3-TPR searches"), xlab="Residue numbers with TPR boundaries marked", ylab="Frequency", type="p", col="blue", pch=16)
	# Extract the PDB Chain Region only as this is a factor in boundaries
	region <- substr(i,1,7)
	# Add TPR start boundaries
	abline(v=boundaries[boundaries$PDBChainRegion==region,2])
	# Add TPR end boundaries
	abline(v=boundaries[boundaries$PDBChainRegion==region,3])
	# Get TPR start residues for this TPR
	tprStart <- boundaries[boundaries$PDBChainRegion==region,2]
	tprEnd <- boundaries[boundaries$PDBChainRegion==region,3]
	# Get residue frequencies for this TPR
	freqVector = freqs[freqs$PDBChainRegion==i,3]
	# Get minimum residue frequency
	minFreq = min(freqVector)
	# Get maximum residue frequency
	maxFreq = max(freqVector)
	
	# Define y position as 20% of the way from the lowest to the highest frequency
	y = minFreq + 0.2*(maxFreq-minFreq)	
	# Define x position as 50% of the way through the TPR
	x = tprStart + (tprEnd-tprStart)/2
	z = c(1:length(x))
	text(x, y,paste("TPR",z))
	
	# Save plot
	savePlot(filename=i, type="jpg")
}


