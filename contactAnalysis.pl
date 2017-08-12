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
#	PDB codes will be the keys of a hash. The values will be an array of arrays, 
#	where each array of arrays stores the following values associated with a contact:
#	[0]	Helix Number 1
#	[1]	Helix Number 2
#	[2] Helix Residue Number 1
#	[3] Helix Residue Number 2
#
# Algorithm:
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: contactAnalysis.pl contact.txt out.sql
#			
# Arguments: 
#
#####################################################################################

use strict;
use warnings;

#use TPRTools;

if (!(scalar @ARGV == 2)){
    die "Usage: contactAnalysis.pl contact.txt out.sql\n";
}

my $in = $ARGV[0];
my $out = $ARGV[1];

open (INFILE, "<$in")
	or die "Can't open file ", $in, "\n";
open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";	

my %contacts;
my $pdbChain = "";
	
while (my $line = <INFILE>){

	if ($line =~ /^Analysis\sOf\s([A-Za-z0-9]+)/){
		my $nextPdbChain = $1;
		if ($nextPdbChain ne $pdbChain){
			#print $line;
			$pdbChain = $nextPdbChain;
			if (!defined($contacts{$pdbChain})){
				$contacts{$pdbChain} = [];
			}
		}
	}
	if ($line =~ /^Helix\s(\d+)\sresidue:\s(\d+).\d+\scontacts\sHelix\s(\d+)\sresidue:\s(\d+)/){
		my @contact = ($1, $3, $2, $4);
		push @{$contacts{$pdbChain}}, \@contact;		
	}
}	

foreach my $pdbChain (sort keys %contacts){
	my $pdb = substr($pdbChain,0,4);
	my $chain = substr($pdbChain,4,1);
	for (my $i = 0; $i < scalar @{$contacts{$pdbChain}}; $i++){
		my ($helix1, $helix2, $residue1, $residue2) = ($contacts{$pdbChain}[$i][0], $contacts{$pdbChain}[$i][1], $contacts{$pdbChain}[$i][2], $contacts{$pdbChain}[$i][3]);
		print OUTFILE "INSERT INTO Contact (pdbCode, chain, helix1, helix2, residue1, residue2) VALUES (\"$pdb\",\'$chain\',$helix1,$helix2,$residue1,$residue2);\n";
	}
}

my $count = scalar keys %contacts;
print "$count PDB Chains encountered and processed\n";

	
	
	