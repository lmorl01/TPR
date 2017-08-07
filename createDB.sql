
-------------------------------------------------------------------------------------------------
-- David Morley, MSc Bioinformatics 2015-2017
-- MSc Project: Origin & Evolution of TPR Domains
-- Version: 005, 07/08/2017
-- Version History:
-- 001: Initial Version creates tables PDBEntry, TPRRegion, TPR, Experiment, Result
-- 002: Amendments to tables Experiment & Result and addition of table ParameterSet
-- 003: Addition of creation statement for table PWSimilarity
-- 004: Addition of creation statement for TentativeTPR and SearchHit tables
-- 005: Updated to reflect latest status of the DB. TentativeTPR and SearchHit tables were made
-- 		obsolete. New TentativeTPR table created. 'superseded' fields added to a number of tables
--		Alignment table added including indexes on queryResidueNo and resultResidueNo. INDEXES
--		added on TPR.startResidue, TPR.endResidue
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

CREATE TABLE TentativeTPR
(	ttprId 			INT				SERIAL DEFAULT VALUE,
	pdbCode			CHAR(4)			,
	chain			CHAR(5)			,
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
		ON UPDATE CASCADE
);

CREATE INDEX ixttprPdbCode ON TentativeTPR(pdbCode);

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

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------TABLES UNDER DEVELOPMENT OR REFINEMENT-------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
----------------------------------------OBSOLETE TABLES------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

/* CREATE TABLE TentativeTPR
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