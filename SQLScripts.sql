
-- SQL to select TPR start residue numbers 

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


-- SQL to select TPR end residue numbers

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