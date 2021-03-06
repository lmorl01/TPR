
-- Select residue alignment frequency data for query PDBs, cancatenating PDB Code, Chain and TPR Region
-- Single block results
-- Fields are those required for residue alignment frequency analysis

SELECT 
CONCAT(E.queryPdb, TPRR.chain, '_', TPRR.regionOrdinal, "_TPR_", P.startTpr, "-", P.endTpr) AS 'PDBChainRegionTPRs', A.queryResidueNo, COUNT(*)
FROM
Alignment A, Results R, Experiment E, TPRRegion TPRR, ParameterSet P 
WHERE 
A.resultId = R.resultId and R.experimentId = E.experimentId and E.regionId = TPRR.regionId and E.parameterId = P.parameterId
AND
R.norm_rmsd < 0.24 and R.norm_score > 18 and R.probability < 0.004 and R.cov1 > 90 and R.blocks = 1 
AND
P.endTpr - P.startTpr = 2	-- This will limit it to results using 3 TPRs
AND
E.superseded IS NULL and TPRR.superseded IS NULL
GROUP BY 
E.queryPdb, E.parameterId, TPRR.chain, TPRR.regionOrdinal, A.queryResidueNo
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/resFreq_1Blk5.csv' fields terminated by ',' lines terminated by '\n';

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