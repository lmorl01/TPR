#####################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Version: 004, 03/06/2017
#
# Version History:
# 004: Addition of norm_RMSD column to the database
#
# Purpose: Write a script to populate the the following table:
#
# +-------------------+-------------+------+-----+---------+----------------+
# | Field             | Type        | Null | Key | Default | Extra          |
# +-------------------+-------------+------+-----+---------+----------------+
# | resultId          | int(11)     | NO   | PRI | NULL    | auto_increment |
# | experimentId      | int(11)     | YES  | MUL | NULL    |                |
# | resultPdb         | char(4)     | YES  | MUL | NULL    |                |
# | resultPdbText     | varchar(50) | YES  |     | NULL    |                |
# | score             | float       | YES  |     | NULL    |                |
# | probability       | float       | YES  |     | NULL    |                |
# | rmsd              | float       | YES  |     | NULL    |                |
# | norm_rmsd         | float       | YES  |     | NULL    |                |
# | len1              | int(11)     | YES  |     | NULL    |                |
# | len2              | int(11)     | YES  |     | NULL    |                |
# | cov1              | int(11)     | YES  |     | NULL    |                |
# | cov2              | int(11)     | YES  |     | NULL    |                |
# | percentId         | float       | YES  |     | NULL    |                |
# | alignedResidues   | int(11)     | YES  |     | NULL    |                |
# | targetDescription | text        | YES  |     | NULL    |                |
# +-------------------+-------------+------+-----+---------+----------------+
#
# Program writes lines of the form:
# INSERT IGNORE INTO PDBEntry (pdbCode) VALUES (CHAR(4));
# INSERT INTO Results (experimentId, resultPdb, resultPdbText, score, probability, rmsd, norm_rmsd, len1, len2, cov1, cov2, percentId, alignedResidues, 
# targetDescription) VALUES (INT, CHAR(4), VARCHAR, FLOAT, FLOAT, FLOAT, FLOAT, INT, INT, INT, INT, FLOAT, INT, TEXT)
#
# Usage: perl writePopulateResults.pl experimentId results_CUSTOM.out populateResults.sql
# where...
# experimentId is a foreign key to an entry in the table Experiment 
# results_CUSTOM.out is an output file in the standard format produced by the FATCAT program
# populateResults.sql is the output file
#####################################################################################

use strict;
use warnings;

use TPRTools;

sub writePdbEntry($$);
sub writeResults($$$$$$$$$$$$$$);

if (!(scalar @ARGV == 3 && $ARGV[0] =~ /^\d+$/)){
	print "Usage: perl writePopulateResults.pl experimentId results_CUSTOM.out populateResults.sql\n";
	exit;
}

 my $experimentId = $ARGV[0];
 my $in = $ARGV[1];
 my $out = $ARGV[2];
 open(OUTFILE, ">$out")
	 or die "Can't create output file $out\n";
open(INFILE, $in)
      or die "Can't open file $in\n";  

my $header = <INFILE>; 	#Discard the first line of the file 
$header = <INFILE>; 	#Discard the second line of the file
$header = <INFILE>;		#Read the input file so that the query PDB can be extracted

if ($header =~ m/([a-z0-9]{4})(_[0-9])?_TPR/){
	my $queryPdb = $1;
	print "Query PDB: ", $queryPdb, "\n";
}
else {
	die "Unable to extract Query PDB Code from $in\n"; 
}

while (my $line = <INFILE>) {
	my @results = split /\t/, $line;	
	my $targetPdb = determinePdbFromPdbText($results[1]);
	my $alignedResidues = int (($results[5]/100)*$results[7]); 	# (len1/100)*cov1
	my $norm_rmsd = $results[4]/sqrt($alignedResidues);			# normalised RMSD = RMSD/sqrt(n)
	writePdbEntry($targetPdb, $results[10]);
	writeResults($experimentId, $targetPdb, $results[1], $results[2], $results[3], $results[4], $norm_rmsd, $results[5], $results[6], $results[7], $results[8], $results[9], $alignedResidues, $results[10]);
 }  
 close(INFILE) or die "Unable to close input file";
 close(OUTFILE) or die "Unable to close output file";

 sub writePdbEntry($$){
	print OUTFILE "INSERT IGNORE INTO PDBEntry (pdbCode) VALUES (\"$_[0]\");\n";
 }
 
 sub writeResults($$$$$$$$$$$$$){
	print OUTFILE "INSERT INTO Results (experimentId, resultPdb, resultPdbText, score, probability, rmsd, norm_rmsd, len1, len2, cov1, cov2, percentId, alignedResidues, targetDescription) VALUES ($_[0], \"$_[1]\", \"$_[2]\", $_[3], $_[4], $_[5], $_[6], $_[7], $_[8], $_[9], $_[10], $_[11], $_[12], \"$_[13]\");\n";
 }