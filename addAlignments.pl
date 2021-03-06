#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: addAlignments.pl
# Version: 	0001 (05/08/17)
#			0002 (07/08/17) Close all file handles; pass all values in a single INSERT
#			0003 (07/08/17) Reversion to multiple INSERTS as single insert is larger 
#							than the max packet size on the DB
#
# Purpose: 	Read a list of Result.resultId, Result.pdbText, Experiment.resultsLocation 
#			entries exported from the DB and use this information to parse the
#			associated alignment files extracting the alignment. 
#			Write SQL to add the alignment details to the Alignment table
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

sub processAlignments($$);

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
	my @results = split /,/, $line;
	my $resultId = $results[0];
	my $pdbText = $results[1];
	my $resLoc = trim($results[2]);
	my $alignFile = $root.$resLoc.$prefix.$pdbText.$suffix;
	print "Unzipping $alignFile\n";
	system("gunzip $alignFile");
	$alignFile = substr($alignFile,0,length($alignFile)-3); #Because .gz has been truncated from the end
	processAlignments($resultId, $alignFile);
	print "Zipping $alignFile\n";
	system("gzip $alignFile");
	if ($count%500 == 0){
		print "$count records processed\n";
		sleep 2;	# Give them a chance to read it
	}
}	 

close(INFILE);
close(OUTFILE) or die "Unable to close $out\n";

sub processAlignments($$){
	my $resultId = $_[0];
	my $path = $_[1];
	if (open(IN, $path)){
		while (my $line = <IN>){
			if ($line =~ /pdbres1="(\d+)"\schain1="([A-Za-z0-9])"\spdbres2="(\d+)"\schain2="([A-Za-z0-9])"/){
				print OUTFILE "INSERT INTO Alignment (resultId, queryResidueNo, resultResidueNo) VALUES ($resultId,$1,$3);\n";
			}
		}
		close(IN);
	}
}