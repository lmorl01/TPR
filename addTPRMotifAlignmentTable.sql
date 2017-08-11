
CREATE TABLE TPRMotifAlignment
(	tprMotifId		INT				SERIAL DEFAULT VALUE,
	tprId			INT				NOT NULL,
	motifNo			INT				NOT NULL,
	residueNo		INT				NOT NULL,
	PRIMARY KEY (tprMotifId),
	FOREIGN KEY (tprId) REFERENCES TPR(tprId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE	
);
CREATE INDEX ixtprId ON TPRMotifAlignment (tprId);
CREATE INDEX ixmotifNo ON TPRMotifAlignment (motifNo);
CREATE INDEX ixresidueNo ON TPRMotifAlignment (residueNo);