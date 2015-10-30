#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 5
#$ -l h_rt=6:00:00
#$ -l h_vmem=1G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2015
# Converts aligned FASTQ to gziped FASTQ using pigz

set -o pipefail
hostname
date

source ../GATKsettings.sh

FASTQ=$1
B_NAME=`basename $FASTQ`

echo "** Variables **"
echo " - PWD = $PWD"
echo " - FASTQ = $FASTQ"
echo " - B_NAME = $B_NAME"

echo "Copying input $FASTQ to $TMPDIR/"
/usr/bin/time --verbose cp -v $FASTQ $TMPDIR

echo "Running pigz on $TMPDIR/$B_NAME saving output as a gziped FASTQ file"
/usr/bin/time --verbose pigz -p 5 $TMPDIR/$B_NAME

echo "Copying $TMPDIR/*.fastq.gz to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/*.fastq.gz $PWD

echo "Deleting $TMPDIR/*.gz"
rm $TMPDIR/*.gz

date
echo "END"
