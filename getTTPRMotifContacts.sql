-- Extract contact data for TTPRs to perform contact analysis

SELECT -- COUNT(*)
TTPR.pdbCode, TTPR.tprOrdinal, TTPR.startMode, TTPR.endMode,
C.residue1, C.residue2, C.helix1, C.helix2, S1.residue, S2.residue,
M1.motifNo, M2.motifNo, TTPR1.tprOrdinal, TTPR2.tprOrdinal
FROM
TentativeTPR TTPR, Contact C, Sequence S1, Sequence S2, 
TTPRMotifAlignment M1, TentativeTPR TTPR1,
TTPRMotifAlignment M2, TentativeTPR TTPR2
WHERE 
TTPR.pdbCode = C.pdbCode and TTPR.chain = C.chain and
C.residue1 = S1.residueNo and TTPR.pdbCode = S1.pdbCode and TTPR.chain = S1.chain and
C.residue2 = S2.residueNo and TTPR.pdbCode = S2.pdbCode and TTPR.chain = S2.chain

-- Limit to contacts where at least one is in the TPR
AND
((TTPR.startMode <= C.residue1 and C.residue1 <= TTPR.endMode) OR (TTPR.startMode <= C.residue2 and C.residue2 <= TTPR.endMode))

-- Join the first residue to the motif via the appropriate TTPR
AND
TTPR1.pdbCode = C.pdbCode and TTPR1.chain = C.chain
AND 
M1.ttprId = TTPR1.ttprId and M1.residueNo = C.residue1

-- Join the second residue to the motif via the appropriate TTPR
AND
TTPR2.pdbCode = C.pdbCode and TTPR2.chain = C.chain
AND
M2.ttprId = TTPR2.ttprId and M2.residueNo = C.residue2

AND
-- TTPR.pdbCode = '1a17' and 
(M1.motifNo = 24 OR M2.motifNo = 24) and
TTPR.ttprParamId = 2
-- GROUP BY TTPR.tprOrdinal
ORDER BY TTPR.pdbCode, TTPR.tprOrdinal
LIMIT 30
-- INTO OUTFILE '/d/user6/md003/Project/db/sqlout/contacts.csv' fields terminated by ',' lines terminated by '\n';
