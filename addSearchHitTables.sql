-- David Morley, MSc Bioinformatics 2015-2017
-- MSc Project: Origin & Evolution of TPR Domains
-- Version: addSearchHitTables.sql, 04/06/2017
-- Purpose: Update the Database Schema to add the following tables:
--
-- SearchHit
--#
--# +-------------------+-------------+------+-----+---------+----------------+
--# | Field             | Type        | Null | Key | Default | Extra          |
--# +-------------------+-------------+------+-----+---------+----------------+
--# | matchId           | int(11)     | NO   | PRI | NULL    | auto_increment |
--# | tentativeTPRId    | int(11)     | YES  | MUL | NULL    |                |
--# | experimentId      | int(11)     | YES  | MUL | NULL    |                |
--# | pdbCode           | char(4)     | YES  | MUL | NULL    |                |
--# | chain             | varchar(5)  | YES  |     | NULL    |                |
--# | start             | int         | YES  |     | NULL    |                |
--# | end               | int         | YES  |     | NULL    |                |
--# +-------------------+-------------+------+-----+---------+----------------+
--#
--# TentativeTPR
--#
--# +-------------------+-------------+------+-----+---------+----------------+
--# | Field             | Type        | Null | Key | Default | Extra          |
--# +-------------------+-------------+------+-----+---------+----------------+
--# | tentativeTPRId    | int(11)     | NO   | PRI | NULL    | auto_increment |
--# | pdbCode           | char(4)     | YES  | MUL | NULL    |                |
--# | chain             | varchar(5)  | YES  |     | NULL    |                |
--# | start             | float       | YES  |     | NULL    |                |
--# | end               | float       | YES  |     | NULL    |                |
--# | count             | int         | YES  |     | NULL    |                |
--# +-------------------+-------------+------+-----+---------+----------------+

DROP TABLE IF EXISTS SearchHit;
DROP TABLE IF EXISTS TentativeTPR;

CREATE TABLE TentativeTPR
(	tentativeTPRId		INT				SERIAL DEFAULT VALUE,
	pdbCode				CHAR(4)			,
	chain				VARCHAR(5)		,
	start				FLOAT			,
	end					FLOAT			,
	count				INT				,
	PRIMARY KEY (tentativeTPRId),
	FOREIGN KEY (pdbCode) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE
);

CREATE INDEX ixTentativeTPRId ON TentativeTPR (tentativeTPRId);
CREATE INDEX ixPdbTTPR ON TentativeTPR (pdbCode);

CREATE TABLE SearchHit
(	matchId				INT				SERIAL DEFAULT VALUE,
	tentativeTPRId		INT				,
	experimentId		INT				,
	pdbCode				CHAR(4)			,
	chain				VARCHAR(5)		,
	start				FLOAT			,
	end					FLOAT			,
	PRIMARY KEY (matchId),
	FOREIGN KEY (tentativeTPRId) REFERENCES TentativeTPR(tentativeTPRId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,	
	FOREIGN KEY (pdbCode) REFERENCES PDBEntry(pdbCode)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE,
	FOREIGN KEY (experimentId) REFERENCES Experiment(experimentId)
		ON DELETE RESTRICT 
		ON UPDATE CASCADE
);

CREATE INDEX ixMatchId ON SearchHit (matchId);
CREATE INDEX ixTentativeTPRIdSH ON SearchHit (tentativeTPRId);
CREATE INDEX ixPdbSH ON SearchHit (pdbCode);