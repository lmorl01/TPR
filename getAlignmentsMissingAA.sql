-- Select Alignments that are missing amino acids
-- Fields are those required for getAminoAcids.pl

SELECT 
A.alignId, E.queryPdb, TPRR.chain, A.queryResidueNo, R.resultPdb, R.chain, A.resultResidueNo
FROM
Alignment A, Results R, Experiment E, TPRRegion TPRR
WHERE
A.resultId = R.resultId and R.experimentId = E.experimentId and E.regionId = TPRR.regionId
AND
(A.queryResidue IS NULL OR A.resultResidue IS NULL)
INTO 
OUTFILE '/d/user6/md003/Project/db/sqlout/aaAll.csv' fields terminated by ',' lines terminated by '\n';