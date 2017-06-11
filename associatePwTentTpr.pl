#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: associatePwTentTpr.pl
# Version: 0001 (11/06/17 21:55)
# Revision History:
#
# Purpose:  Given an extract of current PW Similarities and current Tentative
#			TPRs, identify any missing associations between PW Similarities
#			and tentative TPRs. Write SQL to update the PWSimilarity table with
#			the associations (tentativeTPR1, tentativeTPR2)
#
# Assumptions:
#
# Input File Examples:
# 	
# PWSimilarity details should be extracted with the following SQL:
# select pwId, tentativeTPR1, pdb1, chain1, start1, end1, tentativeTPR2, pdb2, chain2, start2, end2 from PWSimilarity into outfile '/d/user6/md003/Project/db/sqlout/2017-06-11_TentativeTPRs.csv' fields terminated by ',' lines terminated by '\n';
# Example Input File:
# 1,\N,4buj,B,1022,1131,\N,5udi,A,288,412
# 2,\N,3ly7,A,355,483,\N,5udi,A,288,412
# 3,\N,3ly7,A,355,483,\N,4buj,B,1022,1131
# 4,\N,1a17,A,28,129,\N,5udi,A,288,412
# 5,\N,1a17,A,28,129,\N,4buj,B,1022,1131
# 6,\N,1a17,A,28,129,\N,3ly7,A,355,483
#
# TentativeTPR details should be extracted with the following SQL:
# select tentativeTPRId, pdbcode, chain, start, end from TentativeTPR into outfile '/d/user6/md003/Project/db/sqlout/2017-06-11_TentativeTPRs.csv' fields terminated by ',' lines terminated by '\n';
# Example Input File:
# 1,5udi,A,288.667,410.167
# 2,4buj,B,1022,1129
# 3,3ly7,A,354,481
# 4,1a17,A,27.6,127
# 5,3rkv,A,190.286,308.143
# 6,4uzy,A,141.75,271
#
# Strategy: 
#
# Output: The SQL file output will contain lines in the following format:
# UPDATE PWSimilarity SET tentativeTPR1 = 5, tentativeTPR2 = 6 WHERE pwId = 12;
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl associatePwTentTpr.pl pwInput.csv tentativeTprInput.csv out.sql
#			
#####################################################################################

use strict;
use warnings;

use TPRTools;

sub printTPRs();
sub getKnownTPR($$$);

if (!(scalar @ARGV == 3 )){
	print "Usage: perl associatePwTentTpr.pl pwInput.csv tentativeTprInput.csv out.sql\n";
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
	
my $tolerance = 15;
my $pwCount = 0;
my $tentTPRCount = 0;
my $newAssociations = 0;
my %tentTPRs;

# 1. Load Tentative TPRs
while (my $line = <INTENT>) {
	# 0             , 1      , 2    , 3    , 4
	# tentativeTPRId, pdbcode, chain, start, end
	my @values = split /,/, trim($line);
	$tentTPRCount++;
	my $pdbChain = $values[1].$values[2];
	#          (tentativeTPRId, start, end)
	my @tpr = ($values[0], $values[3], $values[4]);
	
	if (!exists $tentTPRs{$pdbChain}){
		my @emptyArray;
		$tentTPRs{$pdbChain} = \@emptyArray;
		$tentTPRs{$pdbChain}[0] = \@tpr;
	} else {
		$tentTPRs{$pdbChain}[scalar @{$tentTPRs{$pdbChain}}] = \@tpr;		
	}	
}

printTPRs();

# 2. Load and Compare PWSimilarity Entries
while (my $line = <INPW>){
	# 0   , 1            , 2   , 3     , 4     , 5   , 6            , 7   , 8     , 9     , 10
	# pwId, tentativeTPR1, pdb1, chain1, start1, end1, tentativeTPR2, pdb2, chain2, start2, end2
	my @values = split /,/, trim($line);
	$pwCount++;
	my $pdbChain1 = $values[2].$values[3];
	my ($pwId, $existingTPR1, $start1, $end1) = ($values[0], $values[1], $values[4], $values[5]);
	my $tentativeTPR1 = getKnownTPR($pdbChain1, $start1, $end1);
	if ($existingTPR1 eq '\N' && $tentativeTPR1 != 0){
		#New match found, let's update the database
			print OUTFILE "UPDATE PWSimilarity SET tentativeTPR1 = $tentativeTPR1 WHERE pwId = $pwId;\n";
			$newAssociations++;
	} elsif ($existingTPR1 ne '\N' && $tentativeTPR1 != 0) {
		#Existing match found, let's check it's still correct
		if (!($existingTPR1 == $tentativeTPR1)){
			print "Error Identified: association for pwId $pwId to tentativeTPR1 $existingTPR1 is invalid or no longer valid\n";
		}
	}
	my $pdbChain2 = $values[7].$values[8];	
	my ($existingTPR2, $start2, $end2) = ($values[6], $values[9], $values[10]);
	my $tentativeTPR2 = getKnownTPR($pdbChain2, $start2, $end2);
	if ($existingTPR2 eq '\N' && $tentativeTPR2 != 0){
		#New match found, let's update the database
			print OUTFILE "UPDATE PWSimilarity SET tentativeTPR2 = $tentativeTPR2 WHERE pwId = $pwId;\n";
			$newAssociations++;
	} elsif ($existingTPR2 ne '\N' && $tentativeTPR2 != 0) {
		#Existing match found, let's check it's still correct
		if (!($existingTPR2 == $tentativeTPR2)){
			print "Error Identified: association for pwId $pwId to tentativeTPR2 $existingTPR2 is invalid or no longer valid\n";
		}
	}	
	
} 

sub getKnownTPR($$$){
	my $pdbChain = $_[0];
	my ($start, $end) = ($_[1], $_[2]);
	my @tprSet;
	if (!exists $tentTPRs{$pdbChain}){
		return 0;
	} else {
		@tprSet = $tentTPRs{$pdbChain};
		my $tprCount = scalar $#{$tprSet[0]};
		for (my $i = 0; $i <= $tprCount; $i++){
			my ($tentativeTPRId, $tprStart, $tprEnd) = ($tprSet[0][$i][0], $tprSet[0][$i][1], $tprSet[0][$i][2]);
			if (abs($start - $tprStart) < $tolerance && abs($end - $tprEnd) < $tolerance){
				print "$pdbChain: $start is close to $tprStart with tentativeTPRId $tentativeTPRId\n";
				print "$pdbChain: $end is close to $tprEnd with tentativeTPRId $tentativeTPRId\n";
				return $tentativeTPRId;
			}	
		}
		return 0;
	}
}

my $pdbCount = scalar keys %tentTPRs;

print "$tentTPRCount TPRs in $pdbCount distinct PDB Chains compared with $pwCount Pairwise entries. $newAssociations new associations made.\n";

sub printTPRs(){
foreach my $pdbChain (sort keys %tentTPRs) {
	#print scalar @{$tentativeTPRs{$pdbChain}}, "\n";
	for (my $i = 0; $i < scalar @{$tentTPRs{$pdbChain}}; $i++){
		 print $pdbChain, " ", $tentTPRs{$pdbChain}[$i][0], " ", $tentTPRs{$pdbChain}[$i][1], " ", $tentTPRs{$pdbChain}[$i][2],"\n";
    }
}	
}
