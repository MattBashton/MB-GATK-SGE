#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 2
#$ -l h_vmem=12G
#$ -l h_rt=2:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs Apply Recalibration, this takes the .recal file and applies it to the raw
# vcf produced by the HC, output is a recalibrated .vcf file.
# Using TS of 99.5 for SNPs as per GATK doc #1259, note that #2805 uses 99.0
# https://www.broadinstitute.org/gatk/guide/article?id=2805
# https://www.broadinstitute.org/gatk/guide/article?id=1259


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
echo " - B_PATH_NAME = $B_PATH_NAME"
echo " - PWD = $PWD"

echo "Copying input $B_PATH_NAME.* to $TMPDIR"
/usr/bin/time --verbose cp -v $B_PATH_NAME.vcf $TMPDIR
/usr/bin/time --verbose cp -v $B_PATH_NAME.vcf.idx $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx8g -jar $GATK \
-T ApplyRecalibration \
-nt 2 \
-input $TMPDIR/$B_NAME.vcf \
-R $REF \
-recalFile $B_NAME.VR_HC_snps.recal \
-tranchesFile $B_NAME.VR_HC_snps.tranches \
-o $TMPDIR/$B_NAME.vrecal.snps.vcf \
-mode SNP \
--ts_filter_level 99.5 \
--log_to_file $B_NAME.AR_HC_snps.log

echo "Copying back output $TMPDIR/$B_NAME.vcf* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.vrecal.snps.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.vrecal.snps.vcf.idx $PWD

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
