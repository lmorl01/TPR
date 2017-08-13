-- Extract contact data for TTPRs to perform contact analysis

SELECT
C.pdbCode, C.chain, C.residue1, C.residue2, S1.residue, S2.residue, M1.motifNo, M2.motifNo
FROM
Contact C, Sequence S1, Sequence S2, TTPRMotifAlignment M1, TTPRMotifAlignment M2
WHERE 
C.pdbCode = S1.pdbCode and C.chain = S1.chain and C.pdbCode = S2.pdbCode and C.chain = S2.chain and 
C.residue1 = S1.residueNo and C.residue2 = S2.residueNo and
C.residue1 = M1.residueNo and C.residue2 = M2.residueNo
INTO OUTFILE '/d/user6/md003/Project/db/sqlout/contacts.csv' fields terminated by ',' lines terminated by '\n';