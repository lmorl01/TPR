#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: msa.pl
# Version: 0002 (18/06/17 18:47)
#
# Purpose: 	Given a seed file associating a search strusture with the 34 residues 
#			of the TPR motif, a directory of alignment result files and a directory
#			of corresponding PDB files, perform a multiple sequence alignment and
#			output this to file
#
# Input file format: The seed file should be a CSV file with the first line as the
# header listing the ordinal numbers in the TPR motif from 1 to 34 and each subsequent
# line being the residue numbers corresponding to the 34 residues in the TPR motif 
# for a TPR in the associated sequence, for example:
# 
# 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34
# 28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61
# 62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95
# 96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129
#
# Strategy: 
#	1. 	
#
# Error Behaviour:
# 1. Print usage instructions if incorrect number of arguments
#
# Usage: perl msa.pl seed.csv resultsDir pdbDir	out.msa	info.out	
#
#####################################################################################

use strict;
use warnings;

use TPRTools;

if (!(scalar @ARGV == 5 )){
	print "Usage: perl msa.pl seed.csv resultsDir pdbDir out.msa info.out\n";
	exit;
}

my $in = $ARGV[0];
my $resultDir = $ARGV[1];
my $pdbDir = $ARGV[2];
my $out = $ARGV[3];
my $info = $ARGV[4];

open(IN, $in)
      or die "Can't open file $in\n"; 
open(OUTFILE, ">$out")
    or die "Can't create outputfile $out\n"; 

open(INFO, ">$info")
    or die "Can't create outputfile $info\n"; 
	
opendir RESDIR, $resultDir
    or die "can't open directory $resultDir\n";
	
opendir PDBDIR, $pdbDir
    or die "can't open directory $pdbDir\n";

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

	
my %residues;
my %sequences;
my %insertions;
my @query;
my @queryToIndex;

my @maxInsertLengths = (0) x 34;

my $junk = <IN>;

# Read query TPRs
while (my $line = <IN>) {
	my @queryResidues = split /,/, trim($line);
	$query[@query] = \@queryResidues;
	for (my $i = 0; $i < @queryResidues; $i++){
		 $queryToIndex[$queryResidues[$i]] = $i;
	}
}

# Print Query TPR to info file
for (my $i = 0; $i < @query; $i++){
	 for (my $j = 0; $j < scalar @{$query[$i]}; $j++){
		 print INFO $query[$i][$j], " ";
	 }
	print INFO "\n";
}

my @alignmentFiles = readdir RESDIR;	

foreach (my $i = 0; $i < @alignmentFiles; $i++){
	my $path = $resultDir."\\".$alignmentFiles[$i];
	if ($alignmentFiles[$i] =~ /.xml/){
		my $pdbCode = getPdbCodeFromFatcatResultFile($path);
		my $chain = getChainFromFatcatResultFile($path);
		my $pdbChain = $pdbCode.".".$chain;
		open(INFILE, $path)
			or die "Can't open file ", $path, "\n";	
		print INFO "Processing PDB: $pdbCode, Chain: $chain, PDB Chain: $pdbChain\n";		
		my @emptyArray1;
		my @emptyArray2;
		$residues{$pdbChain} = \@emptyArray1;
		$insertions{$pdbChain} = \@emptyArray2;


		my ($prevRes1, $prevRes2) = (0,0);
		while (my $line = <INFILE>){
			if ($line =~ /pdbres1="(\d+)"\schain1="([A-Za-z0-9])"\spdbres2="(\d+)"\schain2="([A-Za-z0-9])"/){
				my ($res1, $chain1, $res2, $chain2) = ($1, uc $2, $3, uc $4);
				if ($prevRes1 == 0 && $prevRes2 == 0){
					$prevRes1 = $res1 - 1;
					$prevRes2 = $res2 - 1;
				}
				#print "($chain1.$res1, $chain2.$res2)\n";
				$residues{$pdbChain}[$res1] = $res2;
				for (my $j = 0; $j < @query; $j++){
					 if ($res1 > $query[$j][0] && $res1 <= $query[$j][33]){
						 # Check for insertions
						 if ($res2 > ($prevRes2 + 1)){
							 my $insertSize = $res2 - $prevRes2 - 1;
							 $insertions{$pdbChain}[$res2] = $insertSize;
							 print INFO "Insertion of size $insertSize before $pdbChain, result residue $res2, query residue $res1, TPR index $queryToIndex[$res1]\n";
							 if ($maxInsertLengths[$queryToIndex[$res1]] < $insertSize){
								$maxInsertLengths[$queryToIndex[$res1]] = $insertSize;
								
							 }
						 }
						 if ($res1 > ($prevRes1 + 1)){
							 my $deleteSize = $res1 - $prevRes1 - 1;
							 print INFO "Deletion of size $deleteSize before $pdbChain, residue $res2\n";							
						 }						 
					 }				
				}
				($prevRes1, $prevRes2) = ($res1, $res2);
			}
		}
		close(INFILE);	
	}
}

my @pdbFiles = readdir PDBDIR;

 foreach (my $i = 0; $i < @pdbFiles; $i++){
	my $path = $pdbDir."\\".$pdbFiles[$i];
	my $atomCount = 0;
	if ($pdbFiles[$i] =~ /.ent/){ 
		open(INFILE, $path)
			or die "Can't open file ", $path, "\n";
		my $header = <INFILE>;
		my $pdbCode = lc(substr($header, 62,4));
		print "Reading PDB file $pdbCode\n";

		#print "PDB: $pdbCode\n";
		my ($aaName, $aa, $resPrev) = ("","",0);
		while (my $line = <INFILE>){
			if ($line =~ /^ATOM/){
				$atomCount++;
				my $aaName = substr($line, 17, 3);
				my $aa = $AA_MAP{$aaName};
				my $res = trim(substr($line, 22, 4));
				my $chain = uc substr($line, 21, 1);
				my $pdbChain = $pdbCode.".".$chain;
				if (!exists($sequences{$pdbChain})){
					my @emptyArray;
					$sequences{$pdbChain} = \@emptyArray;		
				}
				#if ($res != $resPrev){
				if ($res != $resPrev && $res >= 0){
					$sequences{$pdbChain}[$res] = $aa;
					#print $res, $sequences{$pdbCode}[$res], ",";
					$resPrev = $res;
				}
				
			}
		}
		#print "\n$atomCount atom lines read\n";	
		close(INFILE);	
	}
 }

foreach my $pdb (sort keys %residues){
	print OUTFILE "\n$pdb: ";
	for (my $i = 0; $i < @query; $i++){
	my $tprOrdinal = $i + 1;
	#print OUTFILE "$pdb TPR $tprOrdinal: ";
		for (my $j = 0; $j < scalar @{$query[$i]}; $j++){
			
			#if (defined($residues{$pdb}[$query[$i][$j]]) && defined($insertions{$pdb}[$residues{$pdb}[$query[$i][$j]]])){
			if ($maxInsertLengths[$queryToIndex[$query[$i][$j]]]){
			#if (defined($insertions{$pdb}[$residues{$pdb}[$query[$i][$j]]])){
			
				#print OUTFILE "*";
				
				# my $insertSize = $insertions{$pdb}[$residues{$pdb}[$query[$i][$j]]];
				# for (my $k = 1; $k <= $insertSize; $k++){
					# #print "X";
					# #if (defined($residues{$pdb}[$query[$i][$j] + $k]) && defined($sequences{$pdb}[$residues{$pdb}[$query[$i][$j] + $k]])){
					# if (defined($residues{$pdb}[$query[$i][$j]]) && defined($sequences{$pdb}[$residues{$pdb}[$query[$i][$j]] + $k])){
						# print OUTFILE $sequences{$pdb}[$residues{$pdb}[$query[$i][$j]] + $k];
					# } else {
						# print OUTFILE "X";
					# }
					
				# }
				# my $gap = $maxInsertLengths[$queryToIndex[$query[$i][$j]]] - $insertSize;
				# for (my $k = 0; $k < $gap; $k++){
					# print OUTFILE "-";
				# }
							
			# }
			# else {
				# for (my $count = 0; $count < $maxInsertLengths[$queryToIndex[$query[$i][$j]]]; $count++){
					# print OUTFILE "-";
				# }		
			}			
			if (defined($residues{$pdb}[$query[$i][$j]]) && defined($sequences{$pdb}[$residues{$pdb}[$query[$i][$j]]])){
				print OUTFILE $sequences{$pdb}[$residues{$pdb}[$query[$i][$j]]];
			} else {
				print OUTFILE "-";
			}
		}
			#print OUTFILE "\n";	#This line determines whether we get each TPR on a separate line all TPRs in series on the same line
	 }	
}

print "Largest insertions:\n";
foreach (my $i = 1; $i < @maxInsertLengths; $i++){
	if ($maxInsertLengths[$i] > 0){
			print "$i: $maxInsertLengths[$i]\n";
	}
	
}

close(OUTFILE);
close(INFO);

 