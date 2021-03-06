#!/bin/bash -e

# Files generated by this pipeline will be save in the given <output> directory (or in local directory is none is given)

usage(){
    NAME=$(basename $0)
    cat <<EOF
Usage:
  ${NAME} [output]
Wrapper script for RNA-Seq analysis protocol used for the analysis of ESCAPE data 
based on the HISAT2/StringTie protocol (Pertea et al., Nat. Prot., 2016), 
adding a pre-processing step using SortMeRNA (Kopylova E., Noé L. and Touzet H., Bioinformatics, 2012) 
and TrimGalore! (Felix Krueger, The Babraham Institute).
This is a modified and extended version of the wrapper provided by the authors
of the protocol (to see the original visit ftp://ftp.ccb.jhu.edu/pub/RNAseq_protocol).

In order to configure the pipeline options (input/output files etc.)
please copy and edit a file rnaseq_pipeline_escape.config.sh which must be
placed in the current (working) directory where this script is being launched.

Output directories "hisat2", "ballgown", "sortmerna", "trimgalore", "counts" will be created in the 
current working directory or, if provided, in the given [output] (which will be created if it does not exist).

EOF
}

OUTDIR="."

if [[ "$1" ]]; then
 if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 1
 fi
 OUTDIR=$1
fi


## load variables
if [[ ! -f ./rnaseq_pipeline_escape.config.sh ]]; then
 usage
 echo "Error: configuration file (rnaseq_pipeline_escape.config.sh) missing!"
 exit 1
fi

source ./rnaseq_pipeline_escape.config.sh
WRKDIR=$(pwd -P)
errprog=""
if [[ ! -x $SAMTOOLS ]]; then
    errprog="samtools"
fi
if [[ ! -x $HISAT2 ]]; then
    errprog="hisat2"
fi
if [[ ! -x $STRINGTIE ]]; then
    errprog="stringtie"
fi

if [[ "$errprog" ]]; then
  echo "ERROR: $errprog program not found, please edit the configuration script."
  exit 1
fi
if [[ ! -x $SORTMERNA ]]; then
    errprog="sortmerna"
fi
if [[ ! -x $TRIMGALORE ]]; then
    errprog="trimgalore"
fi
if [[ ! -x $GFFCOMPARE ]]; then
    errprog="gffcompare"
fi

if [[ ! -f rnaseq_ballgown.R ]]; then
   echo "ERROR: R script rnaseq_ballgown.R not found in current directory!"
   exit 1
fi


## prepDE.py
if [[ ! -f $PREPDE ]]; then
 echo "Error: $PREPDE file missing!"
 exit 1
fi
P=$WRKDIR/$PREPDE
PREPDE=$P

#Create output directory
mkdir -p $OUTDIR
cd $OUTDIR


SCRIPTARGS="$@"
ALIGNLOC=./hisat2
BALLGOWNLOC=./ballgown
SORTMERNALOC=./sortmerna
rRNALOC=${SORTMERNALOC}/rRNA
nonrRNALOC=${SORTMERNALOC}/nonrRNA
TRIMGALORELOC=./trimgalore
COUNTSLOC=./counts

LOGFILE=./run.log

for d in "$TEMPLOC" "$ALIGNLOC" "$BALLGOWNLOC" "$SORTMERNALOC" "$rRNALOC" "$nonrRNALOC" "$TRIMGALORELOC" "$COUNTSLOC" ; do
 if [ ! -d $d ]; then
    mkdir -p $d
 fi
done

# main script block
pipeline() {

echo [`date +"%Y-%m-%d %H:%M:%S"`] "#> START: " $0 $SCRIPTARGS


##Starting from raw datas or samples?
if [ $RAW -eq 1 ]; then
    for ((i=0; i<=${#reads1[@]}-1; i++ )); do
        sample="${reads1[$i]%%.*}"
        sample="${sample%_*}"
        stime=`date +"%Y-%m-%d %H:%M:%S"`
        echo "[$stime] Preprocessing raw sample: $sample"
        
        echo [$stime] "   * Concatenate forward and reverse reads ( raw data )"
        find ${RAWDATA}/*${sample}* | grep -i R1.fastq.gz$ | sort -n |  xargs -i{} -n1 cat {} > ${TEMPLOC}/${sample}_R1.fastq.gz
        find ${RAWDATA}/*${sample}* | grep -i R2.fastq.gz$ | sort -n |  xargs -i{} -n1 cat {} > ${TEMPLOC}/${sample}_R2.fastq.gz
        echo [`date +"%Y-%m-%d %H:%M:%S"`] "   * Concatenate forward and reverse reads ( raw data )"
    done
   
    #samples directory
    if [ ! -d $FASTQLOC ]; then
        mkdir -p $FASTQLOC
    fi
 
    echo [$stime] "   * gunzip forward and reverse reads ( raw data )"
    gunzip ${TEMPLOC}/*.gz 
    mv ${TEMPLOC}/*.fastq ${FASTQLOC}/
    echo [`date +"%Y-%m-%d %H:%M:%S"`] "   * gunzip forward and reverse reads ( raw data )"
fi  


## sortmerna, then hisat2 and stringtie
for ((i=0; i<=${#reads1[@]}-1; i++ )); do
    sample="${reads1[$i]%%.*}"
    sample="${sample%_*}"
    stime=`date +"%y-%m-%d %h:%m:%s"`
    echo "[$stime] Processing sample: $sample"

    echo "   * Pre-processing "
    echo [$stime] "   * Merge paired-end reads ( SortMeRNA )"
    $MERGEPAIREDREADS ${FASTQLOC}/${sample}_R1.fastq ${FASTQLOC}/${sample}_R2.fastq ${TEMPLOC}/${sample}_merged.fastq
    echo [`date +"%Y-%m-%d %H:%M:%S"`] "   * Merge paired-end reads ( SortMeRNA )"


    ##separate ribosomal from non-ribosomal RNA with sortmerna
    echo [$stime] "   * Filter out ribosomal RNA reads ( SortMeRNA )"
    $SORTMERNA --ref $rRNADBs --reads ${TEMPLOC}/${sample}_merged.fastq --fastx --aligned ${TEMPLOC}/${sample}_rRNA --other ${TEMPLOC}/${sample}_non_rRNA --paired_out --log -a $NUMCPUS
    echo [`date +"%Y-%m-%d %H:%M:%S"`] "   * Filter out ribosomal RNA reads ( SortMeRNA )"

    
    ###unmerge non-rRNA paired reads
    echo [$stime] "   * UnMerge non-rRNA reads ( SortMeRNA )"
    $UNMERGEPAIREDREADS ${TEMPLOC}/${sample}_non_rRNA.fastq ${nonrRNALOC}/${sample}_R1.fastq ${nonrRNALOC}/${sample}_R2.fastq
    echo [`date +"%Y-%m-%d %H:%M:%S"`] "   * Unmerge non-rRNA reads ( SortMeRNA )"


    ###unmerge rRNA paired reads
    echo [$stime] "   * UnMerge rRNA reads ( SortMeRNA )"
    $UNMERGEPAIREDREADS ${TEMPLOC}/${sample}_rRNA.fastq ${rRNALOC}/${sample}_R1.fastq ${rRNALOC}/${sample}_R2.fastq
    echo [`date +"%Y-%m-%d %H:%M:%S"`] "   * Unmerge rRNA reads ( SortMeRNA )"

    ##remove tmp files
    echo "...removing intermediate files"
    mv ${TEMPLOC}/${sample}_rRNA.log ${SORTMERNALOC}/
    rm ${TEMPLOC}/${sample}_merged.fastq
    rm ${TEMPLOC}/${sample}_rRNA.fastq
    rm ${TEMPLOC}/${sample}_non_rRNA.fastq

    ##remove adaptor sequences
    echo [$stime] "   * Applying quality and adapter trimming ( Trim Galore! )"
    $TRIMGALORE -q 20 --phred33 --stringency 5 -length 60 --paired -o $TRIMGALORELOC --fastqc ${nonrRNALOC}/${sample}_R1.fastq ${nonrRNALOC}/${sample}_R2.fastq
    echo [`date +"%Y-%m-%d %H:%M:%S"`] "   * Applying quality and adapter trimming ( Trim Galore! )"


    echo [$stime] "   * alignment of reads to genome (hisat2)"
    $HISAT2 -p $NUMCPUS -q --dta-cufflinks -x ${GENOMEIDX}/genome \
     -1 ${TRIMGALORELOC}/${sample}_R1_val_1.fq \
     -2 ${TRIMGALORELOC}/${sample}_R2_val_2.fq \
     -S ${TEMPLOC}/${sample}.sam 2>${ALIGNLOC}/${sample}.alnstats
    echo [`date +"%y-%m-%d %h:%m:%s"`] "   * alignments conversion (samtools)"
    

    $SAMTOOLS sort -@ $NUMCPUS -o ${ALIGNLOC}/${sample}.bam ${TEMPLOC}/${sample}.sam

    echo "..removing intermediate files"
    rm ${TEMPLOC}/${sample}.sam

    echo [`date +"%y-%m-%d %h:%m:%s"`] "   * assemble transcripts (stringtie)"
    $STRINGTIE -p $NUMCPUS -g ${GTFFILE} -o ${ALIGNLOC}/${sample}.gtf \
    -l ${sample} ${ALIGNLOC}/${sample}.bam

done


## merge transcript file
echo [`date +"%y-%m-%d %h:%m:%s"`] "#> merge all transcripts (stringtie)"
ls -1 ${ALIGNLOC}/*.gtf > ${ALIGNLOC}/mergelist.txt

$STRINGTIE --merge -p $NUMCPUS -g  ${GTFFILE} \
    -o ${BALLGOWNLOC}/stringtie_merged.gtf ${ALIGNLOC}/mergelist.txt



## examine how scripts compare to the reference annotation
echo [`date +"%Y-%m-%d %H:%M:%S"`] "#> Compare transcripts to the reference annotation (gffcompare)"
$GFFCOMPARE -r ${GTFFILE} -G -o ${BALLGOWNLOC}/gffcompare_merged ${BALLGOWNLOC}/stringtie_merged.gtf



## estimate transcript abundance
echo [`date +"%Y-%m-%d %H:%M:%S"`] "#> Estimate abundance for each sample (StringTie)"
for ((i=0; i<=${#reads1[@]}-1; i++ )); do
    sample="${reads1[$i]%%.*}"
    dsample="${sample%%_*}"
    sample="${sample%_*}"
    if [ ! -d ${BALLGOWNLOC}/${dsample} ]; then
       mkdir -p ${BALLGOWNLOC}/${dsample}
    fi
    $STRINGTIE -e -B -p $NUMCPUS -G ${BALLGOWNLOC}/gffcompare_merged.annotated.gtf \
    -o ${BALLGOWNLOC}/${dsample}/${dsample}.gtf ${ALIGNLOC}/${sample}.bam \
    -A ${BALLGOWNLOC}/${dsample}/${dsample}.tab

done


echo [`date +"%Y-%m-%d %H:%M:%S"`] "#> Generate the DE tables (Ballgown)"

## Generate the ballgown object:  ballgown/bg_HomoSapiens_GRChr38.89_noPD.rda
$RSCRIPT ${WRKDIR}/rnaseq_ballgown.R 


## Create counts table to be used by egdeR
echo [`date +"%Y-%m-%d %H:%M:%S"`] "#> Generate the DE tables (Ballgown)"
python $PREPDE -i $BALLGOWNLOC -g ${COUNTSLOC}/gene_count_matrix.csv -t ${COUNTSLOC}/transcript_count_matrix.csv -l $READLENGTH



echo [`date +"%Y-%m-%d %H:%M:%S"`] "#> DONE. End of Pipeline"
} #pipeline end


pipeline 2>&1 | tee $LOGFILE
