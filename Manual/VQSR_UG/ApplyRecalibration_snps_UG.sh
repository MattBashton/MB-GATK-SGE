#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 2
#$ -l h_vmem=12G
#$ -l h_rt=12:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs Apply Recalibration, this takes the .recal file and applies it to the raw
# vcf produced by the HC, output is a recalibrated .vcf file.
# Using TS of 99.0 for SNPs as per GATK doc #2805, note that #1259 uses 99.5
# https://www.broadinstitute.org/gatk/guide/article?id=2805
# https://www.broadinstitute.org/gatk/guide/article?id=1259

# As of GATK 3.6 4 attempts are now made to build a model

# Target Ti/Tv ratio is set at 3.2 for exomes, the deault for genomes is 2.15.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=$(basename $1 .vcf)
D_NAME=$(dirname $1)
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
-recalFile $B_NAME.VR_UG_snps.recal \
-tranchesFile $B_NAME.VR_UG_snps.tranches \
-o $TMPDIR/$B_NAME.vrecal.snps.vcf \
-mode SNP \
--target_titv 3.2 \
--ts_filter_level 99.0 \
--max_attempts 4 \
--log_to_file $B_NAME.AR_UG_snps.log

echo "Copying back output $TMPDIR/$B_NAME.recalibrated.snps.vcf* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.vrecal.snps.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.vrecal.snps.vcf.idx $PWD

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
