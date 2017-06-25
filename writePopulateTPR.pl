# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Version: 001, 30/01/2017
#
# Purpose: Write a script to populate the the following table:
#
# +--------------+---------+------+-----+---------+----------------+
# | Field        | Type    | Null | Key | Default | Extra          |
# +--------------+---------+------+-----+---------+----------------+
# | tprId        | int(11) | NO   | PRI | NULL    | auto_increment |
# | regionId     | int(11) | NO   | MUL | NULL    |                |
# | startResidue | int(11) | NO   |     | NULL    |                |
# | endResidue   | int(11) | NO   |     | NULL    |                |
# | tprOrdinal   | int(11) | NO   |     | NULL    |                |
# +--------------+---------+------+-----+---------+----------------+
#
# Program writes lines of the form:
# INSERT INTO TPR (regionId, startResidue, endResidue, tprOrdinal) VALUES (w, x, y, z)
#
# Usage: perl writePopulatePDBEntrySQL.pl input.csv
# where input.csv is a comma-separated export from Excel of TPR details containing regionId codes that
# already exist in the table TPRRegion


$in = @ARGV[0];
$out = "PopulateTPR.sql";
open(OUTFILE, ">$out")
	or die "Can't create output file $in\n";
open(INFILE, $in)
      or die "Can't open file $in\n";  

while (my $line = <INFILE>) {
   printline($line);
}  
close(INFILE) or die "Unable to close input file";

close(OUTFILE) or die "Unable to close output file";

sub printline($){
	$line = $_[0];
	chomp $line;
	my ($regionId, $startResidue, $endResidue, $tprOrdinal) = split /,/, $line, 4;
	print OUTFILE "INSERT INTO TPR (regionId, startResidue, endResidue, tprOrdinal) VALUES (\"", $regionId, "\",\"", $startResidue, "\",\"", $endResidue, "\",\"", $tprOrdinal, "\");\n";
}




