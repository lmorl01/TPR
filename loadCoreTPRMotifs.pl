#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: loadCoreTPRMotifs.pl
# Version: 	0001	(11/08/17)
#
# Purpose: 	Prepare SQL to load core motifs into the table TPRMotifAlignment
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
# Usage: perl loadCoreTPRMotifs.pl coreTPRs.csv coreMotifAlignment.csv out.sql
#			
# Arguments: 	
#
#####################################################################################

use strict;
use warnings;

use TPRTools;

if (!(scalar @ARGV == 3)){
    die "Usage: perl loadCoreTPRMotifs.pl coreTPRs.csv coreMotifAlignment.csv out.sql\n";
}

my $TPRIn = $ARGV[0];
my $coreMotifsIn = $ARGV[1];
my $out = $ARGV[2];

open (INTPR, "<$TPRIn")
	or die "Can't open file ", $TPRIn, "\n";
	
open (INMOTIF, "<$coreMotifsIn")
	or die "Can't open file ", $coreMotifsIn, "\n";

open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";	

my %tprs;
	 
# Read TPRs
while (my $line = <INTPR>){
	my @tpr = split /,/, trim($line);
	my ($tprId, $pdbCode, $chain, $regionOrdinal, $tprOrdinal) = @tpr;
	my $pdbChain = $pdbCode.$chain;
	if (!(exists($tprs{$pdbChain}))){
		$tprs{$pdbChain} = [];
	}
	push @{$tprs{$pdbChain}}, \@tpr;
}

# Read Motifs and write SQL
my $junk = <INMOTIF>;	# Discard the header
while (my $line = <INMOTIF>){
	my @motif = split /,/, trim($line);
	my ($pdb, $chain, $regionOrdinal, $tprOrdinal) = ($motif[0], $motif[1], $motif[2], $motif[3]);
	my $pdbChain = $pdb.$chain;
	my @tpr;
	if (@{$tprs{$pdbChain}}){
		for (my $i = 0; $i < scalar @{$tprs{$pdbChain}}; $i++){
			if ($regionOrdinal == $tprs{$pdbChain}[$i][3] && $tprOrdinal == $tprs{$pdbChain}[$i][4]){
				@tpr = @{$tprs{$pdbChain}[$i]};
				last;
			}
		}	
	}
	else {
		die "Error: ttprId not identified for $pdb\n";
	}

	if (!(@tpr)){
		die "Error: ttprId not identified for $pdb\n";
	}
	for (my $i = 4; $i < 38; $i++){
		my $tprId = $tpr[0];
		my $motifNo = $i-3;
		my $residueNo = $motif[$i];
		if ($residueNo){
			print OUTFILE "INSERT INTO TPRMotifAlignment (tprId, motifNo, residueNo) VALUES ($tprId, $motifNo, $residueNo);\n";
		}
	}
}

	 