#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=8G
#$ -l h_rt=6:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs Depth Of Coverage, needs an input .bam, file and the intervals targeted
# 6hrs run time by default, adjust if need be.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $G_NAME.$SGE_TASK_ID.dedup.bam .bam`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - INTERVALS = $INTERVALS"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/MarkDuplicates/$G_NAME.$SGE_TASK_ID.dedup.* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/MarkDuplicates/$G_NAME.$SGE_TASK_ID.dedup.bam $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/MarkDuplicates/$G_NAME.$SGE_TASK_ID.dedup.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T DepthOfCoverage \
$INTERVALS \
--interval_padding $PADDING \
-I $TMPDIR/$B_NAME.bam \
-R $REF \
-o $TMPDIR/$B_NAME.DofC \
--log_to_file $B_NAME.DofC.log

echo "Copying $TMPDIR/$B_NAME.DofC.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.DofC.* $PWD

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
