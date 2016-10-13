#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 5
#$ -l h_vmem=24G
#$ -l h_rt=24:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs Realigner Target Creator, needs an input .bam file, will generate the
# intervals file for alignment for that region.  If you set $INTERVALS to ""
# in ../GATKsettings.sh then -L string will be missing and all data will be
# used, set like this for WGS.
# 24hrs run time by default.

set -o pipefail
hostname
date

source ../GATKsettings.sh

# Get info for pair using task id from array job
LINE=$(awk "NR==$SGE_TASK_ID" $MUTECT_LIST)
set $LINE
RUN_ID=$1
NORMAL=$2
TUMOUR=$3

# Make output name for this run
OUTPUT=$NORMAL.vs.$TUMOUR

#Input file path
INPUT_DIR="../Merge_MuTect1_pairs"

echo "** Variables **"
echo " - PWD = $PWD"
echo " - NORMAL = $NORMAL"
echo " - TUMOUR = $TUMOUR"
echo " - G_NAME = $G_NAME"
echo " - INPUT_DIR = $INPUT_DIR"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - OUTPUT = $OUTPUT"

echo "Copying normal input $INPUT_DIR/$OUTPUT.dedup.realigned.merged.ba* to $TMPDIR/"
/usr/bin/time --verbose cp -v $INPUT_DIR/$OUTPUT.dedup.realigned.merged.bam $TMPDIR
/usr/bin/time --verbose cp -v $INPUT_DIR/$OUTPUT.dedup.realigned.merged.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx18g -jar $GATK \
-T RealignerTargetCreator \
-nt 5 \
$INTERVALS \
--interval_padding $PADDING \
-known $MILLS_1KG_GOLD \
-known $PHASE1_INDELS \
-I $TMPDIR/$OUTPUT.dedup.realigned.merged.bam \
-R $REF \
-o $TMPDIR/$OUTPUT.RTC.intervals \
--log_to_file $OUTPUT.RTC.log

echo "Copying $TMPDIR/$OUTPUT.RTC.intervals to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$OUTPUT.RTC.intervals $PWD

echo "Deleting $TMPDIR/$OUTPUT.*"
rm $TMPDIR/$OUTPUT.*

date
echo "END"
