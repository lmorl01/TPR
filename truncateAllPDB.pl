#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: truncateAllPDB.pl
# Version: 0001 (14/05/17 13:30)
#
# Purpose: 	Create truncated versions of PDB files associated with a set of FATCAT
#			search results
#
# Assumptions:
#
# Strategy:
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl truncateAllPDB.pl resultDir pdbDir outDir
#			
# Arguments: 
# 	resultDir	The directory containing the XML result files
#	pdbDir		The directory containing PDB files
#	outDir		The directory to output the truncated files to 		
#
#####################################################################################

use strict;
use warnings;

use TPRTools;

if (!(scalar @ARGV == 3)){
    die "Usage: perl truncatePDB.pl input.pdb output.pdb startResidue endResidue\n";
}

my $resDir = $ARGV[0];
my $pdbDir = $ARGV[1];
my $outDir = $ARGV[2];

opendir DIR, $resDir;
my @files = readdir DIR;

foreach (my $i = 0; $i < @files; $i++){
	
	if ($files[$i] =~ /.xml/){
		my $path = $resDir."\/".$files[$i];
		my $pdbCode = getPdbCodeFromFatcatResultFile($path);
		my @startEndResidues = getStartEndResiduesFromFatcatResultFile($path);	
		#print $pdbCode, "\nStart: ", $startEndResidues[0], "\nEnd: ", $startEndResidues[1], "\n";
	}	
}




