#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: copyPDBFiles.pl
# Version: 0001 (09/08/17)
#
# Purpose: 	Given a list of PDB codes and a target directory, copy all the associated 
#			PDB files from the workingPDB directory into the target directory and unzip them
#			
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl copyPDBFiles.pl list.txt targetDir
#			
# Arguments: 
#	list.txt 	List of PDB codes, one per line
#	targetDir	Where to copy the PDB files to
#
#####################################################################################

use strict;
use warnings;

use TPRTools;

if (!(scalar @ARGV == 2)){
    die "Usage: perl copyPDBFiles.pl list.txt targetDir\n";
}

my $list = $ARGV[0];
my $targetDir = $ARGV[1];
my $pdbDir = "/d/mw6/u/md003/workingPDB";

open(INFILE, $list)
      or die "Can't open file $list\n"; 
	  
while (my $line = <INFILE>) {
	$line = trim($line);
	my $path = getPDBPath($line, $pdbDir);
	print "Copying PDB file $path to $targetDir\n";
	system("cp $path $pdbDir");
}	  

system("gunzip $targetDir/*.gz");