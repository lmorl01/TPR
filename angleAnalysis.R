##########################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: angleAnalysis.R
# Version: 0001 (10/08/17)
#
# Purpose: 	Generate histograms of residue angles
#
# Usage: source("angleAnalysis.R")
#
#	The working directory should contain:
#			
#	abAngle.csv
#	aaAngle.csv
#	baAngle.csv		
#
##########################################################################################

# Set window size
win.graph(width=22, height=11)

# Read in intra-TPR AB Angles
abAngle <-scan("abAngle.csv")
# Define suitable breaks for AB angles
abBreaks <- seq(-180, -110, 2)
# Plot histogram of AB angles
hist(abAngle, breaks=abBreaks)
# Save AB Angle plot
savePlot(filename="abAngleDistribution", type="jpg")

# Read in intra-TPR AA Angles
aaAngle <-scan("aaAngle.csv")
# Define suitable breaks for AA angles
aaBreaks <- seq(-75, 75, 4)
# Plot histogram of AA angles
hist(aaAngle, breaks=aaBreaks)
# Save AA Angle plot
savePlot(filename="aaAngleDistribution", type="jpg")

# Read in intra-TPR BA Angles
baAngle <-scan("baAngle.csv")
# Define suitable breaks for AA angles
baBreaks <- seq(-200, -100, 2)
# Plot histogram of BA angles
hist(baAngle, breaks=baBreaks)
# Save AA Angle plot
savePlot(filename="baAngleDistribution", type="jpg")