#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: getAminoAcids.pl
# Version: 	0001 (06/08/17)
#			0002 (07/08/17)	getPDBPath($) updated to reflect the PDB directory
#							structure on blackbird. Negative residue numbers in
#							PDB files ignored.
#
# Purpose: 	Given an extract alignments that are missing amino acids, 
#			parse the associated PDB files to obtain the amino acids corresponding 
#			to each residue number and write SQL to update these in the DB
#
# Assumptions:
#	1. 	PDB files will be named using the format pdb1a17.ent and will be stored
#		in a directory structure that will be returned by an amendable subroutine
#		in this script. This supports testing on a small local pdb directory before
#		transferring to the server 
#	2.	Negative residue numbers feature in some PDB files, but don't feature in any
#		of the FATCAT alignments encountered to date. I ignore negative residue numbers.
#
# Table Structures:
#
# Alignment: 
#
# +-----------------+---------+------+-----+---------+----------------+
# | Field           | Type    | Null | Key | Default | Extra          |
# +-----------------+---------+------+-----+---------+----------------+
# | alignId         | int(11) | NO   | PRI | NULL    | auto_increment |
# | resultId        | int(11) | NO   | MUL | NULL    |                |
# | queryResidueNo  | int(11) | YES  |     | NULL    |                |
# | resultResidueNo | int(11) | YES  |     | NULL    |                |
# | queryResidue    | char(1) | YES  |     | NULL    |                |
# | resultResidue   | char(1) | YES  |     | NULL    |                |
# +-----------------+---------+------+-----+---------+----------------+
#
# Strategy: 
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl input.csv pdbDir out.sql
#			
# Arguments: 
#	input.csv		
#	Extract from the DB with the following fields:
#	A.alignId, E.queryPdb, TPRR.chain, A.queryResisueNo, R.resultPdb, R.chain, 
#	A.resultResidueNo
#	
#	pdbDir
#	The root of the pdb directory	
#
#	out.sql			
#	The SQL output file for loading this data
#	
#####################################################################################

use strict;
use warnings;

use TPRTools;

sub getPDBPath($);
sub getResidue($$);
sub parseResidues($);

if (!(scalar @ARGV == 3)){
	print "Usage: perl input.csv pdbDir out.sql\n";
	exit;
}

my ($in, $pdbDir, $out) = ($ARGV[0], $ARGV[1], $ARGV[2]);

open(INFILE, $in)
      or die "Can't open file $in\n"; 
open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";	

my %residues;	 

my %AA_MAP = 
				(	"ALA" => "A",
					"CYS" => "C",
					"ASP" => "D",
					"GLU" => "E",
					"PHE" => "F",
					"GLY" => "G",
					"HIS" => "H",
					"ILE" => "I",
					"LYS" => "K",
					"LEU" => "L",
					"MET" => "M",
					"ASN" => "N",
					"PRO" => "P",
					"GLN" => "Q",
					"ARG" => "R",
					"SER" => "S",
					"THR" => "T",
					"VAL" => "V",
					"TRP" => "W",
					"TYR" => "Y",
				);
	 
while (my $line = <INFILE>) {
	my @results = split /,/, trim($line);
	my ($alignId, $queryPdbChain, $queryResNo, $resultPdbChain, $resultResNo) =
	($results[0], $results[1].$results[2], $results[3], $results[4].$results[5], $results[6]);
	if (!(exists($residues{$queryPdbChain}))){
		parseResidues($queryPdbChain);
	}
	if (!(exists($residues{$resultPdbChain}))){
		parseResidues($resultPdbChain);
	}	
	my $queryRes = getResidue($queryPdbChain, $queryResNo);
	my $resultRes = getResidue($resultPdbChain, $resultResNo);
	if (defined($queryRes) && defined($resultRes)){
		print OUTFILE "UPDATE Alignment SET queryResidue=\'$queryRes\', resultResidue=\'$resultRes\' WHERE alignId=$alignId;\n";	
	}
}	 

sub getPDBPath($){
	my $pdb = substr($_[0], 0, 4);
	my $pdbMid = substr($pdb, 1, 2);	# PDB file structure stores PDB files based on middle two characters of PDB code
	my $hierarchy = "\/data\/structures\/divided\/pdb\/";
	my ($prefix, $suffix) = ("\/pdb", ".ent.gz");
	return $pdbDir.$hierarchy.$pdbMid.$prefix.$pdb.$suffix;
}

sub getResidue($$){
	my ($pdbChain, $resNo) = ($_[0], $_[1]);
	return $residues{$pdbChain}[$resNo];
}

sub parseResidues($){
	my $pdbChain = $_[0];
	$residues{$pdbChain} = [];
	my $path = getPDBPath($pdbChain);
	my $chainRes = substr($pdbChain,4, length($pdbChain) - 4);
	print "Unzipping $path\n";
	system("gunzip $path");
	$path = substr($path,0,length($path)-3); #Because .gz has been truncated from the end
	if (open(INPDB, $path)){
		while (my $line = <INPDB>){
			if ($line =~ /^ATOM/){
				my $res3 = substr($line, 17, 3);
				my $res = $AA_MAP{$res3};
				my $chainFile = substr($line, 21, 1);
				my $resNo = trim(substr($line, 22, 4));
				if ($chainRes eq $chainFile && $resNo >= 0){	
					# Some PDB files contain negative residue numbers, but none feature in the FATCAT alignments encountered to date
					# With the above clause, we ignore them
					$residues{$pdbChain}[$resNo] = $res;
				}
			}
		}
		close (INPDB);	
	} else {
		print "Unable to open PDB file $path\n";
	}
	print "Zipping $path\n";
	system("gzip $path");
}

close(INFILE);
close(OUTFILE) or die "Unable to close $out\n";