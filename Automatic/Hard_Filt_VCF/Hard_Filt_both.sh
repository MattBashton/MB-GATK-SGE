#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=10G
#$ -l h_rt=4:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Applies hard filters from GATK best practices
# https://www.broadinstitute.org/gatk/guide/article?id=2806 to call set, this
# is useful when VQSR has failed owing to not enough bad variation as is often
# the case with targeted panels. Updated with SOR filters from:
# https://www.broadinstitute.org/gatk/guide/article?id=3225

# Modified to prevent missing values from PASSing variants by splitting each
# filter so that they can individually fail rather than a single failing
# subexpression in JEXL causing a pass.  See:
# http://gatkforums.broadinstitute.org/gatk/discussion/2334/undefined-variable-variantfiltration

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $G_NAME.HC_genotyped.vcf .vcf`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - G_NAME = $G_NAME"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/GenotypeGVCFs/$G_NAME.HC_genotyped.vcf* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/GenotypeGVCFs/$G_NAME.HC_genotyped.vcf $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/GenotypeGVCFs/$G_NAME.HC_genotyped.vcf.idx $TMPDIR

echo "1) SNP extraction from VCF"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $REF \
--out $TMPDIR/$G_NAME.Hard_snps.vcf \
-selectType SNP \
--log_to_file $G_NAME.Hard_SelectVariants_snps.log


echo "2) Applying filter to raw SNP call set"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T VariantFiltration \
--downsampling_type NONE \
--variant $TMPDIR/$G_NAME.Hard_snps.vcf \
-R $REF \
--out $TMPDIR/$G_NAME.Hard_filtered_snps.vcf \
--filterExpression "QD < 2.0"  --filterName "QD" \
--filterExpression "MQ < 40.0" --filterName "MQ" \
--filterExpression "FS > 60.0" --filterName "FS" \
--filterExpression "SOR > 4.0" --filterName "SOR" \
--filterExpression "MQRankSum < -12.5" --filterName "MQRankSum" \
--filterExpression "ReadPosRankSum < -8.0" --filterName "ReadPosRankSum" \
--log_to_file $G_NAME.Hard_VariantFiltration_snps.vcf.log


echo "3) Extracting PASSing SNPs"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$G_NAME.Hard_filtered_snps.vcf \
-R $REF \
--out $TMPDIR/$G_NAME.Hard_filtered_snps.PASS.vcf \
-select "vc.isNotFiltered()" \
--log_to_file $G_NAME.SelectRecaledVariants.Hard_filtered_snps.PASS.log


echo "4) Indel extraction from VCF"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $REF \
--out $TMPDIR/$G_NAME.Hard_indels.vcf \
-selectType INDEL \
--log_to_file $G_NAME.Hard_SelectVariants_indels.log


echo "5) Applying filter to raw indel call set"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T VariantFiltration \
--downsampling_type NONE \
--variant $TMPDIR/$G_NAME.Hard_indels.vcf \
-R $REF \
--out $TMPDIR/$G_NAME.Hard_filtered_indels.vcf \
--filterExpression "QD < 2.0" --filterName "QD" \
--filterExpression "ReadPosRankSum < -20.0" --filterName "ReadPosRankSum" \
--filterExpression "FS > 200.0" --filterName "FS" \
--filterExpression "SOR > 10.0" --filterName "SOR" \
--log_to_file $G_NAME.Hard_VariantFiltration_indel.vcf.log


echo "6) Extracting PASSing indels"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$G_NAME.Hard_filtered_indels.vcf \
-R $REF \
--out $TMPDIR/$G_NAME.Hard_filtered_indels.PASS.vcf \
-select "vc.isNotFiltered()" \
--log_to_file $G_NAME.SelectRecaledVariants.Hard_filtered_indels.PASS.log


echo "Copying back output $TMPDIR/$G_NAME.Hard_filtered_*.vc* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$G_NAME.Hard_filtered_snps.PASS.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$G_NAME.Hard_filtered_snps.PASS.vcf.idx $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$G_NAME.Hard_filtered_indels.PASS.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$G_NAME.Hard_filtered_indels.PASS.vcf.idx $PWD

echo "Deleting $TMPDIR/$G_NAME*"
rm $TMPDIR/$G_NAME*

date
echo "END"
