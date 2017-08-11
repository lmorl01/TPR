CREATE TABLE Sequence
(	seqId			INT				SERIAL DEFAULT VALUE,
	pdbCode			CHAR(4)			NOT NULL,
	chain			CHAR(5)			,
	residueNo		INT				,
	residue			CHAR(1)			,
	PRIMARY KEY (SeqId),
	FOREIGN KEY (pdbCode) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE	
);

CREATE INDEX ixResidueNo ON Sequence (residueNo);