#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=8G
#$ -l h_rt=4:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs Select Variants on VCF to pull out somatic PASSing variants produced by
# MuTect 1.

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

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - INPUT = $INPUT"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/MuTect2/$INPUT* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/MuTect2/$INPUT.vcf $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/MuTect2/$INPUT.vcf.idx $TMPDIR

echo "Running GATK outputing PASSing variants"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$INPUT.vcf \
-R $REF \
--out $TMPDIR/$INPUT.somatic.vcf \
--excludeFiltered \
--log_to_file $INPUT.SelectVariants.somatic.PASS.log

echo "Copying back output $TMPDIR/$INPUT.somatic.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$INPUT.somatic.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$INPUT.somatic.vcf.idx $PWD

echo "Deleting $TMPDIR/$INPUT*"
rm $TMPDIR/$INPUT*

date
echo "END"
