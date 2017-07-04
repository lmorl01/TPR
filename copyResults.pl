###################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origian & Evolution of TPR Domains
# Author: David Morley
# Script Name: copyResults.pl
# Version: 0.002 (04/04/17 14:53)
# Version History:
#	0.002 	Updated to handle new format for extracting top results from the DB
#			Also added checking that directory exists
#
# Purpose: To read a set of substrings from an input file passed as a parameter
# and to copy all files that contain those substrings from the local directory to
# another directory, also passed as a parameter
#
# Assumptions:
# 1. The input file consists of a series of patterns separated by new line characters
#
# Strategy:
# 1.
#
# Error Behaviour:
# 1.
#
# Usage: perl copyResults.pl in.file out.dir
####################################################################################

use strict;
use warnings;
use TPRTools;

if (!(scalar @ARGV == 2)){
    print "Usage: perl copyResults.pl in.file out.dir";
    exit;
}

my $in = $ARGV[0];
my $out = $ARGV[1];

print "Input file: ", $in, "\n";
print "Copy to location: ", $out, "\n";

open (INFILE, $in)
    or die "Can't open file $in\n";
if (!(-e $out and -d $out)){
	die "Unable to find directory $out\n";
}

my $count = 0;
while (my $line = <INFILE>){
    my @values = split /,/, trim($line);
	my $pdbText = $values[3];
    print "Processing ", $pdbText, "\n";
    system("cp *$pdbText* $out");
    $count++;
}

print $count, " filename patterns processed. The actual number of files copied may be larger than this because multiple files may have contained any given substring\n";
