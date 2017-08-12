
-- Extract alignment of Tentative TPRs against the TPR motif for all search results
-- From this data, a consensus alignment of Tentative TPRs against the TPR motif can be calculated

-- Example output: 710,1a17,A,1,1,28,61,29,2,2xpi,1,9,11
-- The above line can be interpreted as "Tentative TPR number 710 is in PDB 1a17, chain A,
-- region ordinal 1, TPR ordinal 1 and it runs from residue 28 to 61. Residue 29 within this tentative TPR has
-- been mapped to TPR motif ordinal number 2 (the second position in the TPR motif) by the results returned
-- from searching with query structure PDB 2xpi, region 1, tripartite TPR 9-11"

SELECT 
-- Tentative TPR Details
TTPR.ttprId, TTPR.pdbCode, TTPR.chain, TTPR.regionOrdinal, TTPR.tprOrdinal, TTPR.startMode, TTPR.endMode, 
-- Residue mapping to TPR Motif
A.resultResidueNo, 
M.motifNo,
-- TPR Query Details
E.queryPdb,
TPRR.regionOrdinal,
P.startTpr, P.endTpr
FROM 
TentativeTPR TTPR, Results R, Alignment A, Experiment E, TPRRegion TPRR, TPR, ParameterSet P, TPRMotifAlignment M
WHERE
TTPR.pdbCode = R.resultPdb and TTPR.chain = R.chain and 
R.resultId = A.resultId and R.experimentId = E.experimentId and E.parameterId = P.parameterId and
E.regionId = TPRR.regionId and TPRR.regionId = TPR.regionId and 
A.queryResidueNo = M.residueNo and TPR.tprId = M.tprId
AND
A.resultResidueNo >= TTPR.startMode and A.resultResidueNo <= TTPR.endMode
AND
E.superseded IS NULL AND TTPR.ttprParamId = 2
ORDER BY TTPR.pdbCode, TTPR.chain, TTPR.regionOrdinal, TTPR.tprOrdinal, A.resultResidueNo, M.motifNo
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/ttprMotifData.csv' fields terminated by ',' lines terminated by '\n';
