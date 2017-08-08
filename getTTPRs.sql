-- Select start and end TPR residue numbers for Tentative TPRs based on start and end residue numbers in the experiment query
-- Fields are those required for extractTPRs.pl
-- Limit to results with only one block

SELECT 
R.resultId, E.queryPdb, TPRR.chain AS 'QueryChain', R.resultPdb, R.chain AS 'ResultChain', TPR.TPROrdinal, TPR.startResidue AS 'StartResidueQuery', TPR.endResidue AS 'EndResidueQuery', MIN(A.resultResidueNo) AS 'StartResidueResult', MAX(A.resultResidueNo) AS 'EndResidueResult'
FROM 
Results R, Experiment E, TPRRegion TPRR, TPR, Alignment A 
WHERE
TPR.regionId = TPRR.RegionId and TPRR.RegionId = E.regionId and R.experimentId = E.experimentId and A.resultId = R.resultId 
AND 
-- We look for the query residues that feature in an alignment and are closest to the TPR boundaries, but not outside them
A.queryResidueNo >= TPR.startResidue and A.queryResidueNo <= TPR.endResidue
AND 
R.norm_rmsd < 0.24 and R.norm_score > 18 and R.probability < 0.004 and R.cov1 > 90 and R.blocks = 1 
AND
E.superseded is null and TPR.superseded is null
GROUP BY
R.resultId, E.queryPdb, TPRR.chain, R.resultPdb, R.chain, TPR.TPROrdinal, TPR.startResidue, TPR.endResidue
ORDER BY 
E.queryPdb, R.resultPdb, TPRR.regionOrdinal, TPR.tprOrdinal
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/2017-08-08_ttprs_1Blk.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n';