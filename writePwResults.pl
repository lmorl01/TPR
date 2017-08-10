#####################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Version: 	004, 25/06/2017
#			005, 10/08/17
# Version history:
#	004: Updated to remove experimentId, which has been removed from the table
#	005: Extensively updated to reflect new table structures and methodologies
#
# Purpose: Write a script to populate the the following table:
#
# +-----------------+---------+------+-----+---------+----------------+
# | Field           | Type    | Null | Key | Default | Extra          |
# +-----------------+---------+------+-----+---------+----------------+
# | pwId            | int(11) | NO   | PRI | NULL    | auto_increment |
# | ttprId1         | int(11) | YES  | MUL | NULL    |                |
# | pdb1            | char(4) | YES  | MUL | NULL    |                |
# | chain1          | char(5) | YES  |     | NULL    |                |
# | start1          | int(11) | YES  |     | NULL    |                |
# | end1            | int(11) | YES  |     | NULL    |                |
# | ttprId2         | int(11) | YES  | MUL | NULL    |                |
# | pdb2            | char(4) | YES  | MUL | NULL    |                |
# | chain2          | char(5) | YES  |     | NULL    |                |
# | start2          | int(11) | YES  |     | NULL    |                |
# | end2            | int(11) | YES  |     | NULL    |                |
# | tprCount        | int(11) | YES  |     | NULL    |                |
# | score           | float   | YES  |     | NULL    |                |
# | norm_score      | float   | YES  |     | NULL    |                |
# | probability     | float   | YES  |     | NULL    |                |
# | rmsd            | float   | YES  |     | NULL    |                |
# | norm_rmsd       | float   | YES  |     | NULL    |                |
# | len1            | int(11) | YES  |     | NULL    |                |
# | len2            | int(11) | YES  |     | NULL    |                |
# | cov1            | int(11) | YES  |     | NULL    |                |
# | cov2            | int(11) | YES  |     | NULL    |                |
# | percentId       | float   | YES  |     | NULL    |                |
# | alignedResidues | int(11) | YES  |     | NULL    |                |
# +-----------------+---------+------+-----+---------+----------------+
#
# Usage: perl writePwResults.pl tprCount pwResultFile.out ttprFile.csv populatePWResults.sql
# where...
# tprCount is the number of TPR repeats associated with these PDB Chain regions
# pwResultFile.out is an output file in the standard format produced by the FATCAT -alignPairs program
# ttprs.csv is an extract from the TentativeTPR table with the following fields:
#		ttprId, pdbCode, chain, regionOrdinal, tprOrdinal, startMean, endMean
# populatePWResults.sql is the output file
#####################################################################################

use strict;
use warnings;

use TPRTools;

if (!(scalar @ARGV == 4 && $ARGV[0] =~ /^\d+$/)){
	print "Usage: perl writePwResults.pl pwResultFile.out ttprFile.csv populatePWResults.sql\n";
	exit;
}

my $tprCount = $ARGV[0];
my $inResults = $ARGV[1];
my $inTTPRs = $ARGV[2];
my $out = $ARGV[3];
open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";
open(INFILE, $inResults)
      or die "Can't open file $inResults\n";  

my %ttprs = %{getTTPRs($inTTPRs)};
	  
my 	$junk = <INFILE>; 					# Discard the first  header line of the file 
	$junk = <INFILE>; 					# Discard the second header line of the file
	$junk = <INFILE>;					# Discard the third  header line of the file
my  $lineNo	= 3;						# Accounting for the discarded header lines
	
my ($processed, $ignored, $maxAlignedResidues) 	= (0,0,0);

while (my $line = <INFILE>) {
	$lineNo++;
	my @results = split /\t/, trim($line);
	my ($region1, $region2, $score, $probability, $rmsd, $len1, $len2, $cov1, $cov2, $percentId, $description) = @results;	
	my ($pdb1, $chain1, $start1, $end1, $pdb2, $chain2, $start2, $end2, $ttprId1, $ttprId2) = ("","",0,0,"","",0,0, "NULL", "NULL");
	if ($region1 =~ /^([A-Za-z0-9]{4}):\(([A-Za-z0-9]):(\d+)-(\d+)\)$/){
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
	if ($region2 =~ /^([A-Za-z0-9]{4}):\(([A-Za-z0-9]):(\d+)-(\d+)\)$/){
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
	my $alignedResidues = int (($len1/100)*$cov1);
	if ($alignedResidues > $maxAlignedResidues){
		$maxAlignedResidues = $alignedResidues; 										# Out of interest
	}
	my $norm_rmsd = ($alignedResidues == 0) ? 1000 : $rmsd/sqrt($alignedResidues); 		# Avoid division by zero
	my $norm_score = $alignedResidues == 0 ? 0 : $score/sqrt($alignedResidues);			# Avoid division by zero
	
	my $pdbChain1 = $pdb1.$chain1;
	for (my $i = 0; $i < scalar @{$ttprs{$pdbChain1}}; $i++){
		if ($start1 == $ttprs{$pdbChain1}[$i][5]){										# [5] contains the start residue
			$ttprId1 = $ttprs{$pdbChain1}[$i][0];										# [0] contains the ttprId										
			last;
		}
	}
	my $pdbChain2 = $pdb2.$chain2;
	for (my $i = 0; $i < scalar @{$ttprs{$pdbChain2}}; $i++){
		if ($start2 == $ttprs{$pdbChain2}[$i][5]){										# [5] contains the start residue
			$ttprId2 = $ttprs{$pdbChain2}[$i][0];										# [0] contains the ttprId
			last;
		}
	}	
	
	print OUTFILE "INSERT INTO PWSimilarity (ttprId, pdb1, chain1, start1, end1, ttprId2, pdb2, chain2, start2, end2, tprCount, score, norm_score, probability, rmsd, norm_rmsd, len1, len2, cov1, cov2, percentId, alignedResidues) VALUES ($ttprId1, \"$pdb1\", \"$chain1\", $start1, $end1, $ttprId2, \"$pdb2\", \"$chain2\", $start2, $end2, $tprCount, $score, $norm_score, $probability, $rmsd, $norm_rmsd, $len1, $len2, $cov1, $cov2, $percentId, $alignedResidues);\n";
	
	$processed++;
 }  
 
 close(INFILE) or die "Unable to close input file";
 close(OUTFILE) or die "Unable to close output file";

 # Print Summary Information
 
 if ($ignored > 0){
	print $ignored, " unexpected line formats ignored.\n"
 }
 print "Maximum number of aligned residues: ", $maxAlignedResidues, "\n"; #Out of interest
 print $processed, " pairwise results processed\nUse the script $out to import these into the database.\n";
 




