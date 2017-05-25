# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Version: 001, 22/01/2017
#
# Purpose: Write a script to populate the the following table:
#
# Field			Key			Indexed	Type	Features
# parameterId	Primary Key	Yes		INT		SERIAL DEFAULT VALUE
# tprCount							INT		NOT NULL
# optionOrdinal						INT		NOT NULL
# startTpr							INT		NOT NULL
# endTpr							INT		NOT NULL
# sh								BOOLEAN	NOT NULL
#
# The table contains all (N+1)N/2 options for selecting a sub-range of consecutive TPRs from an range of consecutive TPRs.
# For instance, from a range of 3 TPRs, you can select TPR1, TPR2, TPR3, TPR1-TPR2, TPR2-TPR3, TPR1-TPR3 and the rows
# associated with this in the table should be:
# 	tprCount	optionOrdinal	startTpr	endTpr	sh
# 	3			1				1			1		FALSE
# 	3			2				2			2		FALSE
#	3			3				3			3		FALSE
#	3			4				1			2		FALSE
#	3			5				2			3		FALSE
#	3			6				1			3		FALSE
#	Finally, all options that end with the last TPR in the set have the option of having the solvating helix included
#	and therefore a further set of N rows is added, for example:
# 	tprCount	optionOrdinal	startTpr	endTpr	sh
#	3			7				1			3		TRUE
#	3			8				2			3		TRUE
#	3			9				3			3		TRUE
#
# Program writes lines of the form:
# INSERT INTO ParameterSet (tprCount, optionOrdinal, startTpr, endTpr) VALUES (w, x, y, z)
#
# Usage: perl writePopulateParameterSetSQL.pl x 
# where x is the maximum number of TPRs up to which you want the script to generate population parameters

$max = @ARGV[0];
open(OUTFILE, ">PopulateParameterSet.sql");

# for loop for each possible number of TPRs (e.g. 1, 2, 3, 4, ...)
for ($tprCount=1; $tprCount <= $max; $tprCount++){
	$ordinal = 0;
	# for loop for each possible length of consecutive TPRs therein (e.g. 1, 2, 3 for 3 TPRs)
	for ($length=1; $length <= $tprCount; $length++){
			# for loop for each possible consecutive set of the given length
			for ($i=1; $i <= $tprCount - $length + 1; $i++){
				$ordinal++;
				printline($tprCount, $ordinal, $i, $i + $length - 1, 0);	
			}
		}
	# now do the solvating helix options	
	for ($i = 1; $i <= $tprCount; $i++){
		$ordinal++;
		printline($tprCount, $ordinal, $i, $tprCount, 1);
	}
}

close(OUTFILE) or die "Unable to close output file";

#print(printline("w", "x", "y", "z"));

sub printline($$$$){
	print OUTFILE "INSERT INTO ParameterSet (tprCount, optionOrdinal, startTpr, endTpr, solvatingHelix) VALUES (" . $_[0] . ", " . $_[1] . ", " . $_[2] . ", " . $_[3] . ", " . $_[4] . ");\n";
}




