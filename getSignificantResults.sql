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