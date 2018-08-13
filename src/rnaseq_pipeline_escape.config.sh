## Configuration file for rnaseq_pipeline.sh
## This file has been modified from: ftp://ftp.ccb.jhu.edu/pub/RNAseq_protocol/rnaseq_pipeline.config.sh
##
## Place this script in a working directory and edit it accordingly.
##
## The default configuration assumes that the user has downloaded the raw 
## data in the rawdata/ directory, for which case set RAW=1.
## Otherwise, if starting with the sample files, FASTQ files are 
## assumed to be in the samples/ directory, for which case set RAW=0.

#how many CPUs to use on the current machine?
NUMCPUS=1

#starting with raw data (RAW=1) or with the concatenated samples (RAW=0)?
RAW=1  ### set to 1 if starting with raw data

#### Program paths ####

## optional BINDIR, using it here because these programs are installed in a common directory
#BINDIR=/usr/local/bin
#HISAT2=$BINDIR/hisat2
#STRINGTIE=$BINDIR/stringtie
#SAMTOOLS=$BINDIR/samtools

#if these programs are not in any PATH directories, please edit accordingly:
HISAT2=$(which hisat2)
STRINGTIE=$(which stringtie)
SAMTOOLS=$(which samtools)
SORTMERNA=$(which sortmerna)
MERGEPAIREDREADS=$(which merge-paired-reads.sh)
UNMERGEPAIREDREADS=$(which unmerge-paired-reads.sh)
TRIMGALORE=$(which trim_galore)
GFFCOMPARE=$(which gffcompare)
RSCRIPT=$(which Rscript)

#### File paths to input data
### Full absolute paths are strongly recommended here.
## Warning: if using relatives paths here, these will be interpreted 
## relative to the  chosen output directory (which is generally the 
## working directory where this script is, unless the optional <output_dir>
## parameter is provided to the main pipeline script)

## Optional base directory, if most of the input files have a common path
BASEDIR=$(pwd -P)

RAWDATA="$BASEDIR/../rawdata"
FASTQLOC="$BASEDIR/../samples"
GENOMEIDX="$BASEDIR/../HISAT2-indexes/homo-sapiens_GRCh38"
GTFFILE="$BASEDIR/../genes/homo-sapiens_GRCh38-89/Homo_sapiens.GRCh38.89.gtf"
DB="$(dirname $SORTMERNA)/../rRNA_databases"
rRNADBs="$DB/rfam-5.8s-database-id98.fasta,$DB/rfam-5.8s-database-id98:$DB/rfam-5s-database-id98.fasta,$DB/rfam-5s-database-id98:$DB/silva-arc-16s-id95.fasta,$DB/silva-arc-16s-id95:$DB/silva-arc-23s-id98.fasta,$DB/silva-arc-23s-id98:$DB/silva-bac-16s-id90.fasta,$DB/silva-bac-16s-id90:$DB/silva-bac-23s-id98.fasta,$DB/silva-bac-23s-id98:$DB/silva-euk-18s-id95.fasta,$DB/silva-euk-18s-id95:$DB/silva-euk-28s-id98.fasta,$DB/silva-euk-28s-id98"

TEMPLOC="./tmp" #this will be relative to the output directory

## list of samples 
## (only paired reads, must follow _R1.*/_R2.* file naming convention)
if [ $RAW -eq 1  ]; then
    reads1=(${RAWDATA}/*_R1.*)
    reads1=("${reads1[@]##*/}")
    reads1=("${reads1[@]#*_}")
    reads1=("${reads1[@]/.fastq.gz/.fastq}")
    reads2=("${reads1[@]/_R1./_R2.}")
else
    reads1=(${FASTQLOC}/*_R1.*)
    reads1=("${reads1[@]##*/}")
    reads1=("${reads1[@]#*_}")
    reads2=("${reads1[@]/_R1./_R2.}")
fi
