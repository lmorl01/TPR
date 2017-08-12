
-------------------------------------------------------------------------------------------------
-- David Morley, MSc Bioinformatics 2015-2017
-- MSc Project: Origin & Evolution of TPR Domains
-- Version: 006, 10/08/2017
-- Version History:
-- 001: Initial Version creates tables PDBEntry, TPRRegion, TPR, Experiment, Result
-- 002: Amendments to tables Experiment & Result and addition of table ParameterSet
-- 003: Addition of creation statement for table PWSimilarity
-- 004: Addition of creation statement for TentativeTPR and SearchHit tables
-- 005: Updated to reflect latest status of the DB. TentativeTPR and SearchHit tables were made
-- 		obsolete. New TentativeTPR table created. 'superseded' fields added to a number of tables
--		Alignment table added including indexes on queryResidueNo and resultResidueNo. INDEXES
--		added on TPR.startResidue, TPR.endResidue
-- 006: New PWSimilarity table
-------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-----------------------------------------ACTIVE TABLES-------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

CREATE TABLE PDBEntry
(	pdbCode			CHAR(4)			NOT NULL,
	protein			TEXT			,			
	PRIMARY KEY (pdbCode)		
);

CREATE TABLE TPRRegion
(	regionId 		INT				SERIAL DEFAULT VALUE,
	pdbCode			CHAR(4)			NOT NULL,
	chain			VARCHAR(5)		NOT NULL,
	regionOrdinal	INT				NOT NULL,
	shEndResidue	INT				,
	tprCount		INT				,
	superseded		BOOLEAN			,
	PRIMARY KEY (regionId),
	FOREIGN KEY (pdbCode) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT
		ON UPDATE CASCADE
);

CREATE INDEX ixpdbCode ON TPRRegion(pdbCode);

CREATE TABLE TPR
(	tprId 			INT				SERIAL DEFAULT VALUE,
	regionId		INT				NOT NULL,
	startResidue	INT				NOT NULL,
	endResidue		INT				NOT NULL,
	tprOrdinal		INT				NOT NULL,
	superseded		BOOLEAN			,
	PRIMARY KEY (tprId),
	FOREIGN KEY (regionId) REFERENCES TPRRegion (regionId) 
		ON DELETE RESTRICT 
		ON UPDATE CASCADE
);

CREATE INDEX ixregionId ON TPR(regionId);
CREATE INDEX ixstartResidue on TPR(startResidue);
CREATE INDEX ixendResidue on TPR(endResidue);

CREATE TABLE ParameterSet
(	parameterId			INT				SERIAL DEFAULT VALUE,
	tprCount			INT				NOT NULL,
	optionOrdinal		INT				NOT NULL,
	startTpr			INT				NOT NULL,
	endTpr				INT				NOT NULL,
	solvatingHelix		BOOLEAN			NOT NULL,
	PRIMARY KEY (parameterId),
);

CREATE TABLE Experiment
(	experimentId	INT				SERIAL DEFAULT VALUE,
	parameterId		INT				NOT NULL,
	experimentDate	DATE			NOT NULL,
	queryPdb		CHAR(4)			NOT NULL,
	regionId		INT				NOT NULL,
	flexible		BOOLEAN			NOT NULL,
	pdbDatabase		TEXT			NOT NULL,
	resultsLocation	TEXT			NOT NULL,
	cmdLineOutput	TEXT			NOT NULL,
	superseded		INT				,
	PRIMARY KEY (experimentId),
	FOREIGN KEY (parameterId) REFERENCES ParameterSet(parameterId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,		
	FOREIGN KEY (queryPdb) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,	
	FOREIGN KEY (regionID) REFERENCES TPRRegion(regionID)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,			
);

CREATE INDEX ixQueryPdb ON Experiment (queryPdb);
CREATE INDEX ixRegionId ON Experiment (regionId);
CREATE INDEX ixParameterId ON Experiment (parameterId);

CREATE TABLE Results
(	resultId			INT				SERIAL DEFAULT VALUE,
	experimentId		INT				,
	resultPdb			CHAR(1)			,
	resultPdbText		VARCHAR(50)		,
	chain				VARCHAR(5)		,
	start				INT				,
	end					INT				,
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
	blocks				INT				,
	alignedResidues		INT				,
	targetDescription	TEXT			,
	PRIMARY KEY (resultId),
	FOREIGN KEY (experimentId) REFERENCES Experiment(experimentId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (resultPdb) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE
);

CREATE INDEX ixExperimentId ON Results (experimentId);
CREATE INDEX ixResultPdb ON Results (resultPdb);

CREATE TABLE TTPRParameters
(	ttprParamId			INT				SERIAL DEFAULT VALUE,
	norm_rmsd			FLOAT			,
	norm_score			FLOAT			,
	probability			FLOAT			,
	cov1				FLOAT			,
	blocks				CHAR(20)		,
	tprTolerance		INT				,
	regionTolerance		INT				,
	analysisDate		DATE			,
	inputFile			TEXT			,
	superseded			INT
	PRIMARY KEY (ttprParamId),
);

CREATE TABLE TentativeTPR
(	ttprId 			INT				SERIAL DEFAULT VALUE,
	ttprParamId		INT				NOT NULL,
	pdbCode			CHAR(4)			NOT NULL,
	chain			CHAR(5)			NOT NULL,
	regionOrdinal	INT				,
	tprOrdinal		INT				,
	startMean		FLOAT			,
	startMedian		FLOAT			,
	startMode		INT				,
	startMax		INT				,
	startMin		INT				,
	endMean			FLOAT			,
	endMedian		FLOAT			,
	endMode			INT				,
	endMax			INT				,
	endMin			INT				,
	abAngle			FLOAT			,
	aaAngle			FLOAT			,
	baAngle			FLOAT			,
	PRIMARY KEY (ttprId),
	FOREIGN KEY (pdbCode) REFERENCES PDBEntry (pdbCode) 
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (ttprParamId) REFERENCES TTPRParameters (ttprParamId) 
		ON DELETE RESTRICT 
		ON UPDATE CASCADE	
);

CREATE INDEX ixttprPdbCode ON TentativeTPR(pdbCode);
CREATE INDEX ixttprParamId ON TentativeTPR(ttprParamId);

CREATE TABLE Alignment
(	alignId			INT				SERIAL DEFAULT VALUE,
	resultId		INT				NOT NULL,
	queryResidueNo	INT				,
	resultResidueNo	INT				,
	queryResidue	CHAR(1)			,
	resultResidue	CHAR(1)			,
	PRIMARY KEY (alignId),
	FOREIGN KEY (resultId) REFERENCES Results(resultId)
		ON DELETE RESTRICT
		ON UPDATE CASCADE
);

CREATE INDEX ixalignId ON Alignment(alignId);
CREATE INDEX ixresultId ON Alignment(resultId);
CREATE INDEX ixqueryResidueNo ON Alignment(queryResidueNo);
CREATE INDEX ixresultResidueNo ON Alignment(resultResidueNo);

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

CREATE INDEX ixPdb1 ON PWSimilarity (pdb1);
CREATE INDEX ixPdb2 ON PWSimilarity (pdb2);
CREATE INDEX ixttprId1 ON PWSimilarity (ttprId1);
CREATE INDEX ixttprId2 ON PWSimilarity (ttprId2);

CREATE TABLE Sequence
(	pdbCode			CHAR(4)			NOT NULL,
	chain			CHAR(5)			NOT NULL,
	residueNo		INT				NOT NULL,
	residue			CHAR(1)			NOT NULL,
	PRIMARY KEY (pdbCode,chain,residueNo),
	FOREIGN KEY (pdbCode) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE	
);
CREATE INDEX ixChain ON Sequence (chain);
CREATE INDEX ixResidueNo ON Sequence (residueNo);

CREATE TABLE TPRMotifAlignment
(	tprMotifId		INT				SERIAL DEFAULT VALUE,
	tprId			INT				NOT NULL,
	motifNo			INT				NOT NULL,
	residueNo		INT				NOT NULL,
	PRIMARY KEY (tprMotifId),
	FOREIGN KEY (tprId) REFERENCES TPR(tprId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE	
);
CREATE INDEX ixtprId ON TPRMotifAlignment (tprId);
CREATE INDEX ixmotifNo ON TPRMotifAlignment (motifNo);
CREATE INDEX ixresidueNo ON TPRMotifAlignment (residueNo);

CREATE TABLE Contact
(	contactId		INT				SERIAL DEFAULT VALUE,
	pdbCode			CHAR(4)			NOT NULL,
	chain			CHAR(5)			NOT NULL,
	helix1			INT				,
	helix2			INT				,
	residue1		INT				NOT NULL,
	residue2		INT				NOT NULL,
	PRIMARY KEY (contactId),
	FOREIGN KEY (pdbCode) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE	
);
CREATE INDEX ixPdbCode ON Contact (pdbCode);
CREATE INDEX ixChain ON Contact (chain);
CREATE INDEX ixResidue1 ON Contact (residue1);
CREATE INDEX ixResidue2 ON Contact (residue2);

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------TABLES UNDER DEVELOPMENT OR REFINEMENT-------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

CREATE TABLE TTPRMotifAlignment
(	ttprMotifId		INT				SERIAL DEFAULT VALUE,
	ttprId			INT				NOT NULL,
	motifNo			INT				NOT NULL,
	residueNo		INT				NOT NULL,
	PRIMARY KEY (ttprMotifId),
	FOREIGN KEY (ttprId) REFERENCES TentativeTPR(ttprId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE	
);
CREATE INDEX ixttprId ON TTPRMotifAlignment (ttprId);
CREATE INDEX ixmotifNo ON TTPRMotifAlignment (motifNo);
CREATE INDEX ixresidueNo ON TTPRMotifAlignment (residueNo);

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------OBSOLETE TABLES------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

/* 
CREATE TABLE PWSimilarity
(	pwId				INT				SERIAL DEFAULT VALUE,
	tentativeTPR1		INT				,
	pdb1				CHAR(4)			,
	chain1				CHAR(1)			,
	start1				INT				,
	end1				INT				,
	tentativeTPR2		INT				,
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
	FOREIGN KEY (tentativeTPR1) REFERENCES ObsoleteTentativeTPR(tentativeTPRId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (tentativeTPR2) REFERENCES ObsoleteTentativeTPR(tentativeTPRId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (pdb1) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (pdb2) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE
);

CREATE INDEX ixPdb1 ON PWSimilarity (pdb1);
CREATE INDEX ixPdb2 ON PWSimilarity (pdb2);
CREATE INDEX ixtentativeTPR1 ON PWSimilarity (tentativeTPR1);
CREATE INDEX ixtentativeTPR2 ON PWSimilarity (ixtentativeTPR2);


CREATE TABLE TentativeTPR
(	tentativeTPRId		INT				SERIAL DEFAULT VALUE,
	pdbCode				CHAR(4)			,
	chain				VARCHAR(5)		,
	start				FLOAT			,
	end					FLOAT			,
	count				INT				,
	PRIMARY KEY (tentativeTPRId),
	FOREIGN KEY (pdbCode) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE
);

CREATE INDEX ixTentativeTPRId ON TentativeTPR (tentativeTPRId);
CREATE INDEX ixPdbTTPR ON TentativeTPR (pdbCode);

CREATE TABLE SearchHit
(	matchId				INT				SERIAL DEFAULT VALUE,
	tentativeTPRId		INT				,
	experimentId		INT				,
	pdbCode				CHAR(4)			,
	chain				VARCHAR(5)		,
	start				FLOAT			,
	end					FLOAT			,
	PRIMARY KEY (matchId),
	FOREIGN KEY (tentativeTPRId) REFERENCES TentativeTPR(tentativeTPRId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,	
	FOREIGN KEY (pdbCode) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (experimentId) REFERENCES Experiment(experimentId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE
); */

/* CREATE INDEX ixMatchId ON SearchHit (matchId);
CREATE INDEX ixTentativeTPRIdSH ON SearchHit (tentativeTPRId);
CREATE INDEX ixPdbSH ON SearchHit (pdbCode); */