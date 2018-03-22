#!/bin/Rscript

library(ballgown)
## bg = ballgown(dataDir = "../output-slurm/Step13_stringtie_abundances/", samplePattern = "LIB", bamfiles = NULL, verbose = TRUE, meas = "all")
bg = ballgown(dataDir = "ballgown", samplePattern = "LIB", bamfiles = NULL, verbose = TRUE, meas = "all")

#ballgown instance with 260298 transcripts and 98 samples
sampleNames(bg)
#save the ballgown object for future quicker loading
save(bg, file='ballgown/bg_HomoSapiens_GRChr38.89_noPD.rda')

