CREATE TABLE TTPRMotifAlignment
(	ttprMotifId		INT				SERIAL DEFAULT VALUE,
	ttprId			INT				NOT NULL,
	motifNo			INT				NOT NULL,
	residueNo		INT				NOT NULL,
	PRIMARY KEY (tprMotifId),
	FOREIGN KEY (ttprId) REFERENCES TentativeTPR(ttprId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE	
);
CREATE INDEX ixttprId ON TPRMotifAlignment (ttprId);
CREATE INDEX ixmotifNo ON TPRMotifAlignment (motifNo);
CREATE INDEX ixresidueNo ON TPRMotifAlignment (residueNo);