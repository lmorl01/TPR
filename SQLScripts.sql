
-- Insertion statement for TPRRegions

INSERT INTO TPRRegion (pdbCode, chain, regionOrdinal, shEndResidue, tprCount) VALUES ("1a17", "A", 1, 164, 3);

-- Insertion statement for TPRs

INSERT INTO TPR (regionId, startResidue, endResidue, tprOrdinal) VALUES (1, 1, 22, 57, 1);

-- Insertion statement for Experiments

INSERT INTO Experiment (parameterId, experimentDate, queryPdb, regionId, flexible, pdbDatabase, resultsLocation, cmdLineOutput) 
VALUES (13, "2017-01-31" , "1ihg", 7, 1, "workingPDB", "1ihg/1ihg_TPR_1-3", "1ihg/1ihg_TPR_1-3/1ihg_TPR_1-3.out");

-- Select significant results for results with one block
-- Fields are those required for addAlignments.pl

SELECT R.resultId, R.resultPdbText, E.resultsLocation 
FROM 
Results R, Experiment E 
WHERE 
R.experimentId = E.experimentId
AND
R.norm_rmsd < 0.24 and R.norm_score > 18 and R.probability < 0.004 and R.cov1 > 90 
AND 
R.blocks = 1 
AND 
E.superseded is null 
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/2017-08-02_Sig_1Blk.csv' fields terminated by ',' lines terminated by '\n';

-- Select significant results for results with 1 < blocks <= n where n = number of TPRs in query
-- Fields are those required for addAlignments.pl

SELECT R.resultId, R.resultPdbText, E.resultsLocation
FROM 
Results R, Experiment E, ParameterSet P 
WHERE 
R.experimentId = E.experimentId and E.parameterId = P.parameterId
AND
R.norm_rmsd < 0.24 and R.norm_score > 18 and R.probability < 0.004 and R.cov1 > 90 
AND 
R.blocks > 1 and R.blocks <= (P.endTpr - P.startTpr + 1)
AND 
E.superseded is null 
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/2017-08-02_Sig_1Blk.csv' fields terminated by ',' lines terminated by '\n';

-- Select significant results for results with blocks <= n where n = number of TPRs in query
-- Fields are those required for addAlignments.pl

SELECT R.resultId, R.resultPdbText, E.resultsLocation
FROM 
Results R, Experiment E, ParameterSet P 
WHERE 
R.experimentId = E.experimentId and E.parameterId = P.parameterId
AND
R.norm_rmsd < 0.24 and R.norm_score > 18 and R.probability < 0.004 and R.cov1 > 90 
AND 
R.blocks <= (P.endTpr - P.startTpr + 1)
AND 
E.superseded is null 
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/2017-08-02_Sig_1Blk.csv' fields terminated by ',' lines terminated by '\n';

-- Select Alignments that are missing amino acids
-- Fields are those required for getAminoAcids.pl

SELECT A.alignId, E.queryPdb, TPRR.chain, A.queryResisueNo, R.resultPdb, R.chain, A.resultResidueNo
FROM
Alignment A, Results R, Experiment E, TPRRegion TPRR
WHERE
A.resultId = R.resultId and R.experimentId = E.experimentId and E.regionId = TPRR.regionId
AND
(A.queryResidue IS NULL OR A.resultResidue IS NULL)
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/2017-08-06_aa.csv' fields terminated by ',' lines terminated by '\n';

-- Select TPR start residue numbers for Tentative TPRs based on start residue numbers in the experiment query

SELECT R.resultId, E.queryPdb, R.resultPdb, TPR.TPROrdinal, TPR.startResidue AS 'StartResidueQuery', MIN(A.resultResidueNo) AS 'StartResidueResult'
FROM 
Results R, Experiment E, ParameterSet P, TPR, Alignment A 
WHERE
TPR.regionId = E.regionId and R.experimentId = E.experimentId and A.resultId = R.resultId 
AND 
A.queryResidueNo >= TPR.startResidue
AND 
E.superseded is null and TPR.superseded is null
GROUP BY
R.resultId, E.queryPdb, R.resultPdb, TPR.TPROrdinal, TPR.startResidue
ORDER BY 
E.queryPdb, R.resultPdb, TPR.TPROrdinal;


-- Select TPR end residue numbers for Tentative TPRs based on end residue numbers in the experiment query

SELECT R.resultId, E.queryPdb, R.resultPdb, TPR.TPROrdinal, TPR.endResidue AS 'EndResidueQuery', MAX(A.resultResidueNo) AS 'EndResidueResult'
FROM 
Results R, Experiment E, ParameterSet P, TPR, Alignment A 
WHERE
TPR.regionId = E.regionId and R.experimentId = E.experimentId and A.resultId = R.resultId 
AND 
A.queryResidueNo <= TPR.endResidue
AND 
E.superseded is null and TPR.superseded is null
GROUP BY
R.resultId, E.queryPdb, R.resultPdb, TPR.TPROrdinal, TPR.endResidue
ORDER BY 
E.queryPdb, R.resultPdb, TPR.TPROrdinal;

-- Select start and end TPR residue numbers for Tentative TPRs based on start and end residue numbers in the experiment query
-- Fields are those required for extractTPRs.pl

SELECT R.resultId, E.queryPdb, TPRR.chain AS 'QueryChain', R.resultPdb, R.chain AS 'ResultChain', TPR.TPROrdinal, TPR.startResidue AS 'StartResidueQuery', TPR.endResidue AS 'EndResidueQuery', MIN(A.resultResidueNo) AS 'StartResidueResult', MAX(A.resultResidueNo) AS 'EndResidueResult'
FROM 
Results R, Experiment E, ParameterSet P, TPRRegion TPRR, TPR, Alignment A 
WHERE
TPR.regionId = TPRR.RegionId and TPRR.RegionId = E.regionId and R.experimentId = E.experimentId and A.resultId = R.resultId 
AND 
A.queryResidueNo >= TPR.startResidue and A.queryResidueNo <= TPR.endResidue
AND 
E.superseded is null and TPR.superseded is null
GROUP BY
R.resultId, E.queryPdb, TPRR.chain, R.resultPdb, R.chain, TPR.TPROrdinal, TPR.startResidue, TPR.endResidue
ORDER BY 
E.queryPdb, R.resultPdb, TPR.TPROrdinal;



