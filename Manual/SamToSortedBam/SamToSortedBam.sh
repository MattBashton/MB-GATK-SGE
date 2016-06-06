#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 2
#$ -l h_rt=48:00:00
#$ -l h_vmem=20G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs Picard SortSam using input passed in at command-line.
# 4hrs runtime by default.  -XX:ParallelGCThreads=2 prevents Picard using all threads.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $1 .sam`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - PWD = $PWD"

echo "Copying input $1 to $TMPDIR/"
/usr/bin/time --verbose cp -v $1 $TMPDIR

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
