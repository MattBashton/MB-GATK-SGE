#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 5
#$ -l h_vmem=24G
#$ -l h_rt=24:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
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

B_NAME=`basename $1 .bam`
D_NAME=`dirname $1`
B_PATH_NAME=$D_NAME/$B_NAME

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - B_PATH_NAME = $B_PATH_NAME"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - PWD = $PWD"

echo "Copying input $B_PATH_NAME.* to $TMPDIR"
/usr/bin/time --verbose cp -v $B_PATH_NAME.bam $TMPDIR
/usr/bin/time --verbose cp -v $B_PATH_NAME.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx18g -jar $GATK \
-T BaseRecalibrator \
-nct 5 \
$INTERVALS \
--interval_padding $PADDING \
-I $TMPDIR/$B_NAME.bam \
-knownSites $DBSNP \
-knownSites $MILLS_1KG_GOLD \
-knownSites $PHASE1_INDELS \
-R $REF \
-o $TMPDIR/$B_NAME.Recal_data.grp \
--log_to_file $B_NAME.BaseRecal.log

echo "Deleting $TMPDIR/$B_NAME.bam"
rm $TMPDIR/$B_NAME.ba*

echo "Copying $TMPDIR/$B_NAME.Recal_data.grp to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.Recal_data.grp $PWD

date
echo "END"
