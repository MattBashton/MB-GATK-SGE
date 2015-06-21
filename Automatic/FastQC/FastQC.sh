#!/bin/bash -e
#$ -cwd -V 
#$ -pe smp 2
#$ -l h_rt=02:00:00,h_vmem=2G
#$ -q all.q,bigmem.q 

# Matthew Bashton 2012-2015
# Runs FastQC on the supplied (at command line $1) .fastq or .fastq.gz file.
# Note parallelisation with FastQC is a waste of time as only works with 
# multiple input files, and these are submited as diff SoGE jobs.
# Default run time is two hours, adjust if need be.

set -o pipefail
hostname
date

source ../GATKsettings.sh

REF="$BUNDLE_DIR/ucsc.hg19.fasta"

LINE=`awk "NR==$SGE_TASK_ID" $MASTER_LIST`
set $LINE
SAMP_ID=$1
RG=$2
FILE1=$3
FILE2=$4

B_NAME_F1=`basename $FILE1`
B_NAME_F2=`basename $FILE2`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - G_NAME = $G_NAME"
echo " - MASTER_LIST = $MASTER_LIST"
echo " - LINE = $LINE"
echo " - SAMP_ID = $SAMP_ID"
echo " - RG = $RG"
echo " - FILE1 = $FILE1"
echo " - FILE2 = $FILE2"
echo " - B_NAME_F1 = $B_NAME_F1"
echo " - B_NAME_F2 = $B_NAME_F2"
echo " - PWD = $PWD"

echo "Copying input $FILE1 and $FILE2 to $TMPDIR/$B_NAME"
/usr/bin/time --verbose cp -v $FILE1 $TMPDIR/$B_NAME
/usr/bin/time --verbose cp -v $FILE2 $TMPDIR/$B_NAME

echo "Running FastQC on $FILE1 and $FILE2"
/usr/bin/time --verbose $FASTQC -t 2 $FILE1 $FILE2 --noextract -q -o $PWD -d $TMPDIR

echo "Deleting $TMPDIR/$B_NAME"
rm $TMPDIR/$B_NAME/*.gz

date
echo "END"
