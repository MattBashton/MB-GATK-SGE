#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 5
#$ -l h_rt=48:00:00
#$ -l h_vmem=8G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs BWA MEM using options passed in at command-line.
# Another script needs to call this one which has a list of all files, @RG lines and Sample IDs.
# Job time being used too to help with getting a slot, 1hrs set - alter if need be.

set -o pipefail
hostname
date

source ../GATKsettings.sh

SAMP_ID=$1
RG=$2
FILE1=$3
FILE2=$4

B_NAME_F1=`basename $FILE1`
B_NAME_F2=`basename $FILE2`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - REF = $REF"
echo " - SAMP_ID = $SAMP_ID"
echo " - RG = $RG"
echo " - FILE1 = $FILE1"
echo " - FILE2 = $FILE2"
echo " - B_NAME_F1 = $B_NAME_F1"
echo " - B_NAME_F2 = $B_NAME_F2"
echo " - PWD = $PWD"

echo "Copying input $FILE1 to $TMPDIR/"
/usr/bin/time --verbose cp -v $FILE1 $TMPDIR

echo "Copying input $FILE2 to $TMPDIR/"
/usr/bin/time --verbose cp -v $FILE2 $TMPDIR

echo "Running BWA_MEM for $SAMP_ID saving SAM as $SAMP_ID.sam"
/usr/bin/time --verbose $BWA mem -t 5 -M -v 2 -R $RG $REF $TMPDIR/$B_NAME_F1 $TMPDIR/$B_NAME_F2 > $TMPDIR/$SAMP_ID.sam

echo "Copying $TMPDIR/$SAMP_ID.ba* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.sam $PWD

echo "Deleting $TMPDIR/$B_NAME_F1 and $B_NAME_F2"
rm $TMPDIR/$B_NAME_F1
rm $TMPDIR/$B_NAME_F2

echo "Deleting $TMPDIR/$SAMP_ID.ba*"
rm $TMPDIR/$SAMP_ID.sam

date
echo "END"
