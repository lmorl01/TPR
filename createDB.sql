
-- David Morley, MSc Bioinformatics 2015-2017
-- MSc Project: Origin & Evolution of TPR Domains
-- Version: 003, 01/06/2017
-- Version History:
-- 001: Initial Version creates tables PDBEntry, TPRRegion, TPR, Experiment, Result
-- 002: Amendments to tables Experiment & Result and addition of table ParameterSet
-- 003: Addition of creation statement for table PWSimilarity

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
	PRIMARY KEY (tprId),
	FOREIGN KEY (regionId) REFERENCES TPRRegion (regionId) 
		ON DELETE RESTRICT 
		ON UPDATE CASCADE
);

CREATE INDEX ixregionId ON TPR(regionId);

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
	FOREIGN KEY (startTPRId) REFERENCES TPR(tprId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,	
	FOREIGN KEY (endTprId) REFERENCES TPR(tprID)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE	
);

CREATE INDEX ixQueryPdb ON Experiment (queryPdb);
CREATE INDEX ixRegionId ON Experiment (regionId);
CREATE INDEX ixParameterId ON Experiment (parameterId);

CREATE TABLE Results
(	resultId			INT				SERIAL DEFAULT VALUE,
	experimentId		INT				,
	resultPdb			CHAR(4)			,
	resultPdbText		VARCHAR(50)		,
	score				FLOAT			,
	probability			FLOAT			,
	rmsd				FLOAT			,
	len1				INT				,
	len2				INT				,
	cov1				INT				,
	cov2				INT				,
	percentId			FLOAT			,
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
		ON UPDATE CASCADE,
);

CREATE INDEX ixPwId ON PWSimilarity (pwId);
CREATE INDEX ixPdb1 ON PWSimilarity (pdb1);
CREATE INDEX ixPdb2 ON PWSimilarity (pdb2);

