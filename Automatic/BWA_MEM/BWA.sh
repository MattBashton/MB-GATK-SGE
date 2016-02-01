#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 5
#$ -l h_rt=16:00:00
#$ -l h_vmem=8G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs BWA MEM using options obtained from $MASTER_LIST
# Job time being used too to help with getting a slot, 4hrs set - alter if need be.

set -o pipefail
hostname
date

source ../GATKsettings.sh

LINE=`awk "NR==$SGE_TASK_ID" $MASTER_LIST`
set $LINE
SAMP_ID=$1
RG=$2
FILE1=$3
FILE2=$4

B_NAME_F1=`basename $FILE1`
B_NAME_F2=`basename $FILE2`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - REF = $REF"
echo " - G_NAME = $G_NAME"
echo " - MASTER_LIST = $MASTER_LIST"
echo " - LINE = $LINE"
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

echo "Running BWA_MEM for $SAMP_ID saving SAM as $G_NAME.$SGE_TASK_ID.sam"
/usr/bin/time --verbose $BWA mem -t 5 -M -v 2 -R $RG $REF $TMPDIR/$B_NAME_F1 $TMPDIR/$B_NAME_F2 > $TMPDIR/$G_NAME.$SGE_TASK_ID.sam

echo "Copying $TMPDIR/$G_NAME.$SGE_TASK_ID.sam to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$G_NAME.$SGE_TASK_ID.sam $PWD

echo "Deleting $TMPDIR/$B_NAME_F1 and $B_NAME_F2"
rm $TMPDIR/$B_NAME_F1
rm $TMPDIR/$B_NAME_F2

echo "Deleting $TMPDIR/$G_NAME.$SAMP_ID.ba*"
rm $TMPDIR/$G_NAME.$SGE_TASK_ID.sam

date
echo "END"
