#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: contactAnalysis.pl
# Version: 	0001	(11/08/17)
#
# Purpose: 	
#
# Assumptions:
#
# Strategy: 
#
# Algorithm:
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: contactAnalysis.pl contact.txt
#			
# Arguments: 
#
#####################################################################################

use strict;
use warnings;

#use TPRTools;

if (!(scalar @ARGV == 1)){
    die "Usage: contactAnalysis.pl contact.txt\n";
}

my $in = $ARGV[0];

open (INFILE, "<$in")
	or die "Can't open file ", $in, "\n";

my $inHelices = "helices.txt";
	
open (INHEL, "<$inHelices")
	or die "Can't open file ", $inHelices, "\n";
	
my $count = 0;
my $tracker = 1;
	
while (my $line = <INFILE>){
	if ($line =~ /^Helix\s(\d+)\sresidue:\s\d+.\d+\scontacts\sHelix\s(\d+)/){
		if ($2 < $tracker){
			$count++;
			$tracker = $2;
		}
		if ($tracker < $2){
			$tracker = $2;
		}
	}
}	
my $countHelix = 0;

while (my $line = <INHEL>){
	if ($line =~ /^Analysis\sOf\s\d/){
		$countHelix++;
	}
}	
print "$count PDB Chains encountered in $in\n";
print "$countHelix PDB Chains counted in $inHelices\n";
	
	
	