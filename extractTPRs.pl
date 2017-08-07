#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: extractTPRs.pl
# Version: 0001 (05/08/17)
# Change Log:
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
# Usage: perl extractTPRs.pl significantResults.csv out.sql
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

if (!(scalar @ARGV == 2)){
	print "Usage: perl extractTPRs.pl significantResults.csv out.sql\n";
	exit;
}

my $in = $ARGV[0];
my $out = $ARGV[1];
my $TPR_TOLERANCE = 15;
my $REGION_TOLERANCE = 34;
my %tprs;

open(INFILE, $in)
      or die "Can't open file $in\n"; 
open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";
	 
while (my $line = <INFILE>) {
	my @values = split /,/, trim($line);
	print "\n$values[0] $values[3] $values[4] $values[5] $values[8] $values[9]\n";
	my ($resultId, $queryPdb, $queryChain, $resultPdb, $resultChain, $tprOrdinal, $startQuery, $endQuery, $startResult, $endResult) 
		= ($values[0], $values[1], $values[2], $values[3], $values[4], $values[5], $values[6], $values[7], $values[8], $values[9]);
	
	my $pdbChain = $resultPdb.$resultChain;
	
	if (!exists $tprs{$pdbChain}){
		# First TPR in this PDB Chain, so we add it
		print "Adding first TPR for PDB Chain $pdbChain\n";
		my (@emptyA1, @emptyA2, @emptyA3, @emptyA4);
		$tprs{$pdbChain} = \@emptyA1;
		$tprs{$pdbChain}[0] = \@emptyA2;
		$tprs{$pdbChain}[0][0] = $startResult;		# This will track the average start residue
		$tprs{$pdbChain}[0][1] = $endResult;		# This will track the average end residue
		$tprs{$pdbChain}[0][2] = 1;					# This will count the hits for this TPR
		$tprs{$pdbChain}[0][3] = \@emptyA3;			# This will be an array of start residue numbers
		$tprs{$pdbChain}[0][4] = \@emptyA4;			# This will be an array of end residue numbers
		$tprs{$pdbChain}[0][3][0] = $startResult;
		$tprs{$pdbChain}[0][4][0] = $endResult;
		
	} else {
		print "PDB Chain is known\n";
		my $known = 0;
		for (my $i = 0; $i < scalar @{$tprs{$pdbChain}}; $i++){
			#print "Comparing to known TPR with start residue $tprs{$pdbChain}[$i][0] and end residue $tprs{$pdbChain}[$i][1]\n";
			#print abs($tprs{$pdbChain}[$i][0] - $startResult), " ", abs($tprs{$pdbChain}[$i][1] - $endResult), "\n";
			if (((abs($tprs{$pdbChain}[$i][0] - $startResult)) < $TPR_TOLERANCE) && ((abs($tprs{$pdbChain}[$i][1] - $endResult)) < $TPR_TOLERANCE)){
				$known = 1;
				print "Known TPR found\n";
				# Update average start residue
				$tprs{$pdbChain}[$i][0] = ($tprs{$pdbChain}[$i][0] * $tprs{$pdbChain}[$i][2] + $startResult)/($tprs{$pdbChain}[$i][2] + 1);
				# Update average end residue
				$tprs{$pdbChain}[$i][1] = ($tprs{$pdbChain}[$i][1] * $tprs{$pdbChain}[$i][2] + $endResult)/($tprs{$pdbChain}[$i][2] + 1);
				$tprs{$pdbChain}[$i][2]++;					# Update the TPR count
				my $new = scalar @{$tprs{$pdbChain}[$i][3]};
				$tprs{$pdbChain}[$i][3][$new] = $startResult;
				$tprs{$pdbChain}[$i][4][$new] = $endResult;				
			}
		}
		if (!($known)){
			print "TPR not yet known\n";
			my $insertPoint = 0;
			for (my $i = 0; $i < scalar @{$tprs{$pdbChain}}; $i++){
				if ($startResult > $tprs{$pdbChain}[$i][0]){
					$insertPoint = $i + 1;
				}
			}
			print "Insert Point: ", $insertPoint, "\n";
			
			my (@emptyA1, @emptyA2, @emptyA3);			
			my @newTpr;
			$newTpr[0] = $startResult;		# This will track the average start residue
			$newTpr[1] = $endResult;		# This will track the average end residue
			$newTpr[2] = 1;					# This will count the hits for this TPR
			$newTpr[3] = \@emptyA2;			# This will be an array of start residue numbers
			$newTpr[4] = \@emptyA3;			# This will be an array of end residue numbers
			$newTpr[3][0] = $startResult;
			$newTpr[4][0] = $endResult;				
			splice $tprs{$pdbChain}, $insertPoint, 0, \@newTpr;
		}	
	}	
}

foreach my $pdb (keys %tprs){
	print "\nProcessing PDB Chain ", $pdb, "\n";	
	my @regions;
	$regions[0] = 1;
	my $region = 1;
	my ($regionStart, $regionEnd) = ($tprs{$pdb}[0][0],$tprs{$pdb}[0][1]);
	for (my $i = 1; $i < scalar @{$tprs{$pdb}}; $i++){
		if (($tprs{$pdb}[$i][0] - $tprs{$pdb}[$i-1][1]) > $REGION_TOLERANCE){
			$region++;
		}
		$regions[$i] = $region;
	}
	
	my $pdbCode = substr($pdb, 0, 4);
	my $chain = substr($pdb, 4, length($pdb)-4);
	my ($regionOrdinal, $tprOrdinal) = (1, 0);
	for (my $i = 0; $i < scalar @{$tprs{$pdb}}; $i++){
		print "Processing TPR start ", $tprs{$pdb}[$i][0], " end ", $tprs{$pdb}[$i][1], " region ", $regions[$i], "\n";
		if ($regions[$i] > $regionOrdinal){
			$tprOrdinal = 0;
		}
		$tprOrdinal++;
		my $regionOrdinal = $regions[$i];
		my $startMedian = calculateMedian(\@{$tprs{$pdb}[$i][3]});	
		my $endMedian = calculateMedian(\@{$tprs{$pdb}[$i][4]});
		my $startMode = calculateMode(\@{$tprs{$pdb}[$i][3]});
		my $endMode = calculateMode(\@{$tprs{$pdb}[$i][4]});
		my $startMax = getMax(\@{$tprs{$pdb}[$i][3]});
		my $endMax = getMax(\@{$tprs{$pdb}[$i][4]});
		my $startMin = getMin(\@{$tprs{$pdb}[$i][3]});
		my $endMin = getMin(\@{$tprs{$pdb}[$i][4]});
		print "Start Mode: $startMode\n";
		print "\n";
		print OUTFILE "INSERT INTO TentativeTPR (pdbCode, chain, regionOrdinal, tprOrdinal, startMean, startMedian, startMode, startMax, startMin, endMean, endMedian, endMode, endMax, endMin) VALUES (\'$pdbCode\',\'$chain\',$regionOrdinal,$tprOrdinal,$tprs{$pdb}[$i][0],$startMedian,$startMode,$startMax,$startMin,$tprs{$pdb}[$i][1],$endMedian,$endMode,$endMax,$endMin);\n"
	}	
}

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


