###################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origian & Evolution of TPR Domains
# Author: David Morley
# Script Name: countBlocks.pl
# Version: 0.001 (15/07/17 10:45)
# Version History:
#
# Purpose: 	To read FATCAT result files, count the number of blocks associated with
# 			each result and output an sql file for updating the Results table with
#			the number of blocks
#
# Assumptions:
#
# Strategy:
#
# Error Behaviour:
#
# Usage: perl countBlocks.pl resultsDir experimentId out.sql
# 
####################################################################################

use strict;
use warnings;
#use TPRTools;

if (!(scalar @ARGV == 3 && $ARGV[1] =~ /^\d+$/)){
    print "Usage: perl countBlocks.pl resultsDir experimentId out.sql";
    exit;
}

my $resDir = $ARGV[0];
my $experimentId = $ARGV[1];
my $out = $ARGV[2];

opendir DIR, $resDir;
my @files = readdir DIR;

open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";

foreach (my $i = 0; $i < @files; $i++){
	if ($files[$i] =~ /.gz/){
		my $path = $resDir."\/".$files[$i];
		print "Unzipping $path\n";
		system("gunzip $path");
		$path = substr($path,0,length($path)-3);	#Because .gz has been truncated from the end
		if (open(INFILE, $path)){
			my $header = <INFILE>;
			my $resultPdbText = "";				
			if ($header =~ /name2=\"([A-Za-z0-9:.]+_?)\"/){
				$resultPdbText = $1;
				my $blockCount = 0;
				while (my $line = <INFILE>){
				if ($line =~ /<block blockNr="(\d+)"/){
					$blockCount++;
				}
			}
			print OUTFILE "UPDATE Results SET blocks = $blockCount WHERE experimentId = $experimentId and resultPdbText = \"$resultPdbText\";\n";					
			}
		}
		print "Zipping $path\n";
		system("gzip $path");		
	}
}

closedir DIR;
close OUTFILE;


