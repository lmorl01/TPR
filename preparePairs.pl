#################################################################################
# David Morley, MSc Bioinformatics 2015-2017 
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: preparePairs.pl
# Version: 0001 (18/05/17 06:41)
#
# Purpose: 	Given a directory of FATCAT DB search results, extract the pdb code, 
#			chain and residue numbers for each result and output all possible
#			pairwise combinations in the following format:
# 				1a17:(A:22-125) 1elw:(A:2-101)
# 				1a17:(A:22-125) 1fch:(A:450-548)
# 				1a17:(A:22-125) 1hh8:(A:2-100)
# 				1a17:(A:22-125) 1ihg:(A:217-336)
# 				1elw:(A:2-101) 1fch:(A:450-548)
# 				1elw:(A:2-101) 1hh8:(A:2-100)
#				1elw:(A:2-101) 1ihg:(A:217-336)
# 				1fch:(A:450-548) 1hh8:(A:2-100)
# 				1fch:(A:450-548) 1ihg:(A:217-336)
# 				1hh8:(A:2-100) 1ihg:(A:217-336)
#
# Assumptions:
#
# Strategy: 
#	1. The PDB code can be extracted from the header line of the result file
#		where it is the name2 attribute in the AFPChain tag
#	2. The residue numbers and the chain IDs can be extracted from each 
#		<eqr> tag, where they are the pdbres2 and chain2 attributes respectively
#	3. With the above information we can compile a string of the form 1a17:(A:22-125)
#		which we will add to an array
#	4. The number of pairwise combinations of a set of size n = i = j can be 
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
# Usage: perl preparePairs.pl resultDir out.csv
#			
# Arguments: 
#	resultDir	The directory where the FATCAT search results are
#	out.csv		The csv output file	containing all pairs	
#
#####################################################################################

use strict;
use warnings;

use TPRTools;

if (!(scalar @ARGV == 2)){
    die "Usage: perl preparePairs.pl resultDir out.csv\n";
}

my $resDir = $ARGV[0];
my $out = $ARGV[1];

opendir DIR, $resDir;
my @files = readdir DIR;
my @alignmentRegions;

foreach (my $i = 0; $i < @files; $i++){
	
	if ($files[$i] =~ /.xml/){
		push @alignmentRegions, extractAlignmentRegion("$resDir\/$files[$i]");
	}			
}	

open (OUTFILE, ">$out")
	or die "Can't create outputfile $out\n";

foreach (my $i = 0; $i < @alignmentRegions; $i++){
	foreach (my $j = 0; $j < $i; $j++){
		print OUTFILE $alignmentRegions[$i], " ", $alignmentRegions[$j], "\n";
	}	
}	

