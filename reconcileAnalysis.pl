#####################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Script Name: reconcileAnalysis.pl
# Version: 0001 (30/05/17 21:17)
#
# Purpose: 	To review and provide feedback on the stages of the analysis pipeline that
#			have been completed for a given pdb code, region, and TPR set and to guide
#			the user through the pipeline process, covering the following stages:
#		**	1-3. Identify/add TPR details to the database
#		***	4. Create truncated PDB files
#		***	5. Create directory for results
#		***	6. Run FATCAT DB Search
#		***	7. Add Experiment Details to the DB
#		***	8. Import results into the Results table
#		***	9. Extract highest-scoring results
#		***	10. Move higest-scoring results to a 'top' directory and unzip them
#		***	11. Extract residue alignment frequncies
#		***	12. Determine all pair-wise sets of results and prepare for FATCAT
#		***	13. Run FATCAT in -alignPairs mode
#		***	14. Prepare a similarity matrix for processing in Radiobutton
#		***	15. Perform clustering in R
#
#		*	Completed section
#		**	Section in development
#		*** Section not yet implemented
#
# Assumptions:
#
# Strategy: 
#
# Algorithm:
#
# Error Behaviour:
#
# Usage: perl reconcileAnalysis.pl pdbCode dbp
#			
# Arguments: 
#
#####################################################################################

use strict;
use warnings;
use DBI;

#use TPRTools;

if (!(scalar @ARGV == 1)){
    die "Usage: perl reconcileAnalysis.pl pdbCode dbpw\n";
}
#my $pdb = $ARGV[0];
my $dbp = $ARGV[0];
my $dbname = "md003";
my $dbserver = "hope";
my $datasource = "dbi:mysql:database=$dbname;host=$dbserver";
my @results;
my $i = 0;

print "Enter a PDB code:";
$pdb = <>;

my $dbh = DBI->connect($datasource, $dbname, $dbp);

my $sql = "select * from TPR T left join TPRRegion R on T.regionId = R.regionId where R.pdbCode = '$pdb';";
my $sth = $dbh->prepare($sql);
if ($sth->execute){
	while(@results = $sth->fetchrow_array){
		for (my $i = 0; $i < @results; $i++){
		print defined($results[$i])?$results[$i]:"NULL", " ";
		}
	print "\n";	
	}
}

