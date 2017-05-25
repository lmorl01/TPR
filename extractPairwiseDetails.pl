#################################################################################
# David Morley, MSc Bioinformatics 2015-2017 
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: extractPairwiseDetails.pl
# Version: 0001 (17/05/17 18:56)
#
# Purpose: 	Given a directory of FATCAT pairwise result files, extract the details
#			from the first line of each file and output them in csv format
#
# Assumptions:
#
# Strategy: 
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl extractPairwiseDetails.pl pwDir out.csv
#			
# Arguments: 
#	pwDir			The directory where the FATCAT pairwise results are
#	out.csv			The csv output file		
#
#####################################################################################

use strict;
use warnings;

#use TPRTools;

if (!(scalar @ARGV == 2)){
    die "Usage: perl extractPairwiseDetails.pl pwDir out.csv\n";
}

my $pwDir = $ARGV[0];
my $out = $ARGV[1];

opendir DIR, $pwDir;
my @files = readdir DIR;

open (OUTFILE, ">$out")
	or die "Can't create outputfile $out\n";

my $headerPrinted = 0;
	
	foreach (my $i = 0; $i < @files; $i++){
	
	if ($files[$i] =~ /align/){
	open (INFILE, "<pw\/$files[$i]")
		 or die "Can't open file ", $files[$i], "\n";	
    my $line = <INFILE>;
	$line = substr($line, 10,length($line) - 12 );
	my @pairs = split(/\s+/, $line);
	my %hash = map {split(/=/, $_, 2)} @pairs;
	
	if (!$headerPrinted){
	foreach my $key (sort {$a cmp $b} keys %hash) {
		print OUTFILE "$key,"; 
	}
	print OUTFILE "\n";	
	$headerPrinted = 1;
	}
	

	foreach my $key (sort {$a cmp $b} keys %hash) {
		$hash{$key} =~ s/"//;
		$hash{$key} =~ s/"//;
		print OUTFILE "$hash{$key},"; 
	}
	print OUTFILE "\n";	
	close(INFILE);	
	
	}

	
}

close(OUTFILE);



