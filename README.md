# RNAseq_analysis
RNA-seq data analysis for the ESCAPE data, following protocol presented in [1].

A paper including this analysis has been submitted for review.

## Overview:

    * Pre-processing of RNA-seq data
        - Removal of rRNA reads
        - Removal of adaptor sequences
        - Removal of low quality reads

    * Alignment of reads to the reference genome

    * Assembly of the alingments into full-length transcripts
    
    * Quantification of the expression levels
    
    * Calculate differential expression
    
    * Gene Set Enrichment Analysis (not included here)


## Requirements:
SortMeRNA, v.2.1b [2]  
cutadapt  
FastQC  
TrimGalore!, v.0.4.2  [3]  
HISAT2, v.2.0.5 [1]  
StringTie, v.1.3.3 [1]  
Samtools, v.1.4  
GFFcompare, v.0.9.8  
BallGown [1]  


## Data
RNA sequencing data will be available from ArrayExpress soon. 
Please contact Perla (dot) TroncosoRey (at) quadram (dot) ac (dot) uk to get a subset of the data for testing the pipeline. 


## Contact
For queries contact Perla (dot) TroncosoRey (at) quadram (dot) ac (dot) uk

## References
[1] Pertea M., Kim D., Pertea G.M., Leek J.T., Salzberg S.L., Transcript-level expression analysis of RNA-seq experiments with HISAT, StringTie and Ballgown, Nature Protocols, 2016.  
[2] Kopylova E., Noé L. and Touzet H., "SortMeRNA: Fast and accurate filtering of ribosomal RNAs in metatranscriptomic data", Bioinformatics (2012), doi: 10.1093/bioinformatics/bts611.  
[3] TrimGalore!, Felix Krueger, The Babraham Institute, http://www.bioinformatics.babraham.ac.uk/projects/trim_galore/  

