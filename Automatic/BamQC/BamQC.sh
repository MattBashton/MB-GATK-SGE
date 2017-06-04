#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_rt=6:00:00
#$ -l h_vmem=6G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2016
# Runs BamQC on a bam file in the automated pipeline.
# Note parallelisation with BamQC is a waste of time as only works with
# multiple input files, and these are submited as diff SoGE jobs.
# Default run time is two hours, adjust if need be.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=$G_NAME.$SGE_TASK_ID

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - G_NAME = $G_NAME"
echo " - B_NAME = $B_NAME"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/MarkDuplicates/$B_NAME.dedup.ba* to $TMPDIR/"
/usr/bin/time --verbose cp -v $BASE_DIR/MarkDuplicates/$B_NAME.dedup.bam $TMPDIR/
/usr/bin/time --verbose cp -v $BASE_DIR/MarkDuplicates/$B_NAME.dedup.bai $TMPDIR/

echo "Running BamQC on $TMPDIR/$B_NAME.bam"
/usr/bin/time --verbose $BAMQC -s "Homo sapiens" -a GRCh37 -g $BAMQC_GENOMES --noextract -o $PWD -d $TMPDIR $TMPDIR/$B_NAME.dedup.realigned.recalibrated.bam

echo "Deleting $TMPDIR/*.ba*"
rm $TMPDIR/*.ba*

date
echo "END"
