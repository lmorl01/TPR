###################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origian & Evolution of TPR Domains 
# Author: David Morley
# Script Name: copyResultsPDB.pl
# Version: 0.001 (02/04/17 22:34)
#
# Purpose: To read a set of substrings from an input file passed as a parameter
# and to copy all PDB files that relating to those substrings from the workingPDB directory to
# another directory, also passed as a parameter
#
# Assumptions:
# 1. The input file consists of a series of patterns separated by new line characters
# 2. The patterns are of the following forms:
# a.dXXXX
#
# Strategy:
# 1.
#
# Error Behaviour:
# 1.
#
# Usage: perl copyResultsPDB.pl in.file out.dir
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
    my $mid = substr($line, 1,2);
    print "Processing ", $line, "\n";
    system("cp /d/mw6/u/md003/workingPDB/data/structures/divided/pdb/$mid/*$line* $out");
    $count++;
}

print $count, " filename patterns processed. The actual number of files copied may be larger than this because multiple files may have contained any given substring\n";
