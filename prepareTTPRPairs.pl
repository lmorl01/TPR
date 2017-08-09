#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: prepareTTPRPairs.pl
# Version: 0001 (09/08/17)
#
# Purpose: 	Given an export of TTPRs from the DB, and a given repeat length, 
# 			determine all possible TTPR series with the given repeat length 
#			and output all pairwise combinations of them in the format required by
#			FATCAT pairwise.
#			
#
# Assumptions:
#	1. ASSUME and REQUIRE the following sort order on the input file:
#			pdbCode, chain, regionOrdinal, tprOrdinal
#
# Strategy: 
#	1. 		The number of pairwise combinations of a set of size n = i = j can be 
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
# Usage: perl prepareTPPRPairs.pl repeats input.csv out.txt
#			
# Arguments: 
#	repeats 	The number of repeats (e.g. 3 for tripartite TPRs)
#	input.csv	The list of TTPRs containing the following fields:
#				TTPR ID
#				PDB Code
#				Chain
#				Region Ordinal
#				TPR Ordinal
#				Start Residue
#				End Residue
#	out.txt		The output file	containing all pairs	
#
#####################################################################################

use strict;
use warnings;

use TPRTools;

if (!(scalar @ARGV == 3 && $ARGV[0] =~ /^\d+$/)){
    die "Usage: perl prepareTPPRPairs.pl repeats input.csv out.txt\n";
}

my $repeats = $ARGV[0];
my $in = $ARGV[1];
my $out = $ARGV[2];
my %tprs;

open(INFILE, $in)
      or die "Can't open file $in\n"; 
open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";

while (my $line = <INFILE>) {
	my @values = split /,/, trim($line);
	my ($ttprId, $pdb, $chain, $region, $tprOrdinal, $start, $end) = @values;
	my $pdbChainRegion = $pdb.$chain.$region;
	
	if (!exists $tprs{$pdbChainRegion}){
		# First TPR in this PDB Chain Region
		$tprs{$pdbChainRegion} 			= [];				# Create an array for the PDB Chain Region
		$tprs{$pdbChainRegion}[0] 		= [];				# Create an array for the first TPR
		$tprs{$pdbChainRegion}[0][0] 	= $start;			# This will track the average start residue
		$tprs{$pdbChainRegion}[0][1] 	= $end;				# This will track the average end residue
	}
	
	else {
		# PDB Chain Region is known, simply add the TPR
		my @tpr = ($start, $end);
		push @{$tprs{$pdbChainRegion}}, \@tpr;
	}	
}	 

my @tprSeries;

foreach my $pdbChainRegion (sort keys %tprs){
	my $pdbCode = substr($pdbChainRegion,0,4);
	my $chain = substr($pdbChainRegion,4,1);
	for (my $i = 0; $i < scalar @{$tprs{$pdbChainRegion}} - $repeats + 1; $i++){
		my ($start, $end) = ($tprs{$pdbChainRegion}[$i][0], $tprs{$pdbChainRegion}[$i + $repeats - 1][1]);
		my $fatcatInput = $pdbCode.":(".$chain.":".$start."-".$end.")";
		push @tprSeries, $fatcatInput;
	}
}

# foreach (my $i = 0; $i < 50; $i++){
		# push @tprSeries, $i;		
# }	

foreach (my $i = 0; $i < @tprSeries; $i++){
	foreach (my $j = 0; $j < $i; $j++){
		print OUTFILE $tprSeries[$i], " ", $tprSeries[$j], "\n";
	}	
}	

