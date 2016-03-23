#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=8G
#$ -l h_rt=4:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs Select Variants on VCF to pull out somatic PASSing variants produced by
# MuTect2.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $1 .vcf`
D_NAME=`dirname $1`
B_PATH_NAME=$D_NAME/$B_NAME

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - D_NAME = $D_NAME"
echo " - B_PATH_NAME = $B_PATH_NAME"
echo " - INPUT = $INPUT"
echo " - PWD = $PWD"

echo "Copying input $B_PATH_NAME.* to $TMPDIR"
/usr/bin/time --verbose cp -v $B_PATH_NAME.vcf $TMPDIR
/usr/bin/time --verbose cp -v $B_PATH_NAME.vcf.idx $TMPDIR

echo "Running GATK outputing PASSing variants"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $REF \
--out /$TMPDIR/$B_NAME.somatic.vcf \
--excludeFiltered \
--log_to_file $B_NAME.SelectVariants.somatic.PASS.log

echo "Copying back output $TMPDIR/$B_NAME.somatic.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.somatic.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.somatic.vcf.idx $PWD

echo "Deleting $TMPDIR/$B_NAME**"
rm $TMPDIR/$B_NAME*

date
echo "END"
