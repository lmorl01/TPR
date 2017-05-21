
pw <- read.table("1a17_TPR_1-3_alignPairs.out", header=TRUE, check.names =FALSE);
rownames(pw) <- colnames(pw);
dist <- as.dist(pw, diag=FALSE, upper=FALSE);
hc <- hclust(dist);
plot(hc);