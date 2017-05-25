#################################################################################
# David Morley, MSc Bioinformatics 2015-2017 
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: prepareSimilarityMatrix.pl
# Version: 0001 (21/05/17 13:18)
#
# Purpose: 	Given the output from the FATCAT -alignPairs program, produce a 
#			similarity matrix of normalised RMSDs for analysis in R
#
# Assumptions:
#
# Strategy: 
#	1. Store similarity values in a matrix (array of arrays)
#	2. Store matrix indicies in a hash with pdb codes as keys
#	3. Track dimensions of matrix
#	4. Populate symmetrical halves of the matrix
#	5. Output the matrix
#
# Algorithm:
#	1. Read each line and extract the PDB codes.
#	2. Extract the fields rmsd, len1 and cov1
#	3. Calculate normalised RMSD as rmsd/sqrt(len1*cov1/100)
#	4. Check whether pdb code is a key in the hash; if not, increment matrix
#		dimension and add pdb code as a key referencing the next index
#	5. Add normalised RMSD to both symmetrical locations in the matrix
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: prepareSimilarityMatrix.pl input.file out.file
#			
# Arguments: 
#
#####################################################################################

use strict;
use warnings;

#use TPRTools;

if (!(scalar @ARGV == 2)){
    die "Usage: prepareSimilarityMatrix.pl input.file out.file\n";
}

my $in = $ARGV[0];
my $out = $ARGV[1];

my @similarityMatrix;
my $dim = 0;
my %indices;

open (INFILE, "<$in")
	or die "Can't open file ", $in, "\n";
	
open (OUTFILE, ">$out")
	or die "Can't create outputfile $out\n";

my $junk = <INFILE>;
$junk = <INFILE>;
$junk = <INFILE>;
	
while (my $line = <INFILE>){
	my @values = split(/\s+/, $line);
	my $pdb1 = substr($values[0],0,4);
	my $pdb2 = substr($values[1],0,4);
	my $norm_rmsd = ($values[5] == 0 || $values[7] == 0) ? 0 : $values[4]/(sqrt($values[5]*$values[7]/100));
	print "pdb 1: ", $pdb1, " pdb 2: ", $pdb2, " rmsd: ", $norm_rmsd, "\n";
	if (!exists($indices{$pdb1})){
		$indices{$pdb1} = $dim;
		$similarityMatrix[$dim][$dim] = 0;
		$dim++;
	}
	if (!exists($indices{$pdb2})){
		$indices{$pdb2} = $dim;
		$similarityMatrix[$dim][$dim] = 0;
		$dim++;
	}	
	$similarityMatrix[$indices{$pdb1}][$indices{$pdb2}] = $norm_rmsd;
	$similarityMatrix[$indices{$pdb2}][$indices{$pdb1}] = $norm_rmsd;
}	

foreach my $pdb (sort { $indices{$a} <=> $indices{$b} } keys %indices){
	print OUTFILE $pdb, " ";
} 
print OUTFILE "\n";

foreach (my $i = 0; $i < @similarityMatrix; $i++){
	foreach (my $j = 0; $j < @similarityMatrix; $j++){
		print OUTFILE $similarityMatrix[$i][$j], " ";
	}
	print OUTFILE "\n";
}
