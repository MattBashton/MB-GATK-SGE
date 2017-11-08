#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=14G
#$ -l h_rt=12:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016

# Runs the Variant Recalibrator input is raw VCF from the HC and output is a
# recal file which can be applied using Apply Recalibration.
# Not using -an DP since this is a bad idea for exome + targeted panels.
# maxGuassians 4 needed to get things working with targeted data, drop this for
# exomes, unless small < 10 sample number or you have issues with too few bad
# variants.  Also leaving out InbreedingCoeff some discussion of this being
# problematic too on forums, needs at least 10 samples which are not related.
# Settings as given in GATK doc #1259 and #2805:
# https://www.broadinstitute.org/gatk/guide/article?id=2805
# https://www.broadinstitute.org/gatk/guide/article?id=1259
# Also you need to use dbsnp_138.hg19.excluding_sites_after_129.vcf see bottom of
# comments section on above link.

# As of GATK 3.6 4 attempts are now made to build a model

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
/usr/bin/time --verbose $JAVA -Xmx10g -jar $GATK \
-T VariantRecalibrator \
-input $TMPDIR/$B_NAME.vcf \
-R $REF \
-recalFile $B_NAME.VR_HC_indels.recal \
-tranchesFile $B_NAME.VR_HC_indels.tranches \
-rscriptFile $B_NAME.VR_HC_indels.R \
-resource:mills,known=false,training=true,truth=true,prior=12.0 $MILLS_1KG_GOLD \
-resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $DBSNP129 \
--maxGaussians 4 \
-an QD \
-an FS \
-an SOR \
-an MQRankSum \
-an ReadPosRankSum \
-mode INDEL \
-tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 90.0 \
--max_attempts 4 \
--log_to_file $B_NAME.VR_HC_indels.log

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
