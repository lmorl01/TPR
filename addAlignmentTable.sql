
-- David Morley, MSc Bioinformatics 2015-2017
-- MSc Project: Origin & Evolution of TPR Domains
-- Version: 001, 05/08/17
-- Version History:

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

