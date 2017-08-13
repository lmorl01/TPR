-- Extract relative frequencies among the Core Set for a given motif residue

SELECT M.motifNo, S.residue, count(*) 
FROM 
TentativeTPR TTPR, TTPRMotifAlignment M, Sequence S 
WHERE 
TTPR.ttprId = M.ttprId and TTPR.pdbCode = S.pdbCode and TTPR.chain = S.chain and M.residueNo = S.residueNo
AND 
ttprParamId = 2
GROUP BY M.motifNo, S.residue
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/ttprMotifAlignment.csv' lines terminated by '\n';