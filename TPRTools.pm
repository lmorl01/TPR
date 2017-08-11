#####################################################################################
# David Morley, MSc Bioinformatics 2015-2017
# MSc Project: Origin & Evolution of TPR Domains
# Author: David Morley
# Package Name: TPRTools.pm
# Version: 	0003 (11/06/17 12:28)
# 			0004 (07/08/17) Close INFILE in getStartEndResiduesFromFatcatResultFile
#			0005 (08/08/17) determineChainFromPdbText should only change chain case 
#							for SCOP domain codes, e.g. those beginning with 'd'
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
our @EXPORT = ("determineChainFromPdbText", "determinePdbFromPdbText", "getAminoAcidCode",
	"getChainFromFatcatResultFile", "getPdbCodeFromFatcatResultFile", "getPDBPath",
	"getStartEndResiduesFromFatcatResultFile", "getTTPRs", "truncatePDBFile", "extractAlignmentRegion", "trim");

#sub contains($$);
sub determineChainFromPdbText($);
sub determinePdbFromPdbText($);
sub extractAlignmentRegion($);
sub getAminoAcidCode($);
sub getChainFromFatcatResultFile($);
sub getPdbCodeFromFatcatResultFile($);
sub getPDBPath($$);
sub getStartEndResiduesFromFatcatResultFile($);
sub getTTPRs($);
sub trim($);
sub truncatePDBFile($$$$$);

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

sub determineChainFromPdbText($){

 if ($_[0] =~ m/^d[A-Za-z0-9]{4}([A-Za-z0-9]+)_?$/){
	return uc substr($1,0,1);
 } elsif ($_[0] =~ m/^PDP:([A-Za-z0-9]+)_?$/){
	return substr($1,4,1);
 } elsif ($_[0] =~ m/^[A-Z0-9]{4}.([A-Za-z0-9]){1}$/){
	return $1;
 } else {
	return "";
 }
}

#####################################################################################
# Purpose: 	To extract the PDB code from a 'PDB Text' string generated from FATCAT 
#			analysis
# Arguments: 
# 	string 		$_[0]: the line of output that the PDB code needs to be extracted from
# Return: 
#	a string representing the four-character PDB code in lowercase
# Assumptions:
#	The PDB codes will come in one of three formats as per the examples below:
#	d1914a1		# The PDB code comes after the 'd'
#	1APY.A		# The PDB code comes immediately after the white space and is 
#				  followed by a '.' and an upper or lower case letter or number
#	PDP:2WPXAc	# The PDB code comes after 'PDP:'
# Error Behaviour: 
#	If there's no match to any of the formats above, an empty string is returned
#####################################################################################
 sub determinePdbFromPdbText($){ 

 if ($_[0] =~ m/^d([A-Za-z0-9:.]+_?)$/){
	return lc substr($1,0,4);
 } elsif ($_[0] =~ m/^PDP:([A-Za-z0-9:.]+_?)$/){
	return lc substr($1,0,4);
 } elsif ($_[0] =~ m/^([A-Z0-9]{4}).[A-Za-z0-9]{1}$/){
	return lc $1;
 } else {
	print STDERR "Unexpected pdbText Format: $_[0]\n";
	return "";
 }
}

#####################################################################################
# Purpose: 	To extract the PDB alignment region from a FATCAT search result file
#			and return it in the following format: 1a17:(A:22-125)
# Arguments: 
# 	string 		$_[0]: the alignment filepath
# Return: 
#	a string representing the alignment details in the format 1a17:(A:22-125)
# Assumptions:
#
# Error Behaviour: 
#	If the file is not an xml file, return an empty string
#	
#####################################################################################
sub extractAlignmentRegion($){

	my $pdbCode = getPdbCodeFromFatcatResultFile($_[0]);
	my ($start, $end, $chainId) = getStartEndResiduesFromFatcatResultFile($_[0]);
	return $pdbCode.":(".$chainId.":".$start."-".$end.")";
}

sub getAminoAcidCode($){
	return $AA_MAP{$_[0]};
}

sub getChainFromFatcatResultFile($){
	my $path = $_[0];
	my $chain = "";
	if ($path =~ /.xml/){
		if (open(INFILE, $path)){
			my $header = <INFILE>;
			if ($header =~ /name2=\"([A-Za-z0-9:.]+_?)\"/){
				$chain = determineChainFromPdbText($1);
			}
			close(INFILE);		
		}
		else {
			print STDERR "Unable to open file: ", $path, "\n";
		}
	}
	return $chain;
}


#####################################################################################
# Purpose: 	To extract the PDB code from a FATCAT DB Search result file in the format
#			dbsearch_CUSTOM_d1a17a.xml
# Arguments: 
# 	string 		$_[0]: the path to the file that the PDB code needs to be extracted from
# Return: 
#	a string representing the four-character PDB code in lowercase
# Assumptions:
#	The PDB codes will come in one of three formats as per the examples below:
#	d1914a1		# The PDB code comes after the 'd'
#	1APY.A		# The PDB code comes immediately after the white space and is 
#				  followed by a '.' and an upper or lower case letter or number
#	PDP:2WPXAc	# The PDB code comes after 'PDP:'
# Error Behaviour: 
#	If there's no match to any of the formats above, an empty string is returned
#####################################################################################
sub getPdbCodeFromFatcatResultFile($){
	my $path = $_[0];
	my $pdbCode = "";
	if ($path =~ /.xml/){
		if (open(INFILE, $path)){
			my $header = <INFILE>;
			if ($header =~ /name2=\"([A-Za-z0-9:.]+_?)\"/){
				$pdbCode = determinePdbFromPdbText($1);
			}
			close(INFILE);		
			
		}
		else {
			print STDERR "Unable to open file: ", $path, "\n";
		}
	}
	return $pdbCode;
}


sub getPDBPath($$){
	my $pdb = substr($_[0], 0, 4);
	my $pdbDir = $_[1];
	my $pdbMid = substr($pdb, 1, 2);	# PDB file structure stores PDB files based on middle two characters of PDB code
	my $hierarchy = "\/data\/structures\/divided\/pdb\/";
	my ($prefix, $suffix) = ("\/pdb", ".ent.gz");
	return $pdbDir.$hierarchy.$pdbMid.$prefix.$pdb.$suffix;
}

#####################################################################################
# Purpose: 	To extract the start and end residue numbers of the match/result from a 
#			FATCAT DB Search result file in the format dbsearch_CUSTOM_d1a17a.xml
# Arguments: 
# 	string 		$_[0]: the path to the file that the residue numbers need to be 
#				extracted from
# Return: 
#	an array (start, end, chainID) containing the start and end residue numbers of the 
#	match and the ID of the chain that they feature in
#
# Assumptions:
#
# Error Behaviour: 
#	In the event of a problem, a (0,0) array is returned
#####################################################################################
sub getStartEndResiduesFromFatcatResultFile($){

	my $path = $_[0];
	my $largeNo = 10000000;
	my $start = $largeNo;
	my $end = 0;
	my $chainId = "";
	
	if ($path =~ /.xml/){
		
		open(INFILE, $path);
		while (my $line = <INFILE>){
			if ($line =~ /pdbres2="(\d+)"\schain2="([A-Za-z0-9])"/){
				if ($1 < $start){
					$start = $1;
				}
				if ($1 > $end){
					$end = $1;
				}
				$chainId = $2;
			}
		}
		close(INFILE);
	}
	
	$start = ($start == $largeNo) ? 0 : $start;
	
	return ($start, $end, $chainId);
	
}

#####################################################################################
# Purpose: 	Read TTPRs from an export from the TTPR table and load them into a hash
# Arguments: 
# 	string 		$_[0]: 	the path to the file containing TTPRs
# Return: 
#	string		A reference to a hash of TTPRs. PDBChains (e.g. 1a17A) are the keys.
#				The values are an array representing TTPRs associated with the PDBChains
#				Each value of the array is itself a reference to an array containing
#				the various properties of the TTPR:
#				[0] TTPR Id
#				[1] PDB Code
#				[2] Chain
#				[3] Region Ordinal
#				[4] TPR Ordinal
#				[5] Modal Start Residue
#				[6] Modal End Residue
# Error Behaviour: 
#	None
#####################################################################################
sub getTTPRs($){
	my $in = $_[0];
	open(INFILE, $in)
      or die "Can't open file $in\n"; 
	my %ttprs;
	while (my $line = <INFILE>) {
		my @ttpr = split /,/, trim($line);
		my $pdbChain = $ttpr[1].$ttpr[2];
		if (!exists($ttprs{$pdbChain})){
			$ttprs{$pdbChain} = [];
		}
		push @{$ttprs{$pdbChain}}, \@ttpr;
	}
	return \%ttprs;
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
# 4. 	We don't need to check for the existence of a file by the same name as the 
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
sub truncatePDBFile($$$$$){
my $in = $_[0];
my $out = $_[1];
my $start = $_[2];
my $end = $_[3];
my $chainId = $_[4];
my $removalCount = 0;

open (INFILE, "<$in")
	or die "Can't open file ", $in, "\n";
open (OUTFILE, ">$out")
	or die "Can't create outputfile $out\n";

while (my $line = <INFILE>){
	
	my $remove = 0;

	if (($line =~ /^HELIX/)){
		my $res1 = trim(substr($line, 21,4)); # in the PDB file spec for HELIX, col 22-25 is initial residue seq no.
		my $res2 = trim(substr($line, 33,4)); # in the PDB file spec for HELIX, col 34-37 is terminal residue seq no.
		my $chain1 = substr($line, 19, 1);	 # in the PDB file spec for HELIX, col 20 is initial chain id
		my $chain2 = substr($line, 31, 1);	 # in the PDB file spec for HELIX, col 32 is terminal chain id
		if (($res2 < $start) || ($res1 > $end) || (($chain1 ne $chainId) && ($chain2 ne $chainId))){
			$remove = 1;
			$removalCount++;
		}
	}

	if (($line =~ /^SHEET/)){
		my $res1 = trim(substr($line, 22,4)); # in the PDB file spec for HELIX, col 22-25 is initial residue seq no.
		my $res2 = trim(substr($line, 33,4)); # in the PDB file spec for HELIX, col 34-37 is terminal residue seq no.
		my $chain1 = substr($line, 21, 1);	 # in the PDB file spec for HELIX, col 20 is initial chain id
		my $chain2 = substr($line, 32, 1);	 # in the PDB file spec for HELIX, col 32 is terminal chain id
		if (($res2 < $start) || ($res1 > $end) || (($chain1 ne $chainId) && ($chain2 ne $chainId))){
			$remove = 1;
			$removalCount++;
		}
	}	

	if ($line =~ /^ATOM/){
		my $res = trim(substr($line, 22,4)); # in the PDB file spec for ATOM, col 23-26 is residue seq no.
		my $chain = substr($line, 21, 1);	 # in the PDB file spec for ATOM, col 22 is chain id
		if (($res < $start) || ($res > $end) || ($chain ne $chainId)){
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





1;