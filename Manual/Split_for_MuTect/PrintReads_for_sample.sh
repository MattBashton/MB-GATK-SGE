#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 2
#$ -l h_vmem=16G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Uses PrintReads to extract samples from a multi sample bam file,
# the second argument at the command-line should be the read group ID to extract
# and the first is the merged bam file to use as input.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $2 .bam`
D_NAME=`dirname $2`
B_PATH_NAME=$D_NAME/$B_NAME
SAMP_NAME=$1

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - B_PATH_NAME = $B_PATH_NAME"
echo " - SAMP_NAME = $SAMP_NAME"
echo " - PWD = $PWD"

echo "Copying input $B_PATH_NAME.* to $TMPDIR"
/usr/bin/time --verbose cp -v $B_PATH_NAME.bam $TMPDIR
/usr/bin/time --verbose cp -v $B_PATH_NAME.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx12g -jar $GATK \
-T PrintReads \
-nct 2 \
--sample_name $SAMP_NAME \
-I $TMPDIR/$B_NAME.bam \
-R $REF\
-o $TMPDIR/$SAMP_NAME.bam \
--log_to_file $SAMP_NAME.PrintReads.log

echo "Copying output $TMPDIR/$SAMP_NAME.ba* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_NAME.bam $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_NAME.bai $PWD

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

echo "Deleting $TMPDIR/$SAMP_NAME.*"
rm $TMPDIR/$SAMP_NAME.*

date
echo "END"
