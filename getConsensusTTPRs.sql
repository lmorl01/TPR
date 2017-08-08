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