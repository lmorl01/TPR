-- In development: Data needed to determine consensus TTPR Motif Alignment:

SELECT 
TTPR.ttprId, TTPR.pdbCode, TTPR.chain, TTPR.regionOrdinal, TTPR.tprOrdinal, TTPR.startMode, TTPR.endMode, 
A.resultResidueNo, 
E.queryPdb,
TPRR.regionOrdinal
FROM 
TentativeTPR TTPR, Results R, Alignment A, Experiment E, TPRRegion TPRR
WHERE
TTPR.pdbCode = R.resultPdb and TTPR.chain = R.chain and R.resultId = A.resultId and R.experimentId = E.experimentId and
E.regionId = TPRR.regionId
AND
A.resultResidueNo >= TTPR.startMode and A.resultResidueNo <= TTPR.endMode
AND
E.superseded IS NULL AND TTPR.ttprParamId = 2
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/ttprMotifData.csv' fields terminated by ',' lines terminated by '\n';