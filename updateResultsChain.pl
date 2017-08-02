#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: updateResultsChain.pl
# Version: 0001 (02/08/17)
#
# Purpose: 	Read a list of pdbText entries from the Results table, extract the chain
#			and write SQL to update the chain field
#
# Assumptions:
#
# Table Structures: (only relevant fields shown)
# 	
# SearchHit
#
# +-------------------+-------------+------+-----+---------+----------------+
# | Field             | Type        | Null | Key | Default | Extra          |
# +-------------------+-------------+------+-----+---------+----------------+
# | resultId          | int(11)     | NO   | PRI | NULL    | auto_increment |
# | resultPdbText     | varchar(50) | YES  |     | NULL    |                |
# | chain             | char(1)     | YES  |     | NULL    |                |
# +-------------------+-------------+------+-----+---------+----------------+#
#
# Strategy: 
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl input.csv output.sql
#			
# Arguments: 
#	input.csv		Output from:
#					SELECT resultId, resultPdbText from Results 
#					WHERE chain IS NULL into outfile...
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

 my $in = $ARGV[0];
 my $out = $ARGV[1];
 my $count = 0;

open(INFILE, $in)
      or die "Can't open file $in\n"; 
open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";	  
	  
while (my $line = <INFILE>) {
	$count++;
	my @results = split /,/, $line;
	my $resultId = $results[0];
	my $pdbText = $results[1];
	my $chain = determineChainFromPdbText($pdbText);
	if ($count%10000 == 0){
		print "$count lines processed\n";
	}
	print OUTFILE "UPDATE Results SET chain = '$chain' WHERE resultId = $resultId;\n";
}

close(INFILE);
close(OUTFILE);
	
	
	