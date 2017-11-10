#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=10G
#$ -l h_rt=4:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs Select Variants to filter with pre set cut-offs, this script is for HC
# data.  Note will get errors for undefined variables this is normal not all
# sites have all variables depending on zygosity.  Updated with SOR filters from:
# https://www.broadinstitute.org/gatk/guide/article?id=3225

# Modified to prevent missing values from PASSing variants by splitting each
# filter so that they can individually fail rather than a single failing
# subexpression in JEXL causing a pass.  See:
# http://gatkforums.broadinstitute.org/gatk/discussion/2334/undefined-variable-variantfiltration

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


echo "1) SNP extraction from VCF"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $REF \
--out $TMPDIR/$B_NAME.HC_snps.vcf \
-selectType SNP -selectType MNP \
--log_to_file $B_NAME.HC_SelectVariants_snps.log


echo "2) Applying filter to raw SNP call set"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T VariantFiltration \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.HC_snps.vcf \
-R $REF \
--out $TMPDIR/$B_NAME.HC_filtered_snps.vcf \
--filterExpression "QD < 2.0"  --filterName "QD" \
--filterExpression "MQ < 40.0" --filterName "MQ" \
--filterExpression "FS > 60.0" --filterName "FS" \
--filterExpression "SOR > 3.0" --filterName "SOR" \
--filterExpression "MQRankSum < -12.5" --filterName "MQRankSum" \
--filterExpression "ReadPosRankSum < -8.0" --filterName "ReadPosRankSum" \
--log_to_file $B_NAME.HC_VariantFiltration_snps.vcf.log


echo "3) Extracting PASSing SNPs"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.HC_filtered_snps.vcf \
-R $REF \
--out $TMPDIR/$B_NAME.HC_filtered_snps.PASS.vcf \
-select "vc.isNotFiltered()" \
--log_to_file $B_NAME.SelectRecaledVariants.HC_filtered_snps.PASS.log


echo "4) Indel extraction from VCF"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $REF \
--out $TMPDIR/$B_NAME.HC_indels.vcf \
-selectType INDEL -selectType MIXED -selectType SYMBOLIC \
--log_to_file $B_NAME.HC_SelectVariants_indels.log


echo "5) Applying filter to raw indel call set"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T VariantFiltration \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.HC_indels.vcf \
-R $REF \
--out $TMPDIR/$B_NAME.HC_filtered_indels.vcf \
--filterExpression "QD < 2.0" --filterName "QD" \
--filterExpression "ReadPosRankSum < -20.0" --filterName "ReadPosRankSum" \
--filterExpression "FS > 200.0" --filterName "FS" \
--filterExpression "SOR > 10.0" --filterName "SOR" \
--log_to_file $B_NAME.HC_VariantFiltration_indel.vcf.log


echo "6) Extracting PASSing indels"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.HC_filtered_indels.vcf \
-R $REF \
--out $TMPDIR/$B_NAME.HC_filtered_indels.PASS.vcf \
-select "vc.isNotFiltered()" \
--log_to_file $B_NAME.SelectRecaledVariants.HC_filtered_indels.PASS.log


echo "Copying back output $TMPDIR/$B_NAME.HC_filtered_*vcf and $TMPDIR/$B_NAME.HC_filtered_*idx to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.HC_filtered_*vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.HC_filtered_*idx $PWD

echo "Deleting $TMPDIR/$B_NAME*"
rm $TMPDIR/$B_NAME*

date
echo "END"
