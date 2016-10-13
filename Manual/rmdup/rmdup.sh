#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_rt=24:00:00
#$ -l h_vmem=6G
#$ -R y

# Matthew Bashton 2015-2016
# Uses SAMtools to remove PCR duplicates from a BAM file, not part of GATK
# pipeline but useful for external tools.

set -o pipefail
hostname
date

source ../GATKsettings.sh

BAM=$1
B_NAME=$(basename $BAM .bam)

echo "** Variables **"
echo " - PWD = $PWD"
echo " - BAM = $BAM"
echo " - B_NAME = $B_NAME"

echo "Copying input $BAM to $TMPDIR/"
/usr/bin/time --verbose cp -v $BAM $TMPDIR

echo "Running SAMtools rmdup on $TMPDIR/$B_NAME "
/usr/bin/time --verbose $OLDSAMTOOLS rmdup $TMPDIR/$B_NAME.bam $TMPDIR/$B_NAME.deduped.bam

echo "Copying $TMPDIR/$B_NAME.deduped.bam to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.deduped.bam $PWD

echo "Deleting $TMPDIR/*.bam"
rm $TMPDIR/*.bam

date
echo "END"
