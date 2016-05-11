#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 5
#$ -l h_vmem=22G
#$ -l h_rt=24:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs BaseRecalibrator needs an input .bam file, output is the Recal_data.grp
# file.
# Using -L intervals from kit will ensure off target reads are not used for
# Recalibration, 100bp padding should also be used on these.
# Output is .grp file

# Note pre-set for and tested on exomes, for less than 100M bases per RG
# targeted don't run BQSR see:
# http://gatkforums.broadinstitute.org/discussion/comment/14269/#Comment_14269

set -o pipefail
hostname
date

source ../GATKsettings.sh

# Get info for pair using task id from array job
LINE=`awk "NR==$SGE_TASK_ID" $MUTECT_LIST`
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
-T BaseRecalibrator \
-nct 5 \
$INTERVALS \
--interval_padding $PADDING \
-I $TMPDIR/$OUTPUT.merged.realigned.bam \
-knownSites $DBSNP \
-knownSites $MILLS_1KG_GOLD \
-knownSites $PHASE1_INDELS \
-R $REF \
-o $TMPDIR/$OUTPUT.Recal_data.grp \
--log_to_file $OUTPUT.BaseRecal.log

echo "Copying $TMPDIR/$OUTPUT.Recal_data.grp to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$OUTPUT.Recal_data.grp $PWD

echo "Deleting $TMPDIR/$OUTPUT.*"
rm $TMPDIR/$OUTPUT.*

date
echo "END"
