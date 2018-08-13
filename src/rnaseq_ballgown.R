#!/bin/Rscript

library(ballgown)
bg = ballgown(dataDir = "ballgown", samplePattern = "LIB", bamfiles = NULL, verbose = TRUE, meas = "all")

#ballgown instance with 260298 transcripts and 98 samples
sampleNames(bg)
#save the ballgown object
save(bg, file='ballgown/bg_HomoSapiens_GRChr38.89_noPD.rda')

