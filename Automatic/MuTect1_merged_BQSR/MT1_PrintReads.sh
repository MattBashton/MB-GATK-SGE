#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 5
#$ -l h_vmem=24G
#$ -l h_rt=24:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs PrintReads to apply BQSR needs an input .bam to recal and the
# Recal_data.grp file.  Using -L optionally in $INTERVALS to remove off target
# reads as we don't call variants on these later.

set -o pipefail
hostname
date

source ../GATKsettings.sh

# Get info for pair using task id from array job
LINE=4(awk "NR==$SGE_TASK_ID" $MUTECT_LIST)
set $LINE
RUN_ID=$1
NORMAL=$2
TUMOUR=$3

# Make output name for this run
OUTPUT=$NORMAL.vs.$TUMOUR

#Input file path
INPUT_DIR="../MuTect1_Realn_pairs"

echo "** Variables **"
echo " - PWD = $PWD"
echo " - NORMAL = $NORMAL"
echo " - TUMOUR = $TUMOUR"
echo " - G_NAME = $G_NAME"
echo " - INPUT_DIR = $INPUT_DIR"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - OUTPUT = $OUTPUT"

echo "Copying normal input $INPUT_DIR/$OUTPUT.merged.realigned.ba* to $TMPDIR/"
/usr/bin/time --verbose cp -v $INPUT_DIR/$OUTPUT.merged.realigned.bam $TMPDIR
/usr/bin/time --verbose cp -v $INPUT_DIR/$OUTPUT.merged.realigned.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx18g -jar $GATK \
-T PrintReads \
-nct 5 \
$INTERVALS \
--interval_padding $PADDING \
-I $TMPDIR/$OUTPUT.merged.realigned.bam \
-R $REF \
-BQSR $OUTPUT.Recal_data.grp \
-o $TMPDIR/$OUTPUT.merged.realigned.recalibrated.bam \
--log_to_file $OUTPUT.PrintReads.log

echo "Copying $TMPDIR/$OUTPUT.merged.realigned.recalibrated.ba* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$OUTPUT.merged.realigned.recalibrated.bam $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$OUTPUT.merged.realigned.recalibrated.bai $PWD

echo "Deleting $TMPDIR/$OUTPUT.*"
rm $TMPDIR/$OUTPUT.*

date
echo "END"
