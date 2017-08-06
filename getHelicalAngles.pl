#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: getHelicalAngles.pl
# Version: 0001 (06/08/17)
#
# Purpose: 	Given an export from the TentativeTPR table, run the helixPair program
#			to calculate inter-helical angles and write SQL to populate these in
#			the TentativeTPR table
#
# Assumptions:
#	1. 	A TPR has three angles associated with its helices:
#		i.) The aa angle is the angle between the first helix of the TPR and the 
#			first helix of the succeeding helix
#		ii.) The ab angle is the angle between the first and second helices of the
#			TPR
#		iii.) The ba angle is the angle between the second helix of the TPR and
#			the first helix of the succeeding helix
#
# Table Structures (only relevant fields shown):
#
# TentativeTPR: 
#
# +--------------+---------+------+-----+---------+----------------+
# | Field        | Type    | Null | Key | Default | Extra          |
# +--------------+---------+------+-----+---------+----------------+
# | ttprId       | int(11) | NO   | PRI | NULL    | auto_increment |
# | ttprRegionId | int(11) | NO   | MUL | NULL    |                |
# | startMean    | float   | YES  |     | NULL    |                |
# | endMean      | float   | YES  |     | NULL    |                |
# | aaAngle      | float   | YES  |     | NULL    |                |
# | abAngle      | float   | YES  |     | NULL    |                |
# | baAngle      | float   | YES  |     | NULL    |                |
# | regionOrdinal| int(11) | YES  |     | NULL    |                |
# | tprOrdinal   | int(11) | YES  |     | NULL    |                |
# +--------------+---------+------+-----+---------+----------------+
#
# Strategy: For each PDB Chain:
#	1. 	Run helixPair program for the relevant PDB chain
#	2. 	Create an associated directory for the result files and move
#		them there
#	3.	Read helices.txt to extract details of helices. Match helices
#		against those in the TentativeTPR and identify an SSE reference
#		for each helix in the TPR
#	4. 	Read helix_packing_pair.txt to identify the global angles between
#		TPR helices
#	5.	Write SQL to add the angles to TentativeTPR
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl ttprs.csv resDir out.sql
#			
# Arguments: 
#	ttprs.csv		
#	Extract from the TentativeTPR table with the following fields:
#	ttprId, pdbCode, chain, regionOrdinal, tprOrdinal, startMean, endMean
#	
#	resDir
#	Directory where the helixPair Results are	
#
#	out.sql			
#	The SQL output file for loading this data
#	
#####################################################################################

use strict;
use warnings;

use TPRTools;

sub getSSEA($$);
sub getSSEB($$);
sub getAngle($$$);

if (!(scalar @ARGV == 3)){
	print "Usage: perl ttprs.csv resDir out.sql\n";
	exit;
}

my $in = $ARGV[0];
my $resDir = $ARGV[1];
my $out = $ARGV[2];
my $TPR_TOLERANCE = 15;
my %ttprs;
#my %pdbChains;
my %helices;
my %angles;

open(INFILE, $in)
      or die "Can't open file $in\n"; 
open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";

# Read in TTPRs	 
while (my $line = <INFILE>) {
	my @ttpr = split /,/, trim($line);
	my $pdbChain = $ttpr[1].$ttpr[2];
	#print "PDB Chain: $pdbChain\n";
	if (!exists($ttprs{$pdbChain})){
		$ttprs{$pdbChain} = [];
		# $pdbChains{$pdbChain} = 1;
	}
	push @{$ttprs{$pdbChain}}, \@ttpr;
	#$ttprs[@ttprs] = \@ttpr;
}	 

# Run helixPair for each PDB chain in keys %pdbChains and copy results 
# to a directory with the name of the PDB chain (e.g. 1a17A) in the directory $resDir
# TODO

# Read helices.txt file for each PDB and load helix details
foreach my $pdb (sort keys %ttprs){
	$helices{$pdb} = [];
	my $dir = $resDir."\/".$pdb;
	my $helixFile = $dir."\/helices.txt";
	if (open(HELIX, $helixFile)){
		while (my $line = <HELIX>) {
			if ($line =~ /SSE:\s(\d+),\sstart\sresidue:\s(\d+).00,\slast\sresidue:\s(\d+)./){
				#print $line;
				my @helix = ($1, $2, $3);
				push @{$helices{$pdb}}, \@helix;
				my ($sse, $start, $end) = ($1, $2, $3);	
				print "SSE $sse Start $start End $end\n";
			}
		}
	}
}

# Read helix_packing_pair.txt file for each PDB and load helix angle details
foreach my $pdb (sort keys %ttprs){
	$angles{$pdb} = [];
	my $dir = $resDir."\/".$pdb;
	my $angleFile = $dir."\/helix_packing_pair.txt";	
	if (open(ANGLE, $angleFile)){
		my $junk = <ANGLE>;		# Discard first line
		while (my $line = <ANGLE>) {
			my @values = split /\t/, trim($line);
			my ($chainId, $sse1, $sse2, $angle) = ($values[0], $values[1], $values[2], $values[4]);
			my @angle = ($sse1, $sse2, $angle);
			print "Chain Id $chainId SSE1 $sse1 SSE2 $sse2 Angle $angle\n";
			push @{$angles{$pdb}}, \@angle;
		}
	}
}

foreach my $pdb (sort keys %ttprs){
	for (my $i = 0; $i < scalar @{$ttprs{$pdb}} - 1; $i++){
		#print @{$ttprs{$pdb}[$i]}, "\n";
		my ($ttprId, $pdbChain, $regionOrdinal, $tprOrdinal, $start, $end)  =  ($ttprs{$pdb}[$i][0], $ttprs{$pdb}[$i][1].$ttprs{$pdb}[$i][2], $ttprs{$pdb}[$i][3], $ttprs{$pdb}[$i][4], $ttprs{$pdb}[$i][5], $ttprs{$pdb}[$i][6]);
		print "TTPR ID: $ttprId\nPDB Chain: $pdbChain\nStart: $start End: $end\n";
		if ($regionOrdinal == $ttprs{$pdb}[$i+1][3]){
			# Next TPR is in the same region
			my @tpr1 = ($start, $end);
			my @tpr2 = ($ttprs{$pdb}[$i+1][5], $ttprs{$pdb}[$i+1][6]);
			my $sseA = getSSEA($pdbChain, \@tpr1);
			my $sseB = getSSEB($pdbChain, \@tpr1);
			my $sseAPrime = getSSEA($pdbChain, \@tpr2);
			my $abAngle = getAngle($pdbChain, $sseA, $sseB);
			my $aaAngle = getAngle($pdbChain, $sseA, $sseAPrime);
			my $baAngle = getAngle($pdbChain, $sseB, $sseAPrime);
			print "Angles:\nAB: $abAngle\nAA: $aaAngle\nBA: $baAngle\n";
			print OUTFILE "UPDATE TentativeTPR SET abAngle=$abAngle, aaAngle=$aaAngle, baAngle=$baAngle WHERE ttprId=$ttprId;\n";
		} else {
			# Next TPR is in another region
			my @tpr1 = ($start, $end);
			my $sseA = getSSEA($pdbChain, \@tpr1);
			my $sseB = getSSEB($pdbChain, \@tpr1);
			my $abAngle = getAngle($pdbChain, $sseA, $sseB);
			print OUTFILE "UPDATE TentativeTPR SET abAngle=$abAngle WHERE ttprId=$ttprId;\n";
		}
	}
	# Now process the final TPR
	# Assume that there may be a solvating helix after a loop, with SSE for the solvatix helix equal to SSE for helix B plus 2
	my $ttprId = $ttprs{$pdb}[scalar @{$ttprs{$pdb}}-1][0];
	my $pdbChain = $ttprs{$pdb}[scalar @{$ttprs{$pdb}}-1][1].$ttprs{$pdb}[scalar @{$ttprs{$pdb}}-1][2];
	my @tpr1 = ($ttprs{$pdb}[scalar @{$ttprs{$pdb}}-1][5], $ttprs{$pdb}[scalar @{$ttprs{$pdb}}-1][6]);
	my $sseA = getSSEA($pdbChain, \@tpr1);
	my $sseB = getSSEB($pdbChain, \@tpr1);
	my $sseAPrime = $sseB + 2;
	my $abAngle = getAngle($pdbChain, $sseA, $sseB);
	my $aaAngle = getAngle($pdbChain, $sseA, $sseAPrime);
	my $baAngle = getAngle($pdbChain, $sseB, $sseAPrime);
	print "Angles:\nAB: $abAngle\nAA: $aaAngle\nBA: $baAngle\n";
	print OUTFILE "UPDATE TentativeTPR SET abAngle=$abAngle, aaAngle=$aaAngle, baAngle=$baAngle WHERE ttprId=$ttprId;\n";	
}

sub getSSEA($$){
	my $pdbChain = $_[0];
	my @tpr = @{$_[1]};
	my ($start, $end) = ($tpr[0], $tpr[1]);
	my @helices = @{$helices{$pdbChain}};
	my $dist = $TPR_TOLERANCE + 1;
	my $sse = -1;
	for (my $i = 0; $i < @helices; $i++){
		if ($dist > abs($start - $helices[$i][1])){
			$dist = abs($start - $helices[$i][1]);
			$sse = $helices[$i][0];
		}
	}
	print "Helix A SSE $sse Distance $dist\n";
	return $sse;
}

sub getSSEB($$){
	my $pdbChain = $_[0];
	my @tpr = @{$_[1]};
	my ($start, $end) = ($tpr[0], $tpr[1]);
	my @helices = @{$helices{$pdbChain}};
	my $dist = $TPR_TOLERANCE + 1;
	my $sse = -1;
	for (my $i = 0; $i < @helices; $i++){
		if ($dist > abs($end - $helices[$i][2])){
			$dist = abs($end - $helices[$i][2]);
			$sse = $helices[$i][0];
		}
	}
	print "Helix B SSE $sse Distance $dist\n";
	return $sse;
}

sub getAngle($$$){
	my $pdbChain = $_[0];
	my $sse1 = $_[1];
	my $sse2 = $_[2];
	my @angles = @{$angles{$pdbChain}};
	for (my $i = 0; $i < scalar @angles; $i++){
		if ($angles[$i][0] == $sse1 &&  $angles[$i][1] == $sse2){
			return $angles[$i][2];
		}
	}
	return "NULL";	# Angle not found. Return NULL for convenient insertion into DB
}





# for (my $i = 0; $i < @ttprs; $i++){
	# my ($ttprId, $pdbChain, $regionOrdinal, $tprOrdinal, $start, $end)  =  ($ttprs[$i][0], $ttprs[$i][1].$ttprs[$i][2], $ttprs[$i][3], $ttprs[$i][4], $ttprs[$i][5], $ttprs[$i][6]);
	# print "TTPR ID: $ttprId\nPDB Chain: $pdbChain\nStart: $start End: $end\n";
	# my $sse1 = getSSE();
		
	
# }














# foreach my $pdb (sort keys %helices){
	# for (my $i = 0; $i < scalar @{$helices{$pdb}}; $i++){
		# print $helices{$pdb}[$i][0], " ", $helices{$pdb}[$i][1], " ", $helices{$pdb}[$i][2], "\n";
	# }
# }

#print sort keys %pdbChains;

