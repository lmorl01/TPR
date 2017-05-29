#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: countResidueFreqs.pl
# Version: 0001 (19/03/17 14:39)
#
# Purpose: read all XML alignment files in a given directory and count the 
# frequency of each amino acid residue number from the query structure.
# Output is is printed to file in a format such as:
# ......
# 39 205
# 40 103
# 50 199
# .....
# where the first column has residue numbers and the second column has frequencies
#
# Assumptions:
# 1.
#
# Strategy:
# 1.
#
# Error Behaviour:
# 1.
#
# Usage: perl countResidueFreqs.pl dir out
#
#####################################################################################

use strict;

if (!(scalar @ARGV == 2)){
    die "Usage: perl countResidueFreqs.pl dir out\n";
}

my $dir = $ARGV[0];

opendir DIR, $dir
    or die "can't open dir";
my @files = readdir DIR;
 
my $out = $ARGV[1];
open(OUTFILE, ">$out")
    or die "Can't create outputfile $out\n";

my @residueCount = (0) x 1000;

foreach (my $i = 0; $i <  @files; $i++){

    if ($files[$i] =~ /.xml/){
	my $path = $dir."\/".$files[$i];

    print "Processing file ", $path, "\n";
    open(INFILE, $path)
	or die "Can't open file ", $path, "\n";
	while (my $line = <INFILE>){
	    if ($line =~ /pdbres1="(\d+)"/){
		$residueCount[$1]++;
	    }
	}

    close(INFILE) or die "Unable to close file ", $path, "\n";
    }
}    

for (my $i = 0; $i < @residueCount; $i++){
    if ($residueCount[$i] > 0){
	print OUTFILE $i, ",", $residueCount[$i], "\n";
    }
}

closedir DIR;
