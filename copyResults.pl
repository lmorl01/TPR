###################################################################################
# David Morley, MSc Bioinformatics 2015-2017  
# MSc Project: Origian & Evolution of TPR Domains
# Author: David Morley
# Script Name: copyResults.pl
# Version: 0.001 (19/03/17 11:04)
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
#Check here that $out is a dir

my $count = 0;
while (my $line = <INFILE>){
    chomp($line);
    print "Processing ", $line, "\n";
    system("cp *$line* $out");
    $count++;
}

print $count, " filename patterns processed. The actual number of files copied may be larger than this because multiple files may have contained any given substring\n";
