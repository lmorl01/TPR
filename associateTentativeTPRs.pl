#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: associateTentativeTPRs.pl
# Version: 0001 (10/06/17 18:50)
#
# Purpose:  Given an extract of current TPR Regions/TPRs and current Tentative
#			TPRs, identify any missing associations between tentative TPRs
#			and known TPRs. Write SQL to update the TentativeTPR table with
#			the associations (regionId and startOrdinal)
#
# Assumptions:
#
# Input File Examples:
# 	
# TPR details should be extracted with the following SQL:
# select R.regionId, R.pdbCode, R.chain, R.regionOrdinal, TPR.tprId, TPR.startResidue, TPR.endResidue, TPR.tprOrdinal from TPRRegion R, TPR where R.regionId = TPR.regionId and TPR.superseded is NULL order by R.pdbCode, R.regionOrdinal, TPR.tprOrdinal into outfile '/d/user6/md003/Project/db/sqlout/2017-06-10_TPRs.csv' fields terminated by ',' lines terminated by '\n'; 
# Fields:
# regionId, pdbCode, chain, regionOrdinal, tprId, startResidue, endResidue, tprOrdinal
# Example Input File:
# 1,1a17,A,1,32,28,61,1
# 1,1a17,A,1,33,62,95,2
# 1,1a17,A,1,34,96,129,3
# 3,1elw,A,1,35,4,37,1
# 3,1elw,A,1,36,38,71,2
# 3,1elw,A,1,37,72,101,3
#
# TentativeTPR details should be extracted with the following SQL:
# select T.tentativeTPRId, T.pdbCode, T.chain, T.start, T.end, T.regionId, T.startOrdinal, T.repeats from TentativeTPR T order by T.pdbCode, T,regionId, T.startOrdinal into outfile '/d/user6/md003/Project/db/sqlout/2017-06-10_TentativeTPRs.csv' fields terminated by ',' lines terminated by '\n';
# Fields:
# tentativeTPRId, pdbCode, chain, start, end, regionId, startOrdinal, repeats
# Example Input File:
# 1,5udi,A,288,412,\N,\N,3
# 2,4buj,B,1022,1131,\N,\N,3
# 3,3ly7,A,355,483,\N,\N,3
# 4,1a17,A,28,129,\N,\N,3
# 5,3rkv,A,191,310,\N,\N,3
# 6,4uzy,A,143,273,\N,\N,3
#
# Strategy: 
#
# Output: The SQL file output will contain lines in the following format:
# UPDATE TentativeTPR SET regionId = 5, startOrdinal = 1 WHERE tentativeTPRId = 6;
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl associateTentativeTPRs.pl tprInput.csv tentativeTprInput.csv out.sql
#			
#####################################################################################

use strict;
use warnings;

use TPRTools;

sub printTPRs();
sub getKnownTPR($$$$);

if (!(scalar @ARGV == 3 )){
	print "Usage: perl associateTentativeTPRs.pl tprInput.csv tentativeTprInput.csv out.sql\n";
	exit;
}

my $inTpr = $ARGV[0];
my $inTent = $ARGV[1];
my $out = $ARGV[2];

open(INTPR, $inTpr)
      or die "Can't open file $inTpr\n"; 
open(INTENT, $inTent)
      or die "Can't open file $inTent\n"; 	  
open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";
	
my $tolerance = 15;
my %TPRs;
my %tentativeTPRs;
	
# 1. Load TPRs
while (my $line = <INTPR>) {
	# 0       , 1      , 2    , 3            , 4    , 5           , 6         , 7
	# regionId, pdbCode, chain, regionOrdinal, tprId, startResidue, endResidue, tprOrdinal
	my @values = split /,/, trim($line);
	my $pdbChain = $values[1].$values[2];
	#          regionId    start       end         tprOrdinal
	my @tpr = ($values[0], $values[5], $values[6], $values[7]);
	
	if (!exists $TPRs{$pdbChain}){
		my @emptyArray;
		$TPRs{$pdbChain} = \@emptyArray;
		$TPRs{$pdbChain}[0] = \@tpr;
	} else {
		$TPRs{$pdbChain}[scalar @{$TPRs{$pdbChain}}] = \@tpr;		
	}	
}

#printTPRs();

# 2. Load and Compare TentativeTPRs
while (my $line = <INTENT>){
	# 0             , 1      , 2    , 3    , 4  , 5       , 6           , 7
	# tentativeTPRId, pdbCode, chain, start, end, regionId, startOrdinal, repeats
	my @values = split /,/, trim($line);
	my $pdbChain = $values[1].$values[2];
	my ($tentativeTPRId, $start, $end, $repeats) = ($values[0], $values[3], $values[4], $values[7]);
	my ($existingRegionId, $existingStartOrdinal) = ($values[5], $values[6]);
	my ($regionId, $startOrdinal) = getKnownTPR($pdbChain, $start, $end, $repeats);
	if ($existingRegionId eq '\N' && $existingStartOrdinal eq '\N' && $regionId != 0 && $startOrdinal != 0){
		#New match found, let's update the database
			print OUTFILE "UPDATE TentativeTPR SET regionId = $regionId, startOrdinal = $startOrdinal WHERE tentativeTPRId = $tentativeTPRId;\n";
			
	} elsif ($existingRegionId ne '\N' && $existingStartOrdinal ne '\N' && $regionId != 0 && $startOrdinal != 0) {
		#Existing match found, let's check it's still correct
		if (!($existingRegionId == $regionId && $existingStartOrdinal == $startOrdinal)){
			print "Error Identified: association for tentativeTPRId $tentativeTPRId is invalid or no longer valid\n";
		}
	}
	# else do nothing as no match has been found
} 

sub getKnownTPR($$$$){
	my $pdbChain = $_[0];
	my ($start, $end, $repeats) = ($_[1], $_[2], $_[3]);
	my @tprSet;
	if (!exists $TPRs{$pdbChain}){
		return (0,0);
	} else {
		@tprSet = $TPRs{$pdbChain};
		my ($startMatch, $endMatch) = (1000, 500); #These are merely random and largely different
		my $tprCount = scalar $#{$tprSet[0]};
		for (my $i = 0; $i <= $tprCount; $i++){
			my ($regionId, $tprStart, $tprEnd, $tprOrdinal) = ($tprSet[0][$i][0], $tprSet[0][$i][1], $tprSet[0][$i][2], $tprSet[0][$i][3]);
			if (abs($start - $tprStart) < $tolerance){
				#print "$pdbChain: $start is close to $tprStart with region Id $regionId and ordinal $tprOrdinal\n";
				$startMatch = $i;
			}
			if (abs($end - $tprEnd) < $tolerance){
				#print "$pdbChain: $end is close to $tprEnd with region Id $regionId and ordinal $tprOrdinal\n";
				$endMatch = $i;
			}			
			#print $tprSet[0][$i][0], " ", $tprSet[0][$i][1], " ", $tprSet[0][$i][2], " ", $tprSet[0][$i][3],"\n";
		}
		#print "Start Match $startMatch, End Match $endMatch\n";
		if (($tprSet[0][$endMatch][3] - $tprSet[0][$startMatch][3]) == ($repeats - 1)){
			my ($regionId, $tprOrdinal) = ($tprSet[0][$startMatch][0], $tprSet[0][$startMatch][3]);
			#print "$pdbChain Match: region ID $regionId , tpr ordinal $tprOrdinal\n";
			return ($regionId, $tprOrdinal);
		}
		
		
		return (0,0);
	}
}


sub printTPRs(){
foreach my $pdbChain (sort keys %TPRs) {
	#print scalar @{$tentativeTPRs{$pdbChain}}, "\n";
	for (my $i = 0; $i < scalar @{$TPRs{$pdbChain}}; $i++){
		 print $pdbChain, " ", $TPRs{$pdbChain}[$i][0], " ", $TPRs{$pdbChain}[$i][1], " ", $TPRs{$pdbChain}[$i][2], " ", $TPRs{$pdbChain}[$i][3],"\n";
    }
}	
}

			#for (my $j = 0; $j < scalar @tprSet[$i]; $j++){
				#print $tprSet[$i][0][0], " ", $tprSet[$i][0][1], " ", $tprSet[$i][0][2], " ", $tprSet[$i][0][3],"\n";	
				#print $tprSet[$i][1][0], " ", $tprSet[$i][1][1], " ", $tprSet[$i][1][2], " ", $tprSet[$i][1][3],"\n";
				#print $tprSet[$i][2][0], " ", $tprSet[$i][2][1], " ", $tprSet[$i][2][2], " ", $tprSet[$i][2][3],"\n";
				#print scalar $#{$tprSet[0]}, "\n";
				#print $tprSet[0][0][0], " ", $tprSet[0][0][1], " ", $tprSet[0][0][2], " ", $tprSet[0][0][3],"\n";	
				#print $tprSet[0][1][0], " ", $tprSet[0][1][1], " ", $tprSet[0][1][2], " ", $tprSet[0][1][3],"\n";
				#print $tprSet[0][2][0], " ", $tprSet[0][2][1], " ", $tprSet[0][2][2], " ", $tprSet[0][2][3],"\n";
				#print $tprSet[0][$i][0], " ", $tprSet[0][$i][1], " ", $tprSet[0][$i][2], " ", $tprSet[0][$i][3],"\n";
				#print $tprSet[0][0], " ", $tprSet[0][1], " ", $tprSet[0][2], " ", $tprSet[0][3],"\n";	
				#print $tprSet[1][0], " ", $tprSet[1][1], " ", $tprSet[1][2], " ", $tprSet[1][3],"\n";
				#print $tprSet[2][0], " ", $tprSet[2][1], " ", $tprSet[2][2], " ", $tprSet[2][3],"\n";				
			#}
