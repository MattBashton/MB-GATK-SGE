#!/bin/bash -u
#$ -cwd -V
#$ -pe smp 2
#$ -l h_rt=24:00:00
#$ -l h_vmem=8G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs Picard BuildBamIndex

set -o pipefail
hostname
date

source ../GATKsettings.sh

INPUT_DIR="../SamToSortedBam/"

echo "** Variables **"
echo " - PWD = $PWD"
echo " - G_NAME = $G_NAME"
echo " - INPUT_DIR = $INPUT_DIR"

echo "Copying input file $INPUT_DIR/$G_NAME.$SGE_TASK_ID.ba* to $TMPDIR/"
/usr/bin/time --verbose cp -v $INPUT_DIR/$G_NAME.$SGE_TASK_ID.bam $TMPDIR
/usr/bin/time --verbose cp -v $INPUT_DIR/$G_NAME.$SGE_TASK_ID.bai $TMPDIR

echo "Running Picard ValidateSamFile on $G_NAME.$SGE_TASK_ID.dedup.realigned.recalibrated.bam"
/usr/bin/time --verbose $JAVA -Xmx4g -XX:ParallelGCThreads=2 \
-jar $PICARD ValidateSamFile \
INPUT=$TMPDIR/$G_NAME.$SGE_TASK_ID.dedup.realigned.recalibrated.bam \
OUTPUT=$TMPDIR/$G_NAME.$SGE_TASK_ID.ValidateSamFile.txt \
TMP_DIR=$TMPDIR \
MODE=SUMMARY \
MAX_RECORDS_IN_RAM=8000000 \
MAX_OUTPUT='null'

echo "Copying $TMPDIR/$G_NAME.$SGE_TASK_ID.ValidateSamFile.txt to $PWD"
/usr/bin/time --verbose cp $TMPDIR/$G_NAME.$SGE_TASK_ID.ValidateSamFile.txt $PWD

echo "Deleting $TMPDIR/*.ba*"
rm $TMPDIR/*.ba*

date
echo "END"
