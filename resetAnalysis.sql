
DROP TABLE TentativeTPR;
DROP TABLE Alignment;

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