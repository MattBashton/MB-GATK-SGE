#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=8G 
#$ -l h_rt=2:00:00   
#$ -R y

# Matthew Bashton 2012-2015
# Runs Depth Of Coverage, needs an input .bam, file and the intervals targeted
# 2hrs run time by default, adjust if need be.

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
echo " - PWD = $PWD"

echo "Copying input $B_PATH_NAME.* to $TMPDIR"
/usr/bin/time --verbose cp -v $B_PATH_NAME.bam $TMPDIR
/usr/bin/time --verbose cp -v $B_PATH_NAME.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T DepthOfCoverage \
-L $INTERVALS \
-I $TMPDIR/$B_NAME.bam \
-R $BUNDLE_DIR/ucsc.hg19.fasta \
-o $TMPDIR/$B_NAME.DofC \
--log_to_file $B_NAME.DofC.log

echo "Copying $TMPDIR/$B_NAME.DofC.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.DofC.* $PWD

echo "Deleting $TMPDIR/$SUBSTR.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
