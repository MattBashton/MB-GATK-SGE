#!/bin/bash -e
#$ -cwd -V 
#$ -pe smp 2
#$ -l h_rt=4:00:00
#$ -l h_vmem=18G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs Picard SortSam using input passed in at command-line.
# 4hrs runtime by default.  -XX:ParallelGCThreads=2 prevents Picard using all threads.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $G_NAME.$SGE_TASK_ID.sam .sam`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/BWA_MEM/$B_NAME.sam to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/BWA_MEM/$B_NAME.sam $TMPDIR

echo "Running SortSam for $B_NAME.sam saving sorted indexed BAM as $B_NAME.bam"
/usr/bin/time --verbose $JAVA -Xmx16g -XX:ParallelGCThreads=2 \
-jar $PICARD SortSam \
INPUT=$TMPDIR/$B_NAME.sam \
TMP_DIR=$TMPDIR \
OUTPUT=$TMPDIR/$B_NAME.bam \
CREATE_INDEX=true \
VALIDATION_STRINGENCY=LENIENT \
MAX_RECORDS_IN_RAM=4000000 \
SORT_ORDER=coordinate

echo "Copying $TMPDIR/$SAMP_ID.ba* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.bam $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.bai $PWD

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
