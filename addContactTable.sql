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