
CREATE TABLE Sequence
(	pdbCode			CHAR(4)			NOT NULL,
	chain			CHAR(5)			NOT NULL,
	residueNo		INT				NOT NULL,
	residue			CHAR(1)			NOT NULL,
	PRIMARY KEY (pdbCode,chain,residueNo)
	FOREIGN KEY (pdbCode) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE	
);
CREATE INDEX ixChain ON Sequence (chain);
CREATE INDEX ixResidueNo ON Sequence (residueNo);