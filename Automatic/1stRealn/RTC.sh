#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 5
#$ -l h_vmem=22G
#$ -l h_rt=24:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs Realigner Target Creator, needs an input .bam file, will generate the
# intervals file for alignment for that region.  If you set $INTERVALS to ""
# in ../GATKsettings.sh then -L string will be missing and all data will be
# used, set like this for WGS.
# 24hrs run time by default.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $G_NAME.$SGE_TASK_ID.dedup.bam .bam`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/MarkDuplicates/$G_NAME.$SGE_TASK_ID.dedup.* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/MarkDuplicates/$G_NAME.$SGE_TASK_ID.dedup.bam $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/MarkDuplicates/$G_NAME.$SGE_TASK_ID.dedup.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx18g -jar $GATK \
-T RealignerTargetCreator \
-nt 5 \
$INTERVALS \
--interval_padding $PADDING \
-known $MILLS_1KG_GOLD \
-known $PHASE1_INDELS \
-I $TMPDIR/$B_NAME.bam \
-R $REF \
-o $TMPDIR/$B_NAME.RTC.intervals \
--log_to_file $B_NAME.RTC.log

echo "Copying $TMPDIR/$B_NAME.RTC.intervals to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.RTC.intervals $PWD

echo "Deleting $TMPDIR/$SUBSTR.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
