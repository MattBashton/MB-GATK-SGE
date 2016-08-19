#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_rt=4:00:00
#$ -l h_vmem=8G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs VariantsToTable to convert .vcf to .tab for MuTect1 vcf output.
# Outputs CHROM, POS, REF, ALT, FILTER, GT:AD:DP:FA for all samples

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

# Make input name for this run
INPUT=$NORMAL.vs.$TUMOUR

#Input file path
INPUT_DIR="../MuTect1"

echo "** Variables **"
echo " - PWD = $PWD"
echo " - NORMAL = $NORMAL"
echo " - TUMOUR = $TUMOUR"
echo " - INPUT_DIR = $INPUT_DIR"
echo " - INPUT = $INPUT"

echo "Copying normal input $INPUT_DIR/$INPUT.vc* to $TMPDIR/"
/usr/bin/time --verbose cp -v $INPUT_DIR/$INPUT.vcf $TMPDIR
/usr/bin/time --verbose cp -v $INPUT_DIR/$INPUT.vcf.idx $TMPDIR

echo "Running VariantsToTable on $INPUT"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T VariantsToTable \
-R $REF \
-V $TMPDIR/$INPUT.vcf \
-F CHROM \
-F POS \
-F REF \
-F ALT \
-F FILTER \
--showFiltered \
-GF GT \
-GF AD \
-GF DP \
-GF FA \
-o $TMPDIR/$INPUT.txt

echo "Copying $TMPDIR/$INPUT.txt to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$INPUT.txt $PWD

echo "Deleting $TMPDIR/$INPUT.*"
rm $TMPDIR/$INPUT.*

date
echo "END"
