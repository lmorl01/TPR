#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: ttprMotifAlignment.pl
# Version: 	0001	(12/08/17)
#
# Purpose: 	Read an extracted alignment of Tentative TPRs against the TPR motif from all search results
#			From this data, determine a consensus alignment of Tentative TPRs against the TPR motif
#
# Assumptions:
#
# Strategy: The TTPR Id will be a key into a hash that identifies an array representing
#			the TTPR. In that array, each element will be a further array representing 
#			a residue number associated that TTPR. The array representing a residue number
#			will contain the frequency with which that residue number was assigned to each
#			motif number among all the analyses. e.g. in the following example, in TTPR 710,
#			residue 28 was mapped to motif number 1 in 22 out of 24 cases and likewise for 
#			residue 29 to motif number 2. Element [0] is a flag showing whether the remainder
#			if populated or empty:
#
#							[0]		[ 1][ 2][3][4][5][6][7] ... [34]
#			710 --> ...	
#					[27]	[0]		[ 0][ 0][0][0][0][0][0] ... [ 0]	
#					[28]	[1]		[22][ 0][0][0][1][0][1] ... [ 0]
#					[29]	[1]		[ 0][22][0][1][0][0][1] ... [ 0]
#					...
#					...
#
# Error Behaviour:
# 	1. Print usage instructions if incorrect number of arguments
#
# Usage: perl ttprMotifAlignment.pl ttprMotifAlign.csv ttprConsensusMotifs.sql
#			
# Arguments: 
#	ttprMotifAlign.csv extracted from the DB using getTTPRMotifData.sql
#	ttprConsensusMotifs.sql for loading the output into the DB
#
#####################################################################################

use strict;
use warnings;

use TPRTools;

sub getMode($);

if (!(scalar @ARGV == 2)){
    die "Usage: perl ttprMotifAlignment.pl ttprMotifAlign.csv ttprConsensusMotifs.sql\n";
}

my $in = $ARGV[0];
my $out = $ARGV[1];

open (INFILE, "<$in")
	or die "Can't open file ", $in, "\n";

open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";

my $count = 0;
my %ttprs;
	 
while (my $line = <INFILE>){
	my @values = split /,/, trim($line);
	my ($ttprId, $pdbCode, $chain, $regionOrdinal, $tprOrdinal, $ttprStart, $ttprEnd, $residueNo, $motifNo, $queryPdb, $queryRegion, $queryStartTpr, $queryEndTpr)
		= @values;
	if (!defined($ttprs{$ttprId})){
		$ttprs{$ttprId} = [];
		push @{$ttprs{$ttprId}}, [(0)x35] for (0..$ttprEnd);	# Initialize zero array, 35 x $ttprEnd
	}
	$ttprs{$ttprId}[$residueNo][0] = 1;							# Flag shows there's some content here
	$ttprs{$ttprId}[$residueNo][$motifNo]++;
	$count++;
}

foreach my $ttprId (sort keys %ttprs){
	#print "Processing TTPR $ttprId\n";
	for (my $i = 0; $i < scalar @{$ttprs{$ttprId}}; $i ++){
		if ($ttprs{$ttprId}[$i][0] == 1){
			my ($modalMotifIndex, $maxFreq) = (0,0);
			# We ignore the first number
			for (my $j = 1; $j < scalar @{$ttprs{$ttprId}[$i]}; $j++){
			if ($ttprs{$ttprId}[$i][$j] > $maxFreq){
				$maxFreq = $ttprs{$ttprId}[$i][$j];
				$modalMotifIndex = $j;
				}
			}			
			print OUTFILE "INSERT INTO TTPRMotifAlignment (ttprId, motifNo, residueNo) VALUES ($ttprId,$modalMotifIndex,$i);\n";
		}
	}
}

print "$count lines processed\n";





