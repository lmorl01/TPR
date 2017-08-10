-- David Morley, MSc Bioinformatics 2015-2017
-- MSc Project: Origin & Evolution of TPR Domains
-- Version 	01: addPwTable.sql, 01/06/2017
--			02: New table definition, 10/08/17
-- Purpose: Update the Database Schema to add a new table for storing
-- pairwise similarity data from FATCAT -alignPairs 

CREATE TABLE PWSimilarity
(	pwId				INT				SERIAL DEFAULT VALUE,
	ttprId1				INT				,
	pdb1				CHAR(4)			,
	chain1				CHAR(5)			,
	start1				INT				,
	end1				INT				,
	ttprId2				INT				,
	pdb2				CHAR(4)			,
	chain2				CHAR(5)			,
	start2				INT				,
	end2				INT				,
	tprCount			INT				,
	score				FLOAT			,
	norm_score			FLOAT			,
	probability			FLOAT			,
	rmsd				FLOAT			,
	norm_rmsd			FLOAT			,
	len1				INT				,
	len2				INT				,
	cov1				INT				,
	cov2				INT				,
	percentId			FLOAT			,
	alignedResidues		INT				,
	PRIMARY KEY (pwId),
	FOREIGN KEY (ttprId1) REFERENCES TentativeTPR(ttprId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (ttprId2) REFERENCES TentativeTPR(ttprId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (pdb1) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (pdb2) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE
);