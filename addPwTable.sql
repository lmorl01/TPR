-- David Morley, MSc Bioinformatics 2015-2017
-- MSc Project: Origin & Evolution of TPR Domains
-- Version: addPwTable.sql, 01/06/2017
-- Purpose: Update the Database Schema to add a new table for storing
-- pairwise similarity data from FATCAT -alignPairs 

DROP TABLE IF EXISTS PWSimilarity;

CREATE TABLE PWSimilarity
(	pwId				INT				SERIAL DEFAULT VALUE,
	experimentId		INT				,
	pdb1				CHAR(4)			,
	chain1				CHAR(1)			,
	start1				INT				,
	end1				INT				,
	pdb2				CHAR(4)			,
	chain2				CHAR(1)			,
	start2				INT				,
	end2				INT				,
	score				FLOAT			,
	probability			FLOAT			,
	rmsd				FLOAT			,
	rmsdNorm			FLOAT			,
	len1				INT				,
	len2				INT				,
	cov1				INT				,
	cov2				INT				,
	percentId			FLOAT			,
	alignedResidues		INT				,
	PRIMARY KEY (pwId),
	FOREIGN KEY (experimentId) REFERENCES Experiment(experimentId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (pdb1) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (pdb2) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE
);

CREATE INDEX ixPwId ON PWSimilarity (pwId);
CREATE INDEX ixPdb1 ON PWSimilarity (pdb1);
CREATE INDEX ixPdb2 ON PWSimilarity (pdb2);
