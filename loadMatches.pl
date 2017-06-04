#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: loadMatches.pl
# Version: 0001 (03/06/17 20:05)
#
# Purpose: 	1. Given a directory of FATCAT DB search results, extract the pdb code, 
#			chain and residue numbers for each result. 
#			2. Given an extract of tentative TPR regions previously identified
#			determine whether the identified region is equivalent to an existing
#			identified region. If so, write SQL to update the associated entry 
#			in the TentativeTPR table; if not, write SQL to add the entry as a new
#			tentative TPR region to the tentativeTPR table
#			3. Write SQL to insert the results into the searchMatch table, 
#			referencing the associated entry in the TentativeTPR table. 
#
# Assumptions:
#	1. A Tentative TPR Region will only feature once in any one result set and 
#	therefore there will not be more than one update statement for any given 
#	Tentative TPR Region. 
#
# Table Structures:
# 	
# SearchHit
#
# +-------------------+-------------+------+-----+---------+----------------+
# | Field             | Type        | Null | Key | Default | Extra          |
# +-------------------+-------------+------+-----+---------+----------------+
# | matchId           | int(11)     | NO   | PRI | NULL    | auto_increment |
# | tentativeTPRId    | int(11)     | YES  | MUL | NULL    |                |
# | experimentId      | int(11)     | YES  | MUL | NULL    |                |
# | pdbCode           | char(4)     | YES  | MUL | NULL    |                |
# | chain             | varchar(5)  | YES  |     | NULL    |                |
# | start             | int         | YES  |     | NULL    |                |
# | end               | int         | YES  |     | NULL    |                |
# +-------------------+-------------+------+-----+---------+----------------+
#
# TentativeTPR
#
# +-------------------+-------------+------+-----+---------+----------------+
# | Field             | Type        | Null | Key | Default | Extra          |
# +-------------------+-------------+------+-----+---------+----------------+
# | tentativeTPRId    | int(11)     | NO   | PRI | NULL    | auto_increment |
# | pdbCode           | char(4)     | YES  | MUL | NULL    |                |
# | chain             | varchar(5)  | YES  |     | NULL    |                |
# | start             | float       | YES  |     | NULL    |                |
# | end               | float       | YES  |     | NULL    |                |
# | count             | int         | YES  |     | NULL    |                |
# +-------------------+-------------+------+-----+---------+----------------+
#
# Strategy: 
#	1. The PDB code can be extracted from the header line of the result file
#		where it is the name2 attribute in the AFPChain tag
#	2. The residue numbers and the chain IDs can be extracted from each 
#		<eqr> tag, where they are the pdbres2 and chain2 attributes respectively
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl loadMatches.pl experimentId resultDir tentativeTPR.csv out.sql
#			
# Arguments: 
#	experimentId		A foreign key to an entry in the table Experiment relating to 
#						the experiment that the results derive from
#	resultDir			The directory where the (top) FATCAT search results are
#	tentativeTPR.csv	The csv output file	containing all previously identified TPRs
#	out.sql				The SQL output file for loading this data
#	
#####################################################################################

use strict;
use warnings;

use TPRTools;

sub knownTPR($$$$);
sub writeUpdateTentativeTPR($$$$$);
sub writeAddTentativeTPR($$$$);
sub writeAddHit($$$$$);
sub printTentativeTPRs();

if (!(scalar @ARGV == 4 && $ARGV[0] =~ /^\d+$/)){
	print "Usage: perl loadMatches.pl experimentId resultDir tentativeTPR.csv out.sql\n";
	exit;
}

my $experimentId = $ARGV[0];
my $resDir = $ARGV[1];
my $in = $ARGV[2];
my $out = $ARGV[3];
my %tentativeTPRs;
my $tolerance = 15;
my ($fileCount, $added, $updated, $hits) = (0,0,0,0);

open(INFILE, $in)
      or die "Can't open file $in\n"; 
open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";
 
while (my $line = <INFILE>) {
	my @values = split /,/, trim($line);
	#print $values[0], " ", $values[1], " ", $values[2], " ", $values[3], " ", $values[4], "\n";
	my ($tentativeTPRId, $start, $end, $count) = ($values[0], $values[3], $values[4], $values[5]);
	my $pdbChain = $values[1].$values[2];
	my @tprRegion = ($start, $end, $count, $tentativeTPRId);
	if (!exists $tentativeTPRs{$pdbChain}){
		my @emptyArray;
		$tentativeTPRs{$pdbChain} = \@emptyArray;
		$tentativeTPRs{$pdbChain}[0] = \@tprRegion;
	} else {
		#print "Familiar PDB Chain found\n";
		#push $tentativeTPRs{$pdbChain}, \@tprRegion;		
		$tentativeTPRs{$pdbChain}[scalar @{$tentativeTPRs{$pdbChain}}] = \@tprRegion;		
	}
}	  

#printTentativeTPRs();
 
opendir DIR, $resDir;
my @files = readdir DIR;	  

#print "\nResults\n";
foreach (my $i = 0; $i < @files; $i++){
	
	if ($files[$i] =~ /.xml/){
		$fileCount++;
		my $pdbCode = getPdbCodeFromFatcatResultFile("$resDir\/$files[$i]");
		my ($start, $end, $chainId) = getStartEndResiduesFromFatcatResultFile("$resDir\/$files[$i]");		
		#print $pdbCode, " ", $chainId, " ", $start, " ", $end, "\n";
		my ($ref, $tentativeTPRId) = knownTPR($pdbCode, $chainId, $start, $end);
		if ($ref > -1){
			my $tentativeTPRId = writeUpdateTentativeTPR($pdbCode, $chainId, $start, $end, $ref);
			writeAddHit($pdbCode, $chainId, $start, $end, $tentativeTPRId);
		} else {
			writeAddTentativeTPR($pdbCode, $chainId, $start, $end);
			writeAddHit($pdbCode, $chainId, $start, $end, -1);
		}
		
	}	else {
		print $files[$i], "\n";
	}		
}

print "\nUpdated TentativeTPRs\n";
printTentativeTPRs();
print "\n";

print $fileCount, " files processed\n";
print $added, " new Tentative TPR Regions identified and added\n";
print $updated, " existing Tentative TPR Regions recognised and updated\n";
print $hits, " Search Hits added\n";
	


sub knownTPR($$$$){
	my $pdbChain = $_[0].$_[1];
	my ($start, $end) = ($_[2], $_[3]);
	if (exists $tentativeTPRs{$pdbChain}){
		#print $pdbChain, " exists\n";
		my @tprRegions = $tentativeTPRs{$pdbChain};
		for (my $i = 0; $i < scalar @{$tentativeTPRs{$pdbChain}}; $i++){
			if (((abs($start-$tentativeTPRs{$pdbChain}[$i][0])) < $tolerance) and
				((abs($end-$tentativeTPRs{$pdbChain}[$i][1])) < $tolerance)){
				print $pdbChain, " ", $start, " ", $end, " exists\n";
				return ($i, $tentativeTPRs{$pdbChain}[$i][3]) ;
			}
		}
		#print $_[0].$_[1], " doesn't exist\n";
		return -1;
	} else {
		#print $_[0].$_[1], " doesn't exist\n";
		return -1;
	}
}

sub writeUpdateTentativeTPR($$$$$){
	my ($pdbChain, $start, $end, $ref) = ($_[0].$_[1], $_[2], $_[3], $_[4]);
	#print "Updating ", $pdbChain, " ", $start, " ", $end, " ", $ref, " \n";
	# The average position of the start residue is updated 
	$tentativeTPRs{$pdbChain}[$ref][0] = ($tentativeTPRs{$pdbChain}[$ref][2]*$tentativeTPRs{$pdbChain}[$ref][0] + $start)/($tentativeTPRs{$pdbChain}[$ref][2] + 1);
	# The average position of the end residue is updated
	$tentativeTPRs{$pdbChain}[$ref][1] = ($tentativeTPRs{$pdbChain}[$ref][2]*$tentativeTPRs{$pdbChain}[$ref][1] + $end)/($tentativeTPRs{$pdbChain}[$ref][2] + 1);
	# The number of structures that have contributed to the averages is updated
	$tentativeTPRs{$pdbChain}[$ref][2]++;
	print OUTFILE "UPDATE TentativeTPRRegion SET start = $tentativeTPRs{$pdbChain}[$ref][0], end = $tentativeTPRs{$pdbChain}[$ref][1], count = $tentativeTPRs{$pdbChain}[$ref][2] WHERE tentativeTPRId = $tentativeTPRs{$pdbChain}[$ref][3];\n";
	$updated++;
	return $tentativeTPRs{$pdbChain}[$ref][3];
}

sub writeAddTentativeTPR($$$$){
	my ($pdbCode, $chain, $pdbChain, $start, $end) = ($_[0], $_[1], $_[0].$_[1], $_[2], $_[3]);
	#print "Adding ", $pdbChain, " ", $start, " ", $end, " \n";	
	my @tprRegion = ($start, $end, 1, "UNKNOWN");
	if (!exists $tentativeTPRs{$pdbChain}){
		my @emptyArray;
		$tentativeTPRs{$pdbChain} = \@emptyArray;
		$tentativeTPRs{$pdbChain}[0] = \@tprRegion;		
	} else {
		# push $tentativeTPRs{$pdbChain}, \@tprRegion;
		$tentativeTPRs{$pdbChain}[scalar @{$tentativeTPRs{$pdbChain}}] = \@tprRegion;
	}
	print OUTFILE "INSERT INTO TentativeTPRRegion (pdbCode, chain, start, end, count) VALUES (\"$pdbCode\", \"$chain\", $start, $end, 1);\n";
	$added++;
	return;
}

sub writeAddHit($$$$$){
	my ($pdbCode, $chain, $pdbChain, $start, $end, $tentativeTPRId) = ($_[0], $_[1], $_[0].$_[1], $_[2], $_[3], $_[4]);
	if ($tentativeTPRId > 0){
		# Known tentativeTPRId
		print OUTFILE "INSERT INTO SearchHit (tentativeTPRId, experimentId, pdbCode, chain, start, end) VALUES ($tentativeTPRId, $experimentId, \"$pdbCode\", \"$chain\", $start, $end);\n";
	} else {
		# Unknown tentativeTPRId, so we have to call it with LAST_INSERT_ID()
		print OUTFILE "INSERT INTO SearchHit (tentativeTPRId, experimentId, pdbCode, chain, start, end) VALUES (LAST_INSERT_ID(), $experimentId, \"$pdbCode\", \"$chain\", $start, $end);\n";
	}
	$hits++;
	return;
}

sub printTentativeTPRs(){
foreach my $pdbChain (sort keys %tentativeTPRs) {
	#print scalar @{$tentativeTPRs{$pdbChain}}, "\n";
	for (my $i = 0; $i < scalar @{$tentativeTPRs{$pdbChain}}; $i++){
		 print $pdbChain, " ", $tentativeTPRs{$pdbChain}[$i][0], " ", $tentativeTPRs{$pdbChain}[$i][1], " ", $tentativeTPRs{$pdbChain}[$i][2], " ", $tentativeTPRs{$pdbChain}[$i][3],"\n";
    }
}	
}





	  
