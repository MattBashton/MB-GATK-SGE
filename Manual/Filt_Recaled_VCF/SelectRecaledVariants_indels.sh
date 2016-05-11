#!/bin/bash -eu
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

echo "Running GATK VQSLOD >= 0.00"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $REF \
--out $TMPDIR/$B_NAME.VQSlod_gr_eq_zero.vcf \
-select "VQSLOD >= 0.00" \
-selectType INDEL -selectType MIXED -selectType SYMBOLIC \
--log_to_file $B_NAME.SelectRecaledVariants.VQSlod_gr_eq_zero.log

echo "Running GATK VQSLOD >= 3.00"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $REF \
--out $TMPDIR/$B_NAME.VQSlod_gr_eq_three.vcf \
-select "VQSLOD >= 3.00" \
-selectType INDEL -selectType MIXED -selectType SYMBOLIC \
--log_to_file $B_NAME.SelectRecaledVariants.VQSlod_gr_eq_three.log

echo "Running GATK outputing PASSing variants"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $REF \
--out $TMPDIR/$B_NAME.PASS.vcf \
--excludeFiltered \
-selectType INDEL -selectType MIXED -selectType SYMBOLIC \
--log_to_file $B_NAME.SelectRecaledVariants.PASS.log

echo "Copying back output $TMPDIR/$B_NAME.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.*.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.*.vcf.idx $PWD

echo "Deleting $TMPDIR/$B_NAME*"
rm $TMPDIR/$B_NAME*

date
echo "END"
