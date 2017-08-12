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