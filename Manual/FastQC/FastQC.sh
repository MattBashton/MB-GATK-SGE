#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 1
#$ -l -l h_rt=02:00:00,h_vmem=2G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs FastQC on the supplied (at command line $1) .fastq or .fastq.gz file.
# Note parallelisation with FastQC is a waste of time as only works with
# multiple input files, and these are submited as diff SoGE jobs.
# Default run time is two hours, adjust if need be.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $1`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - PWD = $PWD"

echo "Copying input $1 to $TMPDIR/$B_NAME"
/usr/bin/time --verbose cp -v $1 $TMPDIR/$B_NAME

echo "Running FastQC on $1"
/usr/bin/time --verbose $FASTQC -t 1 --noextract -q -o $PWD -d $TMPDIR

echo "Deleting $TMPDIR/$B_NAME"
rm $TMPDIR/$B_NAME/*.gz

date
echo "END"
