#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=8G
#$ -l h_rt=4:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs Select Variants on VCF to pull out sub sets with >= 0 VQSlod, >= 3 VQSlod
# and PASS flagged variants from the VQSR stage.  VQSlod >= 0 and >= 3 should be
# the better and even better set of variants from the recalibration stage, more 
# positive log odds ratio here means greater likelihood of true variant under 
# Gaussian mixture model used in recalibration.  The PASS set are all those that
# passed recalibration at the desired TS filter level.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $G_NAME.HC_genotyped.vrecal.snps.vcf .vcf`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/VQSR_HC/$G_NAME.HC_genotyped.vrecal.snps.vcf.idx to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/VQSR_HC/$G_NAME.HC_genotyped.vrecal.snps.vcf $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/VQSR_HC/$G_NAME.HC_genotyped.vrecal.snps.vcf.idx $TMPDIR

echo "Running GATK VQSLOD >= 0.00"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $BUNDLE_DIR/ucsc.hg19.fasta \
--out $TMPDIR/$G_NAME.snps.VQSlod_gr_eq_zero.vcf \
-select "VQSLOD >= 0.00" \
-selectType SNP \
--log_to_file $G_NAME.snps.SelectRecaledVariants.VQSlod_gr_eq_zero.log

echo "Running GATK VQSLOD >= 3.00"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $BUNDLE_DIR/ucsc.hg19.fasta \
--out $TMPDIR/$G_NAME.snps.VQSlod_gr_eq_three.vcf \
-select "VQSLOD >= 3.00" \
-selectType SNP \
--log_to_file $G_NAME.snps.SelectRecaledVariants.VQSlod_gr_eq_three.log

echo "Running GATK outputing PASSing variants"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $BUNDLE_DIR/ucsc.hg19.fasta \
--out $TMPDIR/$G_NAME.snps.PASS.vcf \
-select "vc.isNotFiltered()" \
-selectType SNP \
--log_to_file $G_NAME.snps.SelectRecaledVariants.PASS.log

echo "Copying back output $TMPDIR/$B_NAME.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$G_NAME.snps.*.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$G_NAME.snps.*.vcf.idx $PWD

echo "Deleting $TMPDIR/$G_NAME*"
rm $TMPDIR/$G_NAME*

date
echo "END"
