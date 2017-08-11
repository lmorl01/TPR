#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: getSequences.pl
# Version: 	0001	(11/08/17)
#
# Purpose: 	Given a list of PDB codes, extract the associated chain sequences from 
#			the PDB and write SQL to add them to the Sequence table in the DB
#
# Assumptions:
#
# Strategy: 
#
# Algorithm:
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl getSequences.pl pdb.csv out.sql error.log
#			
# Arguments: 	pdb.csv is a raw list of pdb codes, each on a separate line
#				out.sql is the SQL output file
#				error.log is an error log file
#
#####################################################################################

use strict;
use warnings;

use TPRTools;

if (!(scalar @ARGV == 3)){
    die "Usage: perl getSequences.pl pdb.csv out.sql error.log\n";
}

my $in = $ARGV[0];
my $out = $ARGV[1];
my $err = $ARGV[2];
my $pdbDir = "/d/mw6/u/md003/workingPDB";

open (INFILE, "<$in")
	or die "Can't open file ", $in, "\n";

open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";	
	 
open(ERR, ">$err")
	 or die "Can't create output file $err\n";	
	
while (my $inLine = <INFILE>){
	my %knownResidues;
	my $pdb = trim($inLine);
	my $path = getPDBPath($pdb, $pdbDir);
	print "Unzipping $path\n";
	system("gunzip $path");
	$path = substr($path,0,length($path)-3); #Because .gz has been truncated from the end
	if (open(INPDB, "<$path")){
		while (my $line = <INPDB>){
			if ($line =~ /^MODRES/){
				# These are residues that have been modified, such as changing methionine to selenomethionine to aid crystallography
				my $res3 = substr($line, 24, 3);
				my $res = getAminoAcidCode($res3);
				my $resNo = trim(substr($line, 18, 4));
				my $chain = substr($line, 16, 1);
				if (!(exists($knownResidues{$resChain}))){
					$knownResidues{$resChain} = 1;
					if (defined($res)){
						print OUTFILE "INSERT IGNORE INTO Sequence (pdbCode, chain, residueNo, residue) VALUES (\"$pdb\",\'$chain\',$resNo,\'$res\');\n";
					} else {
					print "Line ignored:\n $line\n";
					}
					
				}				
			}
			if ($line =~ /^ATOM/){
				my $chain = substr($line, 21, 1);
				my $res3 = substr($line, 17, 3);
				my $res = getAminoAcidCode($res3);
				my $resNo = trim(substr($line, 22, 4));
				my $resChain = $chain.$resNo;
				if (!(exists($knownResidues{$resChain}))){
					$knownResidues{$resChain} = 1;
					if (defined($res)){
						print OUTFILE "INSERT IGNORE INTO Sequence (pdbCode, chain, residueNo, residue) VALUES (\"$pdb\",\'$chain\',$resNo,\'$res\');\n";
					} else {
					print ERR "Line ignored:\n $line\n";
					}
					
				}
			}
		}
		close (INPDB);
	}
	else {
		print "Error opening PDB file $path\n";
	}
	print "Zipping $path\n";
	system("gzip $path");	
}	
	
# sub getPDBPath($$){
	# return "pdb".$_[0].".ent";
# }	
	
	
	
	
	
	
	
	
	
	
	
	