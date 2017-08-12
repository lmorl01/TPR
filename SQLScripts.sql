
-- Log command line messages to a log

tee /d/user6/md003/Project/db/sqlout/console.out

-- Insertion statement for TPRRegions

INSERT INTO TPRRegion (pdbCode, chain, regionOrdinal, shEndResidue, tprCount) VALUES ("1a17", "A", 1, 164, 3);

-- Insertion statement for TPRs

INSERT INTO TPR (regionId, startResidue, endResidue, tprOrdinal) VALUES (1, 1, 22, 57, 1);

-- Insertion statement for Experiments

INSERT INTO Experiment (parameterId, experimentDate, queryPdb, regionId, flexible, pdbDatabase, resultsLocation, cmdLineOutput) 
VALUES (13, "2017-01-31" , "1ihg", 7, 1, "workingPDB", "1ihg/1ihg_TPR_1-3", "1ihg/1ihg_TPR_1-3/1ihg_TPR_1-3.out");

--Insertion statement for TTPRParameters

INSERT INTO TTPRParameters (norm_rmsd, norm_score, probability, cov1, blocks, tprTolerance, regionTolerance, analysisDate, inputFile)
VALUES (0.24, 18, 0.004, 90, "1", 21, 34, "2017-08-08", "ttprs/2017-08-08/2017-08-08_ttprs_1Blk.csv");

-- Select significant results for results with one block
-- Fields are those required for addAlignments.pl

SELECT 
R.resultId, R.resultPdbText, E.resultsLocation 
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

SELECT 
R.resultId, R.resultPdbText, E.resultsLocation
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

SELECT 
R.resultId, R.resultPdbText, E.resultsLocation
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
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/sig_results.csv' fields terminated by ',' lines terminated by '\n';

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

-- Select TPR start residue numbers for Tentative TPRs based on start residue numbers in the experiment query

SELECT 
R.resultId, E.queryPdb, R.resultPdb, TPR.TPROrdinal, TPR.startResidue AS 'StartResidueQuery', MIN(A.resultResidueNo) AS 'StartResidueResult'
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

SELECT 
R.resultId, E.queryPdb, R.resultPdb, TPR.TPROrdinal, TPR.endResidue AS 'EndResidueQuery', MAX(A.resultResidueNo) AS 'EndResidueResult'
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
R.norm_rmsd < 0.24 and R.norm_score > 18 and R.probability < 0.004 and R.cov1 > 90
AND 
E.superseded is null and TPR.superseded is null
GROUP BY
R.resultId, E.queryPdb, TPRR.chain, R.resultPdb, R.chain, TPR.TPROrdinal, TPR.startResidue, TPR.endResidue
ORDER BY 
E.queryPdb, R.resultPdb, TPRR.regionOrdinal, TPR.tprOrdinal;

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

-- Select start and end TPR residue numbers for Tentative TPRs based on start and end residue numbers in the experiment query
-- Fields are those required for extractTPRs.pl
-- Limit to results with 1 to n blocks for n <= no of blocks in query

SELECT 
R.resultId, E.queryPdb, TPRR.chain AS 'QueryChain', R.resultPdb, R.chain AS 'ResultChain', TPR.TPROrdinal, TPR.startResidue AS 'StartResidueQuery', TPR.endResidue AS 'EndResidueQuery', MIN(A.resultResidueNo) AS 'StartResidueResult', MAX(A.resultResidueNo) AS 'EndResidueResult'
FROM 
Results R, Experiment E, TPRRegion TPRR, TPR, Alignment A, ParameterSet P 
WHERE
TPR.regionId = TPRR.RegionId and TPRR.RegionId = E.regionId and R.experimentId = E.experimentId and A.resultId = R.resultId and E.parameterId = P.parameterId
AND 
-- We look for the query residue that feature in an alignment and are closest to the TPR boundaries, but not outside them
A.queryResidueNo >= TPR.startResidue and A.queryResidueNo <= TPR.endResidue
AND 
-- (P.endTpr - T.startTpr + 1) is the number of TPRs that featured in the query structure
R.norm_rmsd < 0.24 and R.norm_score > 18 and R.probability < 0.004 and R.cov1 > 90 and R.blocks <= (P.endTpr - T.startTpr + 1) 	
AND
E.superseded is null and TPR.superseded is null
GROUP BY
R.resultId, E.queryPdb, TPRR.chain, R.resultPdb, R.chain, TPR.TPROrdinal, TPR.startResidue, TPR.endResidue
ORDER BY 
E.queryPdb, R.resultPdb, TPRR.regionOrdinal, TPR.tprOrdinal
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/2017-08-08_ttprs_nBlk.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n';

-- Select residue alignment frequency data for query PDBs
-- Fields are those required for residue alignment frequency analysis

SELECT 
E.queryPdb, TPRR.chain, TPRR.regionOrdinal, A.queryResidueNo, COUNT(*) 
FROM
Results R, Alignment A, Experiment E, TPRRegion TPRR 
WHERE 
R.resultId = A.resultId and R.experimentId = E.experimentId and E.regionId = TPRR.regionId
AND
E.superseded is null and TPR.superseded is null
GROUP BY 
E.queryPdb, TPRR.chain, TPRR.regionId, A.queryResidueNo;
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/residueFrequencies.csv' fields terminated by ',' lines terminated by '\n';

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

-- Select residue alignment frequency data for query PDBs, cancatenating PDB Code, Chain and TPR Region
-- Multi block results
-- Fields are those required for residue alignment frequency analysis

SELECT 
CONCAT(queryPdb, TPRR.chain, '_', TPRR.regionOrdinal) AS 'PDBChainRegion', A.queryResidueNo, COUNT(*) 
FROM
Results R, Alignment A, Experiment E, TPRRegion TPRR, ParameterSet P 
WHERE 
R.resultId = A.resultId and R.experimentId = E.experimentId and E.regionId = TPRR.regionId and E.parameterId = P.parameterId
AND
R.norm_rmsd < 0.24 and R.norm_score > 18 and R.probability < 0.004 and R.cov1 > 90 and R.blocks = 1 and R.blocks <= (P.endTpr - T.startTpr + 1) 
AND
E.superseded IS NULL and TPRR.superseded IS NULL
GROUP BY 
'PDBChainRegion', A.queryResidueNo
ORDER BY
'PDBChainRegion', A.queryResidueNo
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/residueFrequencies.csv' fields terminated by ',' lines terminated by '\n';

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

-- Select Tentative TPRs
-- Fields are those required for pairwise analysis

SELECT
ttprId, pdbCode, chain, regionOrdinal, tprOrdinal, startMode, endMode
FROM
TentativeTPR
WHERE
ttprParamId = 1
ORDER BY pdbCode, chain, regionOrdinal, tprOrdinal
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/ttprs.csv' fields terminated by ',' lines terminated by '\n';

-- Select PDB Codes from TentativeTPR

SELECT 
DISTINCT(pdbCode)
FROM
TentativeTPR
WHERE pdbCode 
NOT IN (SELECT DISTINCT pdbCode FROM Sequence)
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/ttprPDBs.csv' lines terminated by '\n';

-- Extract the motif alignment for a given Core TPR

SELECT TPRR.pdbCode, TPR.tprOrdinal, M.residueNo, M.motifNo, S.residue 
FROM
TPRRegion TPRR, TPR, TPRMotifAlignment M, Sequence S 
WHERE 
M.tprId = TPR.tprId and TPR.regionId = TPRR.regionId and TPRR.pdbCode = S.pdbCode and M.residueNo = S.residueNo;

-- Extract the residues from Core TPRs aligned against a particular motif residue

SELECT TPRR.pdbCode, TPR.tprOrdinal, M.residueNo, M.motifNo, S.residue 
FROM 
TPRRegion TPRR, TPR, TPRMotifAlignment M, Sequence S 
WHERE 
M.tprId = TPR.tprId and TPR.regionId = TPRR.regionId and TPRR.pdbCode = S.pdbCode and M.residueNo = S.residueNo 
AND 
M.motifNo = 20;

-- Extract relative frequencies among the Core Set for a given motif residue

SELECT S.residue, count(*) 
FROM 
TPRRegion TPRR, TPR, TPRMotifAlignment M, Sequence S 
WHERE 
M.tprId = TPR.tprId and TPR.regionId = TPRR.regionId and TPRR.pdbCode = S.pdbCode and M.residueNo = S.residueNo 
AND 
M.motifNo = 20 
GROUP BY S.residue;

-- In development

SELECT 
M.motifNo, E.queryPdb, R.resultPdb, S.residueNo, S.residue 
FROM
TPRMotifAlignment M, TPR, TPRRegion TPRR, Alignment A
WHERE
M.tprId = TPR.tprId and TPR.regionId = TPRR.regionId and TPRR.regionId = E.regionId and E.experimentId = R.experimentId 
and R.resultPdb = S.pdbCode and M.residueNo = A.queryResidueNo
AND
R.resultPdb = '1a17';

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








