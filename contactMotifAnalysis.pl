#################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: contactMotifAnalysis.pl
# Version: 	0001	18/08/17
#
# Purpose: 	Using an extract of TTPR Contacts derived using getTTPRMotifContacts.sql,
#			determine the frequency of different contact-pairs at each position in
#			the motif
#
# Assumptions:
#
# Strategy: 
#	
#	
#
#
# Error Behaviour:
# 	1. Print usage instructions if incorrect number of arguments
#
# Usage: perl contactMotifAnalysis.pl contacts.csv motifFrequencies.csv residueFrequencies.csv
#			
# Arguments: 
#	contacts.csv			Extract from the DB using getTTPRMotifContacts.csv
#	motifFrequencies.csv 	Combined motif frequency data
#	residueFrequencies.csv	Combined residue-residue frequency data
#
#####################################################################################

use strict;
use warnings;

use TPRTools;

if (!(scalar @ARGV == 3)){
    die "Usage: perl contactMotifAnalysis.pl contacts.csv motifFrequencies.csv residueFrequencies.csv\n";
}

my $in = $ARGV[0];
my $out1 = $ARGV[1];
my $out2 = $ARGV[2];
my $motifLength = 34;

open (INFILE, "<$in")
	or die "Can't open file ", $in, "\n";

open(OUTMOTIF, ">$out1")
	 or die "Can't create output file $out1\n";

open(OUTRES, ">$out2")
	 or die "Can't create output file $out2\n";
	 
my @residueContacts;
my @motifContacts;
#my %emptyHash = ();
for (my $i = 0; $i < $motifLength + 1; $i++){
	 my %emptyHash = ();
	 $residueContacts[$i] = \%emptyHash;
	 #%emptyHash = ();
	#$residueContacts[$i] = 0;
}

push @motifContacts, [(0) x (($motifLength*3)+1)] for (0..($motifLength+1));

while (my $line = <INFILE>){
	my @values = split /,/, trim($line);
	my ($pdbCode, $tprOrdinal, $tprStart, $tprEnd, $resNo1, $resNo2, $helix1, $helix2, $res1, $res2, $motif1, $motif2, $tprOrdinal1, $tprOrdinal2)
		= @values;
	
	###############################################
	## Process contact frequencies by motif number
	###############################################
	# Add forward connection
	my $motifPosition = ($tprOrdinal2 - $tprOrdinal1 + 1)*$motifLength + $motif2;
	$motifContacts[$motif1][$motifPosition]++;
	# Add backward connection
	$motifPosition = ($tprOrdinal1 - $tprOrdinal2 + 1)*$motifLength + $motif1;
	$motifContacts[$motif2][$motifPosition]++;
	
	###############################################
	## Process residue-residue combinations
	###############################################
	# Add forward connection
	my $key1 = $res1;
	my $direction = 0;
	# Pointing back to the previous TPR
	if($tprOrdinal2 < $tprOrdinal1){
		$direction = 0;
	}
	# Pointing back in the same TPR
	elsif ($motif2 < $motif1 && $tprOrdinal2 == $tprOrdinal1){
		$direction = 1;
	}
	#Pointing forward in the same TPR
	elsif($motif2 > $motif1 && $tprOrdinal2 == $tprOrdinal1){
		$direction = 2;
	}
	# Pointing forward to the next TPR
	elsif ($tprOrdinal2 >  $tprOrdinal1){
		$direction = 3;
	} else{
		print "\nUnexpected line:\n$line\n";
	}
	my $key2 = $direction.$res2;
	print $motif1, "\n", $key1, "\n", $key2, "\n";
	if (!defined($residueContacts[$motif1]{$key1})){
		 my %emptyHash = ();
		 $residueContacts[$motif1]{$key1} = \%emptyHash;
	}
	if (!defined($residueContacts[$motif1]{$key1}{$key2})){
		 $residueContacts[$motif1]{$key1}{$key2} = 1;
	} else {
		$residueContacts[$motif1]{$key1}{$key2}++;
	}

	# Add backward connection
	my $key1 = $res2;
	my $direction = 0;
	# Pointing back to the previous TPR
	if($tprOrdinal1 < $tprOrdinal2){
		$direction = 0;
	}
	# Pointing back in the same TPR
	elsif ($motif1 < $motif2 && $tprOrdinal1 == $tprOrdinal2){
		$direction = 1;
	}
	#Pointing forward in the same TPR
	elsif($motif1 > $motif2 && $tprOrdinal1 == $tprOrdinal2){
		$direction = 2;
	}
	# Pointing forward to the next TPR
	elsif ($tprOrdinal1 >  $tprOrdinal2){
		$direction = 3;
	} else{
		print "\nUnexpected line:\n$line\n";
	}
	my $key2 = $direction.$res1;
	print $motif2, "\n", $key1, "\n", $key2, "\n";
	if (!defined($residueContacts[$motif2]{$key1})){
		 my %emptyHash = ();
		 $residueContacts[$motif2]{$key1} = \%emptyHash;
	}
	if (!defined($residueContacts[$motif2]{$key1}{$key2})){
		 $residueContacts[$motif2]{$key1}{$key2} = 1;
	} else {
		$residueContacts[$motif2]{$key1}{$key2}++;
	}
	
}


###############################################
## Output contact frequencies by motif number
###############################################

# Header
print OUTMOTIF ",";
for (my $i = 1; $i <= $motifLength*3; $i++){
	my $res = ($i <= 34) ? 'A'.$i : ($i <= 68) ? 'B'.($i - 34) : 'C'.($i - 68) ;
	print OUTMOTIF $res, ",";
}
print OUTMOTIF "\n";

# Iterate over each motif number
 for (my $i = 1; $i <= $motifLength; $i++){
	 print OUTMOTIF "A".$i.",";
	 # Iterate over each residue position in preceding, current and succeeding TPR
	 for (my $j = 1; $j <= $motifLength*3; $j++){
		print OUTMOTIF $motifContacts[$i][$j], ",";
	 }
	 print OUTMOTIF "\n";
 }


###############################################
## Output residuec contact frequencies by residue
###############################################

# Iterate over every position in the motif
for (my $i = 1; $i < $motifLength + 1; $i++){

	# Determine all posible targets for contacts from this position	
	my %allKey2;
	foreach my $key1 (sort keys %{$residueContacts[$i]}){
		foreach my $key2 (sort keys %{$residueContacts[$i]{$key1}}){
			if (!defined($allKey2{$key2})){
				$allKey2{$key2} = 1;
			}
		}
	}

	# print header for this position in the motif
	print OUTRES "Residue $i,";
	foreach my $key2 (sort keys %allKey2){
		 print OUTRES $key2, ",";
	}
	print OUTRES "\n";
	
	# Iterate over all residues that feature at this position
	foreach my $key1 (sort keys %{$residueContacts[$i]}){
		# Print row header
		print OUTRES $key1, ",";
		
		# Iterate over all targets for contacts from this position
		foreach my $key2 (sort keys %allKey2){		
			if (defined($residueContacts[$i]{$key1}{$key2})){
				print OUTRES $residueContacts[$i]{$key1}{$key2}, ",";
			}
			else {
				print OUTRES "0,";
			}
		}
		print OUTRES "\n";
	}
}
	



close(INFILE);
close(OUTMOTIF);
close(OUTRES);








	
	 
	 