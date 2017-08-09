#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: extractTPRs.pl
# Version: 	
# 0001 (05/08/17)
# 0002 (08/08/17)	Tidied and debugged. TPR ordinals associated with
# region ordinals > 1 not output correctly. Added TTPR Parameter ID, TPR Tolerance 
# and Region Tolerance as input parameters for the script
# 0003 (09/08/17) Criteria for identifying duplicate TPRs loosened
# from and AND requirement that both start and end residues be within TPR tolerance 
# of one another to an OR requirement than one or the other has to be within
# TPR tolerance. This is because TPRs seem to be more divergent	towards the end of 
# the motif and seem to be more likely to to feature insertions near the end. 
# With an AND requirement, duplicate TPRs were getting correctly matched on the 
# start residues, but the match was getting lost on the end residues, resuting in
# the TPRs getting classed as different, despite having the same modal start residues
#
# Purpose: 	Given an extract of significant results from the Results table,
#			which will contain redundancy, determine a non-redundant set of  
#			tentative TPR Regions and their associated tentative TPRs. 
#			Write SQL to load these details into the TentativeTPRRegion and
#			TentativeTPR tables
#
# Assumptions:
#	1. 	Two series of TPRs are considered to belong to two different TPR regions
#		if they are separated by more than 34 amino acids that are not part of
#		any TPRs
#
# Table Structures:
# 	
# TentativeTPR
#
# +--------------+---------+------+-----+---------+----------------+
# | Field        | Type    | Null | Key | Default | Extra          |
# +--------------+---------+------+-----+---------+----------------+
# | ttprId       | int(11) | NO   | PRI | NULL    | auto_increment |
# | ttprParamId  | int(11) | NO   | MUL | NULL    | auto_increment |
# | pdbCode      | char(4) | NO   | MUL | NULL    |                |
# | chain        | char(5) | NO   |     | NULL    |                |
# | regionOrdinal| int(11) | NO   |     | NULL    |                |
# | tprOrdinal   | int(11) | YES  |     | NULL    |                |
# | startMean    | float   | YES  |     | NULL    |                |
# | startMedian  | float   | YES  |     | NULL    |                |
# | startMode    | int(11) | YES  |     | NULL    |                |
# | startMax     | int(11) | YES  |     | NULL    |                |
# | startMin     | int(11) | YES  |     | NULL    |                |
# | endMean      | float   | YES  |     | NULL    |                |
# | endMedian    | float   | YES  |     | NULL    |                |
# | endMode      | int(11) | YES  |     | NULL    |                |
# | endMax       | int(11) | YES  |     | NULL    |                |
# | endMin       | int(11) | YES  |     | NULL    |                |
# | abAngle      | float   | YES  |     | NULL    |                |
# | aaAngle      | float   | YES  |     | NULL    |                |
# | baAngle      | float   | YES  |     | NULL    |                |
# +--------------+---------+------+-----+---------+----------------+
#
# Strategy: 
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl extractTPRs.pl ttprParamId tprTolerance regionTolerance significantResults.csv out.sql
#			
# Arguments: 
#	significantResults.csv		
#	This should be the following fields comma separated:
#	resultId, queryPdb, queryChain, resultPdb, resultChain, tprOrdinal, startQuery, 
#	endQuery, startResult, endResult
#
#	out.sql				
#	The SQL output file for loading this data
#	
#####################################################################################

use strict;
use warnings;

use TPRTools;

sub calculateMedian($);
sub calculateMode($);
sub getMax($);
sub getMin($);

if (!(scalar @ARGV == 5 && $ARGV[0] =~ /^\d+$/ && $ARGV[1] =~ /^\d+$/ && $ARGV[2] =~ /^\d+$/)){
	print "Usage: perl extractTPRs.pl ttprParamId tprTolerance regionTolerance significantResults.csv out.sql\n";
	print "ttprParamId should be a key in the DB table TTPRParameters\n";
	print "Recommended parameters:\nTPR Tolerance : 23\nRegion Tolerance: 34\n";
	exit;
}

my $ttprParamId = $ARGV[0];
my $TPR_TOLERANCE = $ARGV[1];
my $REGION_TOLERANCE = $ARGV[2];
my $in = $ARGV[3];
my $out = $ARGV[4];
my $testPdb = "2if4A";

my %tprs;

open(INFILE, $in)
      or die "Can't open file $in\n"; 
open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";
	 
################################################################################
# STAGE 1: READ IN ALL OF THE TENTATIVE TPRS FROM THE INPUT FILE
################################################################################
#
# DATA STRUCTURES
#
# PDB Codes and chains are concatenated to create a PDBChain
#
# Each PDBChain is a key in the %tprs hash pointing to an array reference
# 
# Each array represents a TPR associated with the PDB Chain.
#
# The TPR is a consensus built from multiple TPRs matched from the results
#
# The TPR array contains five elements:
# [0]	The average start residue
# [1]	The average end residue
# [2]	A count of the number of hits that have contributed to the consensus TPR
# [3]	A pointer to another array storing all start values from associated hits
# [4]	A pointer to another array storing all end values from associated hits
#
################################################################################
	 
while (my $line = <INFILE>) {
	my @values = split /,/, trim($line);
	my ($resultId, $queryPdb, $queryChain, $resultPdb, $resultChain, $tprOrdinal, $startQuery, $endQuery, $startResult, $endResult) 
		= @values;
	my $pdbChain = $resultPdb.$resultChain;
	
	if (!exists $tprs{$pdbChain}){
		if ($pdbChain eq $testPdb){
			print "Creating $testPdb with start = $startResult, end = $endResult\n";
		}
		# First TPR in this PDB Chain
		#print "Adding first TPR for PDB Chain $pdbChain\n";
		$tprs{$pdbChain} = [];						# Create an array for the PDB Chain
		$tprs{$pdbChain}[0] = [];					# Create an array for the first TPR
		$tprs{$pdbChain}[0][0] = $startResult;		# This will track the average start residue
		$tprs{$pdbChain}[0][1] = $endResult;		# This will track the average end residue
		$tprs{$pdbChain}[0][2] = 1;					# This will count the hits for this TPR
		$tprs{$pdbChain}[0][3] = [];				# This will be an array of start residue numbers
		$tprs{$pdbChain}[0][4] = [];				# This will be an array of end residue numbers
		$tprs{$pdbChain}[0][3][0] = $startResult;	# Add the first start residue for this TPR
		$tprs{$pdbChain}[0][4][0] = $endResult;		# Add the first end residue for this TPR
		
	} else {
		# PDB Chain is known
		my $known = 0;
		for (my $i = 0; $i < scalar @{$tprs{$pdbChain}}; $i++){
			# Version Control 0003: The following was changed from && to || to reduce incidence of duplicate TPRs in final set.
			if (((abs($tprs{$pdbChain}[$i][0] - $startResult)) < $TPR_TOLERANCE) || ((abs($tprs{$pdbChain}[$i][1] - $endResult)) < $TPR_TOLERANCE)){
				# This is a TPR we've encountered before
				$known = 1;
				#print "Known TPR found\n";
				# Update average start residue
				$tprs{$pdbChain}[$i][0] = ($tprs{$pdbChain}[$i][0] * $tprs{$pdbChain}[$i][2] + $startResult)/($tprs{$pdbChain}[$i][2] + 1);
				# Update average end residue
				$tprs{$pdbChain}[$i][1] = ($tprs{$pdbChain}[$i][1] * $tprs{$pdbChain}[$i][2] + $endResult)/($tprs{$pdbChain}[$i][2] + 1);
				# Update the TPR count
				$tprs{$pdbChain}[$i][2]++;					
				my $new = scalar @{$tprs{$pdbChain}[$i][3]};
				# Add the start/end residues
				$tprs{$pdbChain}[$i][3][$new] = $startResult;
				$tprs{$pdbChain}[$i][4][$new] = $endResult;
				# Break out of the for loop as we've found our TPR
				last;
			}
		}
		if (!($known)){
		if ($pdbChain eq $testPdb){
			print "Adding a new TPR for $testPdb with start = $startResult, end = $endResult\n";
		}
		# This is a new TPR in a known PDBChain
			my $insertPoint = 0;
			# Determine where to splice it into the array to keep them in order
			for (my $i = 0; $i < scalar @{$tprs{$pdbChain}}; $i++){
				if ($startResult > $tprs{$pdbChain}[$i][0]){
					$insertPoint = $i + 1;
				}
			}
			my @newTpr;
			$newTpr[0] = $startResult;		# This will track the average start residue
			$newTpr[1] = $endResult;		# This will track the average end residue
			$newTpr[2] = 1;					# This will count the hits for this TPR
			$newTpr[3] = [];				# This will be an array of start residue numbers
			$newTpr[4] = [];				# This will be an array of end residue numbers
			$newTpr[3][0] = $startResult;	# Add the first start residue for this TPR
			$newTpr[4][0] = $endResult;		# Add the first end residue for this TPR		
			splice @{$tprs{$pdbChain}}, $insertPoint, 0, \@newTpr;
		}	
	}	
}

################################################################################
# STAGE 2: ITERATE THROUGH ALL PDB CODES, PRINTING CONSENSUS TENTATIVE TPRS
################################################################################

foreach my $pdb (sort keys %tprs){
	print $pdb, ": ", scalar @{$tprs{$pdb}}, " TPRs\n";
	# if ($pdb eq $testPdb){
		# my $tprCount = scalar @{$tprs{$pdb}};
		# print "Processing PDB Chain ", $testPdb, " which has $tprCount TPRs\n";
	# }
	#print "Processing PDB Chain ", $pdb, "\n";	
	my @regions;
	$regions[0] = 1;
	my $currentRegion = 1;
	# Iterate through the TPRs and check whether they are in the same region
	# as their predecessor.	
	for (my $i = 1; $i < scalar @{$tprs{$pdb}}; $i++){
		if (($tprs{$pdb}[$i][0] - $tprs{$pdb}[$i-1][1]) > $REGION_TOLERANCE){
			$currentRegion++;
		}
		$regions[$i] = $currentRegion;
	}
	
	my $pdbCode = substr($pdb, 0, 4);
	my $chain = substr($pdb, 4, length($pdb)-4);
	my ($regionOrdinal, $tprOrdinal) = (1, 0);
	for (my $i = 0; $i < scalar @{$tprs{$pdb}}; $i++){
		if ($regions[$i] > $regionOrdinal){
			$regionOrdinal++;
			$tprOrdinal = 0;
		}
		$tprOrdinal++;
		my $regionOrdinal 	= 	$regions[$i];
		my $startMedian 	= 	calculateMedian(\@{$tprs{$pdb}[$i][3]});	
		my $endMedian 		= 	calculateMedian(\@{$tprs{$pdb}[$i][4]});
		my $startMode 		= 	calculateMode(\@{$tprs{$pdb}[$i][3]});
		my $endMode 		=	calculateMode(\@{$tprs{$pdb}[$i][4]});
		my $startMax 		=	getMax(\@{$tprs{$pdb}[$i][3]});
		my $endMax 			=	getMax(\@{$tprs{$pdb}[$i][4]});
		my $startMin 		=	getMin(\@{$tprs{$pdb}[$i][3]});
		my $endMin 			=	getMin(\@{$tprs{$pdb}[$i][4]});
		# if ($pdb eq $testPdb){
			# print "Printing an insertion line for PDB Chain ", $pdb, "\n";
		# }
		print OUTFILE "INSERT INTO TentativeTPR (ttprParamId, pdbCode, chain, regionOrdinal, tprOrdinal, startMean, startMedian, startMode, startMax, startMin, endMean, endMedian, endMode, endMax, endMin) VALUES ($ttprParamId,\'$pdbCode\',\'$chain\',$regionOrdinal,$tprOrdinal,$tprs{$pdb}[$i][0],$startMedian,$startMode,$startMax,$startMin,$tprs{$pdb}[$i][1],$endMedian,$endMode,$endMax,$endMin);\n"
	}	
}

################################################################################
# STATISTICAL SUBROUTINES
################################################################################

sub calculateMedian($){
	my @values = @{$_[0]};
	@values = sort @values;
	if ((scalar @values)%2 == 1){
		return $values[(scalar @values - 1)/2];		
	} else {
		return $values[(scalar @values)/2 - 1] +  ($values[(scalar @values)/2] - $values[(scalar @values-1)/2])/2;
	}
}

sub calculateMode($){
	my @values = @{$_[0]};
	my %freq;
	foreach (@values) {$freq{$_}++};
	my @sorted = sort { $freq{$b} <=> $freq{$a} } keys %freq;
	
	# There may be multiple modes - let's check
	my @modes;
	$modes[0] = $sorted[0];
	my $ref = 0;
	while ($ref < scalar @sorted - 1){
		if ($freq{$sorted[$ref + 1]} == $freq{$sorted[$ref]}){
			$ref++;
			$modes[$ref] = $sorted[$ref];
		} else {
			$ref = scalar @sorted;
		}
	}
	
	# If there's only one mode, we're done
	if (scalar @modes == 1){
		return $modes[0];
	}

	# Otherwise, let's pick the mode that's closest to the mean
	else {
		my $mean = 0;
		for (my $i = 0; $i < @values; $i++){
			$mean += $values[$i];
		}
		$mean = $mean / scalar @values;
		my $bestMode = $modes[0];
		my $min = abs($mean - $modes[0]);
		for (my $i = 0; $ i < @modes; $i++){
			if ((abs($mean - $modes[$i])) < $min){
				$min = abs($mean - $modes[$i]);
				$bestMode = $modes[$i];
			}
		}
		return $bestMode;
	}
	# If multiple modes are equally close to the mean, we return the first one we find
}

sub getMax($){
	my @values = @{$_[0]};	
	my $max = $values[0];
	for (my $i = 0; $i < @values; $i++){
		if ($values[$i] > $max){
			$max = $values[$i];
		}
	}
	return $max;
}

sub getMin($){
	my @values = @{$_[0]};	
	my $min = $values[0];
	for (my $i = 0; $i < @values; $i++){
		if ($values[$i] < $min){
			$min = $values[$i];
		}
	}
	return $min;
}

################################################################################
# END
################################################################################
