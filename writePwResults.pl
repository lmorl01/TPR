#####################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Version: 004, 25/06/2017
# Version hostory:
#	004: Updated to remove experimentId, which has been removed from the table
#
# Purpose: Write a script to populate the the following table:
#
# +-----------------+---------+------+-----+---------+----------------+
# | Field           | Type    | Null | Key | Default | Extra          |
# +-----------------+---------+------+-----+---------+----------------+
# | pwId            | int(11) | NO   | PRI | NULL    | auto_increment |
# | pdb1            | char(4) | YES  | MUL | NULL    |                |
# | chain1          | char(1) | YES  |     | NULL    |                |
# | start1          | int(11) | YES  |     | NULL    |                |
# | end1            | int(11) | YES  |     | NULL    |                |
# | pdb2            | char(4) | YES  | MUL | NULL    |                |
# | chain2          | char(1) | YES  |     | NULL    |                |
# | start2          | int(11) | YES  |     | NULL    |                |
# | end2            | int(11) | YES  |     | NULL    |                |
# | score           | float   | YES  |     | NULL    |                |
# | probability     | float   | YES  |     | NULL    |                |
# | rmsd            | float   | YES  |     | NULL    |                |
# | rmsdNorm        | float   | YES  |     | NULL    |                |
# | len1            | int(11) | YES  |     | NULL    |                |
# | len2            | int(11) | YES  |     | NULL    |                |
# | cov1            | int(11) | YES  |     | NULL    |                |
# | cov2            | int(11) | YES  |     | NULL    |                |
# | percentId       | float   | YES  |     | NULL    |                |
# | alignedResidues | int(11) | YES  |     | NULL    |                |
# +-----------------+---------+------+-----+---------+----------------+
#
# Program writes lines of the form:
# INSERT INTO PWSimilarity (pdb1, chain1, start1, end1, pdb2, chain2, start2, end2, score, probability, rmsd, rmsdNorm, 
# len1, len2, cov1, cov2, percentId, alignedResidues) 
# VALUES (CHAR(4), VARCHAR, FLOAT, FLOAT, FLOAT, INT, INT, INT, INT, FLOAT, INT, TEXT)
#
# Usage: perl writePwResults.pl pwResultFile.out populatePWResults.sql
# where...
# pwResultFile.out is an output file in the standard format produced by the FATCAT -alignPairs program
# populatePWResults.sql is the output file
#####################################################################################

use strict;
use warnings;

#use TPRTools;

sub writeResults($$$$$$$$$$$$$$$$$$);

if (!(scalar @ARGV == 2)){
	print "Usage: perl writePwResults.pl pwResultFile.out populatePWResults.sql\n";
	exit;
}

 my $in = $ARGV[0];
 my $out = $ARGV[1];
 open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";
open(INFILE, $in)
      or die "Can't open file $in\n";  

my $junk = <INFILE>; 		#Discard the first header line of the file 
$junk = <INFILE>; 			#Discard the second header line of the file
$junk = <INFILE>;			#Discard the third header line of the file
my $processed = 0;
my $ignored = 0;
my $lineNo = 3;				#Accounting for the discarded header lines
my $maxAlignedResidues = 0;	#Out of interest

while (my $line = <INFILE>) {
	$lineNo++;
	my @results = split /\t/, $line;	
	my ($pdb1, $chain1, $start1, $end1, $pdb2, $chain2, $start2, $end2) = ("","",0,0,"","",0,0);
	if ($results[0] =~ /^([A-Za-z0-9]{4}):\(([A-Za-z0-9]):(\d+)-(\d+)\)$/){
		$pdb1 = $1;
		$chain1 = $2;
		$start1 = $3;
		$end1 = $4;
	}
	else {
		print "Unexpected line format ignored at line $lineNo:\n", $line;
		$ignored++;
		next;
	}
	if ($results[1] =~ /^([A-Za-z0-9]{4}):\(([A-Za-z0-9]):(\d+)-(\d+)\)$/){
		$pdb2 = $1;
		$chain2 = $2;
		$start2 = $3;
		$end2 = $4;
	}
	else {
		print "Unexpected line format ignored at line $lineNo:\n", $line;
		$ignored++;
		next;
	}	
	my $alignedResidues = int (($results[5]/100)*$results[7]);
	if ($alignedResidues > $maxAlignedResidues){
		$maxAlignedResidues = $alignedResidues; 	#Out of interest
	}
	my $normRmsd = ($alignedResidues == 0) ? 1000 : $results[4]/sqrt($alignedResidues); #avoid division by zero
	writeResults($pdb1, $chain1, $start1, $end1, $pdb2, $chain2, $start2, $end2, $results[2], $results[3], $results[4], $normRmsd, $results[5], $results[6], $results[7], $results[8], $results[9], $alignedResidues);
	$processed++;
	
 }  
 close(INFILE) or die "Unable to close input file";
 close(OUTFILE) or die "Unable to close output file";

 if ($ignored > 0){
	print $ignored, " unexpected line formats ignored.\n"
 }
 print "Maximum number of aligned residues: ", $maxAlignedResidues, "\n"; #Out of interest
 print $processed, " pairwise results processed. Use the script $out to import these into the database.\n";
 
 sub writeResults($$$$$$$$$$$$$$$$$$){
	print OUTFILE "INSERT INTO PWSimilarity (pdb1, chain1, start1, end1, pdb2, chain2, start2, end2, score, probability, rmsd, rmsdNorm, len1, len2, cov1, cov2, percentId, alignedResidues) VALUES (\"$_[0]\", \"$_[1]\", $_[2], $_[3], \"$_[4]\", \"$_[5]\", $_[6], $_[7], $_[8], $_[9], $_[10], $_[11], $_[12], $_[13], $_[14], $_[15], $_[16], $_[17]);\n";
 }




