
-- In development: Data needed to determine consensus TTPR Motif Alignment:

SELECT 
TTPR.ttprId, TTPR.pdbCode, TTPR.chain, TTPR.regionOrdinal, TTPR.tprOrdinal, TTPR.startMode, TTPR.endMode, A.resultResidueNo
FROM 
TentativeTPR TTPR, Results R, Alignment A
WHERE
TTPR.pdbCode = R.pdbCode AND TTPR.chain = R.chain AND R.resultId = A.resultId
AND
TTPR.ttprParamId = 2;