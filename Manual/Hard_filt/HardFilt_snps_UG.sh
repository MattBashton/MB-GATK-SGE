#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=8G
#$ -l h_rt=4:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs Select Variants to filter with pre set cut-offs, this script is for UG
# SNP data.  Note will get errors for undefined variables this is normal not all
# sites have all variables depending on zygosity.

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

echo "UG called SNPs separately - skip SNP extraction from VCF"

echo "Applying filter to raw SNP call set"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T VariantFiltration \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $BUNDLE_DIR/$REF \
--out $TMPDIR/$B_NAME.UG_filtered_snps.vcf \
--filterExpression "QD < 2.0 || FS > 60.0 || MQ < 40.0 || HaplotypeScore > 13.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0" \
--filterName "GATK_BP_snp_filter" \
--log_to_file $B_NAME.UG_VariantFiltration_snps.vcf.log

echo "Extracting PASSing variants"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.UG_filtered_snps.vcf \
-R $BUNDLE_DIR/$REF \
--out $TMPDIR/$B_NAME.UG_filtered_snps.PASS.vcf \
-select "vc.isNotFiltered()" \
--log_to_file $B_NAME.SelectRecaledVariants.UG_filtered_snps.PASS.log

echo "Copying back output $TMPDIR/$B_NAME.*PASS.vcf and $B_NAME.*PASS.vcf.idx to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.*PASS.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.*PASS.vcf.idx $PWD

echo "Deleting $TMPDIR/$B_NAME*"
rm $TMPDIR/$B_NAME*

date
echo "END"
