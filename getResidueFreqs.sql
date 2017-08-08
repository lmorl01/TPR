
-- Select residue alignment frequency data for query PDBs, cancatenating PDB Code, Chain and TPR Region
-- Single block results
-- Fields are those required for residue alignment frequency analysis

SELECT 
CONCAT(queryPdb, TPRR.chain, '_', TPRR.regionOrdinal) AS 'PDBChainRegion', A.queryResidueNo, COUNT(*) 
FROM
Alignment A, Results R, Experiment E, TPRRegion TPRR 
WHERE 
A.resultId = R.resultId and R.experimentId = E.experimentId and E.regionId = TPRR.regionId
AND
R.norm_rmsd < 0.24 and R.norm_score > 18 and R.probability < 0.004 and R.cov1 > 90 and R.blocks = 1 
AND
E.superseded IS NULL and TPRR.superseded IS NULL
GROUP BY 
'PDBChainRegion', queryPdb, TPRR.chain, TPRR.regionOrdinal, A.queryResidueNo
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/resFreq_1Blk.csv' fields terminated by ',' lines terminated by '\n';

-- Select TPR Boundaries
-- Fields are those required for residue alignment frequency analysis

SELECT 
CONCAT(TPRR.pdbCode, TPRR.chain, '_', TPRR.regionOrdinal) AS 'PDBChainRegion', TPR.startResidue, TPR.endResidue 
FROM
TPRRegion TPRR, TPR 
WHERE 
TPRR.regionId = TPR.regionId
AND
TPRR.superseded IS NULL and TPR.superseded IS NULL
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/tprBoundaries.csv' fields terminated by ',' lines terminated by '\n';