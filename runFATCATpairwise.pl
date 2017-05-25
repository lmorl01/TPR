#################################################################################
# David Morley, MSc Bioinformatics 2015-2017 
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: runFATCATpairwise.pl
# Version: 0001 (14/05/17 20:22)
#
# Purpose: 	Given a directory of truncated PDB files, determine all pair-wise
#			combinations and run FATCAT-pairwise on each pair. Output the results
#			to a pairwise results directory
#
# Assumptions:
#
# Strategy: The number of pairwise combinations of a set of size n = i = j can be 
#			considered to be the set of combinations that occurs above the diagonal 
#			in a matrix	such as the following:
#
#				  i
#			  0 1 2 3 4
#			 0  x x x x
#			 1    x x x
#		   j 2      x x
#			 3        x
#			 4
#
#			It is clear that the number of pairwise combinations can be calculated by
#			squaring n to get the total number of elements in the matrix, subtracting n
#			to account for the diagonal and then halving the result to get only elements
#			above the diagonal.
#
#			Thus the number of pairwise combinations is given by N = (n^2-n)/2
#
#			The pairs can be iterated over with two nested for loops as follows:
#			for (i=1; i < n; i++)
#				for (j=0; j < i; j++)
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl runFATCATpairwise.pl fatcatDir pdbTruncDir outDir
#			
# Arguments: 
#	fatcatDir		The directory where the FATCAT script runFATCAT.sh is stored
#	pdbTruncDir		The directory containing the truncated PDB files
#	outDir			The directory to output the pairwise results to 		
#
#####################################################################################

use strict;
use warnings;

use TPRTools;

if (!(scalar @ARGV == 3)){
    die "Usage: perl runFATCATpairwise.pl fatcatDir pdbTruncDir outDir\n";
}

my $fatcatDir = $ARGV[0];
my $pdbDir = $ARGV[1];
my $outDir = $ARGV[2];

opendir DIR, $pdbDir;
my @files = readdir DIR;

foreach (my $i = 1; $i < @files; $i++){
	foreach (my $j = 0; $j < $i; $j++){
		system("bash $fatcatDir\/runFATCAT.sh -flexible -file1 $pdbDir\/$files[$i] -file2 $pdbDir\/$files[$j] -outFile $outDir\/$files[$i]_$files[$j].align");
	}
}





