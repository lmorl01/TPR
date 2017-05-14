#####################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Package Name: TPRTools.pm
# Version: 0002 (14/05/17 11:43)
#
# Purpose: 	A package of tools developed for use in the Origin & Evolution of 
#			TPR Domains project
#
# Assumptions: Addressed in individual subroutine headers
#
# Strategy: Addressed in individual subroutine headers
#
# Error Behaviour: Addressed in individual subroutine headers
#
#####################################################################################

package TPRTools;

use strict;
use warnings;
use Exporter;

our @ISA = ("Exporter");
our @EXPORT = qw(truncatePDBFile);

sub trim($);
sub truncatePDBFile($$$$);

#####################################################################################
# Purpose: 	Truncate a PDB file such that it represents a new structure containing
# 			only the region between the start and end coordinates supplied
# Arguments: 
# 	string 		$_[0]: the path to the existing input PDB file
#	string		$_[1]: the path to the new truncated output PDB file
#	int			$_[2]: the start residue number for the truncated region
#	int			$_[3]: the end residue number for the truncated region
#
# Assumptions:
# 1. 	Truncation involves the following steps (identified by manual examination of 
#		the	truncated version of TPR 1-3 in 1a17):
# 			a. Remove any HELIX or SHEET entries outside of the range
# 			b. Remove any ATOM entries outside of the range 
# 			c. Remove any entries of the following types: TER; HETATM; CONECT; MASTER 
# 2. 	It is harmless for atom serial numbers to start at values > 1 (This will 
#		happen if we truncate from the N-terminal end and don't bother to recalibrate 
#		atom serial numbers, which is what we do)
# 3. 	It is harmless to remove entirely the TER, HETATM, CONECT and MASTER entries
# 4. 	Nothing about chains needs to be considered (this assumption is likely to be
# 		naive and is likely to be addressed in a subsequent version of this subroutine)
# 5. 	We don't need to check for the existence of a file by the same name as the 
#		output file and if such a file exists, we can overwrite it without warning
#
# Strategy:
# 1. 	Read each line from the PDB input file and write it to PDB output file unless
# 		it meets any of the criteria listed in the assumptions
#
# Return: 
#	int			The number of lines removed during truncation
#
# Error Behaviour: 
#	1. If the input file cannot be opened, report and die
#	2. If the output file cannot be written, report and die
#####################################################################################
sub truncatePDBFile($$$$){
my $in = $_[0];
my $out = $_[1];
my $start = $_[2];
my $end = $_[3];
my $removalCount = 0;

open (INFILE, "<$in")
	or die "Can't open file ", $in, "\n";
open (OUTFILE, ">$out")
	or die "Can't create outputfile $out\n";

while (my $line = <INFILE>){
	
	my $remove = 0;
	
	if ($line =~ /^HELIX\s+\d+\s+\d+\s+[A-Z]+\s+[A-Z]+\s+(\d+)/){
		if (($1 < $start) || ($1 > $end)){
			$remove = 1;
			$removalCount++;
		}
	}
	if ($line =~ /^SHEET\s+\d+\s+\d+\s+[A-Z]+\s+[A-Z]+\s+(\d+)/){
	if (($1 < $start) || ($1 > $end)){
			$remove = 1;
			$removalCount++;
		}
	}
	if ($line =~ /^ATOM\s+\d+\s+[A-Z0-9]+\s+[A-Z]+\s+[A-Z]+\s+(\d+)/){
		if (($1 < $start) || ($1 > $end)){
			$remove = 1;
			$removalCount++;
		}
	}	
	if ($line =~ /^TER\s/ || $line =~ /^HETATM\s/ || $line =~ /^CONECT\s/ || $line =~ /^MASTER\s/){
			$remove = 1;
			$removalCount++;		
	}		
	if (!$remove){
		print OUTFILE $line;
	}	
  }
  return $removalCount;
}

#####################################################################################
# Purpose: 	Trims whitespace from either end of a String
# Arguments: 
# 	string 		$_[0]: 	the string to be trimmed
# Return: 
#	string		The trimmed string
# Error Behaviour: 
#	None
#####################################################################################
sub trim($){
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

1;