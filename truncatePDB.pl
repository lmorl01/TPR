#################################################################################
# David Morley, MSc Bioinformatics 2015-2017 
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: truncatePDB.pl
# Version: 0001 (13/05/17 16:16)
#
# Purpose: create a truncated version of a PDB file such that it contains only
# the section between two given residue numbers, passed as parameters
#
# Assumptions:
# 1. Truncation involves the following steps (identified by manual examination of the
# truncated version of TPR 1-3 in 1a17):
# a. Remove any HELIX or SHEET entries outside of the range
# b. Remove any ATOM entries outside of the range 
# c. Remove any entries of the following types: TER; HETATM; CONECT; MASTER 
# 2. It is harmless for atom serial numbers to start at values > 1 (This will happen
# if we truncate from the N-terminal end and don't bother to recalibrate atom serial numbers)
# 3. It is harmless to remove entirely the TER, HETATM, CONECT and MASTER entries
# 4. Nothing about chains needs to be considered (this assumption is likely to be
# naive and is likely to be addressed in a subsequent version of this script)
#
# Strategy:
# 1. Read each line from the PDB input file and write it to PDB output file unless
# it meets any of the criteria listed in the assumptions
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
# 2. Report failure if unable to open input file or output file
#
# Usage: perl truncatePDB.pl input.pdb output.pdb startResidue endResidue
#
#####################################################################################

use strict;
use warnings;

use TPRTools;

if (!(scalar @ARGV == 4)){
    die "Usage: perl truncatePDB.pl input.pdb output.pdb startResidue endResidue\n";
}

my $in = $ARGV[0];
my $out = $ARGV[1];
my $start = $ARGV[2];
my $end = $ARGV[3];

my $count = truncatePDBFile($in, $out, $start, $end);

print "File ", $in, " processed to remove regions outside the range [", $start, ", ", $end, "]\n", $count, " lines removed during truncation.";
