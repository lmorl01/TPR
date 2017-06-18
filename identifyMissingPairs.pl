#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: identifyMissingPairs.pl
# Version: 0001 (17/06/17 11:51)
#
# Purpose: 	Given an export of the TentativeTPR table and the PWSimilarity table,
#			identify all the pairwise combinations of TentativeTPRs from the 
#			TentativeTPR table that don't have a corresponding calculated pairwise
#			similarity in the PWSimilarity table. For all such cases, output the
#			pair in the format required by the FATCAT -alignPairs method, i.e.
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
# Input File Examples:
# 	
# PWSimilarity details should be extracted with the following SQL:
# select pwId, tentativeTPR1, pdb1, chain1, start1, end1, tentativeTPR2, pdb2, chain2, start2, end2 from PWSimilarity into outfile '/d/user6/md003/Project/db/sqlout/2017-06-17_PWSimilarity.csv' fields terminated by ',' lines terminated by '\n';
# Example Input File:
# 1,\N,4buj,B,1022,1131,\N,5udi,A,288,412
# 2,\N,3ly7,A,355,483,\N,5udi,A,288,412
# 3,\N,3ly7,A,355,483,\N,4buj,B,1022,1131
# 4,\N,1a17,A,28,129,\N,5udi,A,288,412
# 5,\N,1a17,A,28,129,\N,4buj,B,1022,1131
# 6,\N,1a17,A,28,129,\N,3ly7,A,355,483
#
# TentativeTPR details should be extracted with the following SQL:
# select tentativeTPRId, pdbcode, chain, start, end from TentativeTPR into outfile '/d/user6/md003/Project/db/sqlout/2017-06-17_TentativeTPRs.csv' fields terminated by ',' lines terminated by '\n';
# Example Input File:
# 1,5udi,A,288.667,410.167
# 2,4buj,B,1022,1129
# 3,3ly7,A,354,481
# 4,1a17,A,27.6,127
# 5,3rkv,A,190.286,308.143
# 6,4uzy,A,141.75,271
#
# Strategy: 
#	1. 	For efficient checking, pairs from the PWSimilarity table will be stored
#		in two hashes, a hash from tentativeTPR1 to and array of TentativeTPR2 
#		and a hash the other way from tentativeTPR2 to an array of TentativeTPR1. 
#		Both hashes would then be checked for the presence of a pair as the 
#		pairwise simlarity could have been calculated in either direction
#	2. 	Since all PWSimilarities have been associated with TentativeTPRs where possible
#		using associateTentativeTPRs.pl, it is adequate to use TentativeTPRIds as 
#		the unique identifiers with which to perform comparisons
#	3. 	Information from tentativeTPR can be used to compile a string of the form 
#		1a17:(A:22-125) which can be used for printing the missing pairwise combinations
#	4. 	The number of pairwise combinations of a set of size n = i = j can be 
#		considered to be the set of combinations that occurs above the diagonal 
#		in a matrix	such as the following:
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
#	5.	TentativeTPRIds will be read and stored in an array and each time a new TPR is
#		added to the array, we will iterate through all pw combinations of that new
#		TPR with existing TPRs and print the missing pairs.
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl identifyMissingPairs.pl pwInput.csv tentativeTprInput.csv pairs.out			
#
#####################################################################################

use strict;
use warnings;

use Math::Round;
use TPRTools;

if (!(scalar @ARGV == 3 )){
	print "Usage: perl identifyMissingPairs.pl pwInput.csv tentativeTprInput.csv pairs.out\n";
	exit;
}

my $inPw = $ARGV[0];
my $inTent = $ARGV[1];
my $out = $ARGV[2];

open(INPW, $inPw)
      or die "Can't open file $inPw\n"; 
open(INTENT, $inTent)
      or die "Can't open file $inTent\n"; 	  
open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";
	 
my $tentTPRCount = 0;
my $pwCount = 0;
my $newPairs = 0;
my %pairs;
my %pdbChains;
my @tentativeTPRs;
my $progress = 10000;
	 
# 1. Read PWSimilarities

print "\nLoading existing pairs\n";
while (my $line = <INPW>){
	# 0   , 1            , 2   , 3     , 4     , 5   , 6            , 7   , 8     , 9     , 10
	# pwId, tentativeTPR1, pdb1, chain1, start1, end1, tentativeTPR2, pdb2, chain2, start2, end2
	my @values = split /,/, trim($line);
	$pwCount++;
	if ($pwCount >= $progress){
		$progress = $progress + 10000;
		print "$pwCount pairs loaded\n";
		
	}
	
	my ($tpr1, $tpr2) = ($values[1], $values[6]);	
	#print "Processing pair: TPRId $tpr1, $tpr2\n";
	if ($tpr1 =~ /\d+/ && $tpr2 =~ /\d+/){
		if (!exists($pairs{$tpr1})){
			#print "No pairs for TPR $tpr1 found. Creating a new array\n";
			my @emptyArray;
			$pairs{$tpr1} = \@emptyArray;
			$pairs{$tpr1}[0] = $tpr2;
			#print "TPR pair $tpr1, $tpr2 added to the array\n";
		} else {
			#print "Pairs found for TPR $tpr1. Checking whether TPR $tpr2 is in the array\n";
			my $found = 0;
			for (my $i = 0; $i < scalar @{$pairs{$tpr1}}; $i++){
				if ($tpr2 eq $pairs{$tpr1}[$i]){
					#print "Found pair $pairs{$tpr1}[$i], $tpr2\n";
					$found = 1;
				}
			}
			if ($found == 0){
				#print "Pair TPR $tpr1, $tpr2 not found. Adding to the array\n";
				$pairs{$tpr1}[scalar @{$pairs{$tpr1}}] = $tpr2;
			}	
		}
		if (!exists($pairs{$tpr2})){
			#print "No pairs for TPR $tpr2 found. Creating a new array\n";
			my @emptyArray;
			$pairs{$tpr2} = \@emptyArray;
			$pairs{$tpr2}[0] = $tpr1;
			#print "TPR pair $tpr2, $tpr1 added to the array\n";
		} else {
			#print "Pairs found for TPR $tpr2. Checking whether TPR $tpr1 is in the array\n";
			my $found = 0;
			for (my $i = 0; $i < scalar @{$pairs{$tpr2}}; $i++){
				if ($tpr1 eq $pairs{$tpr2}[$i]){
					#print "Found pair $pairs{$tpr2}[$i], $tpr1\n";
					$found = 1;
				}
			}
			if ($found == 0){
				#print "Pair TPR $tpr2, $tpr1 not found. Adding to the array\n";
				$pairs{$tpr2}[scalar @{$pairs{$tpr2}}] = $tpr1;
			}	
		}
	}
}
print "All $pwCount pairs loaded\n";

	 
# 2. Read TentativeTPRs & print missing pairs
print "\nDetermining missing pairs\n";
$progress = 100;
while (my $line = <INTENT>) {
	# 0             , 1      , 2    , 3    , 4
	# tentativeTPRId, pdbcode, chain, start, end
	my @values = split /,/, trim($line);
	my ($tentativeTPR, $pdbCode, $chainId, $start, $end) = ($values[0], $values[1], $values[2], round($values[3]), round($values[4]))	;
	my $pdbChain = $pdbCode.":(".$chainId.":".$start."-".$end.")";
	$tentTPRCount++;
	if ($tentTPRCount >= $progress){
		$progress = $progress + 100;
		print "$tentTPRCount Tentative TPRs processed\n";
		
	}
	$pdbChains{$tentativeTPR} = $pdbChain;
	$tentativeTPRs[@tentativeTPRs] = $tentativeTPR;
	#print "Processing TentativeTPR $tentativeTPR\n";
	for (my $i = 0; $i < @tentativeTPRs - 1; $i++){
		my $otherTPR = $tentativeTPRs[$i];
		#print "Processing the TPR pair $tentativeTPR, $otherTPR\n";
		if (!(exists($pairs{$tentativeTPR})) || !(exists($pairs{$otherTPR}))){
			print OUTFILE $pdbChains{$tentativeTPR}, " ", $pdbChains{$otherTPR}, "\n";
			$newPairs++;
		} else {
		my $found = 0;
			for (my $i = 0; $i < scalar @{$pairs{$tentativeTPR}}; $i++){
				if ($otherTPR eq $pairs{$tentativeTPR}[$i]){
					$found = 1;
				}
			}
			for (my $i = 0; $i < scalar @{$pairs{$otherTPR}}; $i++){
				if ($tentativeTPR eq $pairs{$otherTPR}[$i]){
					$found = 1;
				}
			}
			if ($found == 0){
				print OUTFILE $pdbChains{$tentativeTPR}, " ", $pdbChains{$otherTPR}, "\n";
				$newPairs++;
			}	
		}
	}
}
print "All $tentTPRCount Tentative TPRs processed\n";

my $pairs = scalar keys %pairs;
my $tprs = scalar @tentativeTPRs;
print "\nSummary Report:\n$tprs Tentative TPRs analysed\n$pairs TPRs were already associated with existing calculated pairwise similarities\n$newPairs new pairs written\n";



