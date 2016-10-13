#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_rt=24:00:00
#$ -l h_vmem=8G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Splits a BAM file by its read groups, works as a job array make sure array
# task size or individual numbers matches number of read groups you want split
# out. $1 = input.bam to split

set -o pipefail
hostname
date

source ../GATKsettings.sh

# Input BAM file
INPUT_BAM=$1
B_NAME=$(basename $INPUT_BAM .bam)
DEST=$PWD

# Extract @RG ID to split for this $SGE_TASK_ID
RG=$($SAMTOOLS view -H $INPUT_BAM | grep '@RG' | grep -oP 'ID:\K\S+(?=\tPL)' | awk "NR==$SGE_TASK_ID")

echo "** Variables **"
echo " - PWD = $PWD"
echo " - DEST = $DEST"
echo " - INPUT_BAM = $INPUT_BAM"
echo " - B_NAME = $B_NAME"
echo " - RG = $RG"

echo "Copying $INPUT_BAM to $TMPDIR"
/usr/bin/time --verbose cp -v $B_NAME.bam $TMPDIR
/usr/bin/time --verbose cp -v $B_NAME.bai $TMPDIR

echo $RG > $TMPDIR/RG_file

cd $TMPDIR
echo "Running samtools view -h -R $TMPDIR/RF_file on $TMPDIR/$B_NAME.bam and outputing reads from read group: $RG and sorting bam to $TMPDIR/$B_NAME.$RG.bam"
/usr/bin/time --verbose samtools view -h -R $TMPDIR/RG_file $TMPDIR/$B_NAME.bam | samtools sort - > $TMPDIR/$B_NAME.$RG.bam

echo "Indexing $TMPDIR/B_NAME.$RG.bam"
/usr/bin/time --verbose samtools index $TMPDIR/$B_NAME.$RG.bam $TMPDIR/$B_NAME.$RG.bai
cd $DEST

echo "Checking output in $TMPDIR"
ls -lh $TMPDIR

echo "Copying split bam file $TMPDIR/$B_NAME.$RG.ba* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.$RG.bam $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.$RG.bai $PWD

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
