#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: addStartEnd.pl
# Version: 0001 (02/08/17)
#
# Purpose: 	Read a list of Result.resultId, Result.pdbText, Experiment.resultsLocation 
#			entries exported from the DB and use this information to parse the
#			associated alignment files extracting the start and end residues for 
#			each alignment. Write SQL to update the start and end fields incorrect
#			the Results table
#
# Assumptions:
#
# Table Structures: 
#
# Strategy: 
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl input.csv output.sql
#			
# Arguments: 
#	input.csv		Result.resultId, Result.pdbText, Experiment.resultsLocation
#	out.sql			The SQL output file for loading this data
#	
#####################################################################################

use strict;
use warnings;

use TPRTools;

if (!(scalar @ARGV == 2)){
	print "Usage: perl input.csv output.sql\n";
	exit;
}

 my ($in, $out) = ($ARGV[0], $ARGV[1]);
 my $root = "\/d\/mw6\/u\/md003\/results\/";
 my ($prefix, $suffix) = ("\/dbsearch_CUSTOM_", ".xml.gz");
 my $count = 0;
 
 open(INFILE, $in)
      or die "Can't open file $in\n"; 
open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";	
	 
while (my $line = <INFILE>) {
	$count++;
	if ($count%100 == 0){
		print "$count records processed\n";
	}
	my @results = split /,/, $line;
	my $resultId = $results[0];
	my $pdbText = $results[1];
	my $resLoc = trim($results[2]);
	my $alignFile = $root.$resLoc.$prefix.$pdbText.$suffix;
	print "Unzipping $alignFile\n";
	system("gunzip $alignFile");
	$alignFile = substr($alignFile,0,length($alignFile)-3); #Because .gz has been truncated from the end
	my ($start, $end, $chainId) = getStartEndResiduesFromFatcatResultFile($alignFile);
	print OUTFILE "UPDATE Results SET start = $start, end = $end WHERE resultId = $resultId;\n";
	print "Zipping $alignFile\n";
	system("gzip $alignFile");
}	 