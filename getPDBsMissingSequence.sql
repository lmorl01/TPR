-- Select PDB Codes from TentativeTPR

SELECT 
DISTINCT(pdbCode)
FROM
TentativeTPR
WHERE pdbCode 
NOT IN (SELECT DISTINCT pdbCode FROM Sequence)
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/ttprPDBs.csv' lines terminated by '\n';