
-- David Morley, MSc Bioinformatics 2015-2017
-- MSc Project: Origin & Evolution of TPR Domains
-- Version: 001, 05/08/17
-- Version History:

CREATE TABLE TentativeTPRRegion
(	ttprRegionId	INT				SERIAL DEFAULT VALUE,
	pdbCode			CHAR(4)			NOT NULL,
	chain			VARCHAR(5)		NOT NULL,
	start			INT				,
	end				INT				,
	regionOrdinal	INT				,
	tprCount		INT				,
	PRIMARY KEY (ttprRegionId),
	FOREIGN KEY (pdbCode) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT
		ON UPDATE CASCADE
);

CREATE INDEX ixttprRegionId ON TentativeTPRRegion(ttprRegionId);
CREATE INDEX ixpdbCode ON TentativeTPRRegion(pdbCode);

CREATE TABLE TentativeTPR
(	ttprId 			INT				SERIAL DEFAULT VALUE,
	ttprRegionId	INT				NOT NULL,
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
	aaAngle			FLOAT			,
	abAngle			FLOAT			,
	baAngle			FLOAT			,
	tprOrdinal		INT				,
	PRIMARY KEY (ttprId),
	FOREIGN KEY (ttprRegionId) REFERENCES TentativeTPRRegion (ttprRegionId) 
		ON DELETE RESTRICT 
		ON UPDATE CASCADE
);

CREATE INDEX ixttprId ON TentativeTPR(ttprId);
CREATE INDEX ixttprRegionId ON TentativeTPR(ttprRegionId);
