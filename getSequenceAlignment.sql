SELECT -- COUNT(*)
TTPR.ttprId, TTPR.pdbCode, TTPR.chain, TTPR.regionOrdinal, TTPR.tprOrdinal, TTPR.startMode, TTPR.endMode, S.residueNo, S.residue, M.motifNo
FROM
TentativeTPR TTPR, Sequence S, TTPRMotifAlignment M
WHERE
TTPR.pdbCode = S.pdbCode and TTPR.chain = S.chain
AND
M.ttprId = TTPR.ttprId and M.residueNo = S.residueNo
AND
TTPR.startMode <= S.residueNo and S.residueNo <= TTPR.endMode
AND
-- (TTPR.pdbCode = '1a17' OR TTPR.pdbCode = '1elw') AND
TTPR.ttprParamId = 2
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/alignment.csv' fields terminated by ',' lines terminated by '\n';
-- LIMIT 30;


