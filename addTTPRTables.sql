
-- Create tables TTPRParameters and TentativeTPR

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
		ON UPDATE CASCADE
	FOREIGN KEY (ttprParamId) REFERENCES TTPRParameters (ttprParamId) 
		ON DELETE RESTRICT 
		ON UPDATE CASCADE	
);

CREATE INDEX ixttprPdbCode ON TentativeTPR(pdbCode);
CREATE INDEX ixttprParamId ON TentativeTPR(ttprParamId);