#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 2
#$ -l h_vmem=12G
#$ -l h_rt=12:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs Apply Recalibration, this takes the .recal file and applies it to the raw
# vcf produced by the HC, output is a recalibrated .vcf file.
# Using TS of 99.0 for indels as per GATK doc #1259 and #2805
# https://www.broadinstitute.org/gatk/guide/article?id=1259
# https://www.broadinstitute.org/gatk/guide/article?id=2805

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=$(basename $G_NAME.HC_genotyped.vcf .vcf)

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/GenotypeGVCFs/$G_NAME.HC_genotyped.vcf* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/GenotypeGVCFs/$G_NAME.HC_genotyped.vcf $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/GenotypeGVCFs/$G_NAME.HC_genotyped.vcf.idx $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx8g -jar $GATK \
-T ApplyRecalibration \
-nt 2 \
-input $TMPDIR/$B_NAME.vcf \
-R $REF \
-recalFile $B_NAME.VR_HC_indels.recal \
-tranchesFile $B_NAME.VR_HC_indels.tranches \
-o $TMPDIR/$B_NAME.vrecal.indels.vcf \
-mode INDEL \
--ts_filter_level 99.0 \
--log_to_file $B_NAME.AR_HC_indels.log

echo "Copying back output $TMPDIR/$B_NAME.vcf* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.vrecal.indels.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.vrecal.indels.vcf.idx $PWD

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
