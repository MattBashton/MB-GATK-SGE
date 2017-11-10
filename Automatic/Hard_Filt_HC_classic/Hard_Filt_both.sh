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

# Make sure matplotlib works on FMS cluster
module add apps/python27/2.7.8
module add libs/python/numpy/1.9.1-python27-2.7.8
module add libs/python/matplotlib/1.3.1-python27

#╔======================================================================╗
#║ WARNING this script will assume all runs have unique SM: sample IDs! ║
#╚======================================================================╝
SAMP_ID=$(awk "NR==$SGE_TASK_ID" ../master_list.txt | perl -ne '/SM:(\S+)\\t/; print "$1\n"')
DEST=$PWD

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - G_NAME = $G_NAME"
echo " - SAMP_ID = $SAMP_ID"
echo " - G_NAME = $G_NAME"
echo " - PWD = $PWD"
echo " - DEST = $DEST"

echo "Copying input $BASE_DIR/HC_classic/$SAMP_ID.HC.vcf* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/HC_classic/$SAMP_ID.HC.vcf $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/HC_classic/$SAMP_ID.HC.vcf.idx $TMPDIR


echo "1) SNP extraction from VCF"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$SAMP_ID.HC.vcf \
-R $REF \
--out $TMPDIR/$SAMP_ID.HC.Hard_snps.vcf \
-selectType SNP -selectType MNP \
--log_to_file $SAMP_ID.HC.Hard_SelectVariants_snps.log


echo "2) Applying filter to raw SNP call set"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T VariantFiltration \
--downsampling_type NONE \
--variant $TMPDIR/$SAMP_ID.HC.Hard_snps.vcf \
-R $REF \
--out $TMPDIR/$SAMP_ID.HC.Hard_filtered_snps.vcf \
--filterExpression "QD < 2.0"  --filterName "QD" \
--filterExpression "MQ < 40.0" --filterName "MQ" \
--filterExpression "FS > 60.0" --filterName "FS" \
--filterExpression "SOR > 3.0" --filterName "SOR" \
--filterExpression "MQRankSum < -12.5" --filterName "MQRankSum" \
--filterExpression "ReadPosRankSum < -8.0" --filterName "ReadPosRankSum" \
--log_to_file $SAMP_ID.HC.Hard_VariantFiltration_snps.vcf.log


echo "3) Extracting PASSing SNPs"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$SAMP_ID.HC.Hard_filtered_snps.vcf \
-R $REF \
--out $TMPDIR/$SAMP_ID.HC.Hard_filtered_snps.PASS.vcf \
-select "vc.isNotFiltered()" \
--log_to_file $SAMP_ID.HC.SelectRecaledVariants.Hard_filtered_snps.PASS.log


echo "4) Indel extraction from VCF"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$SAMP_ID.HC.vcf \
-R $REF \
--out $TMPDIR/$SAMP_ID.HC.Hard_indels.vcf \
-selectType INDEL -selectType MIXED -selectType SYMBOLIC \
--log_to_file $SAMP_ID.HC.Hard_SelectVariants_indels.log


echo "5) Applying filter to raw indel call set"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T VariantFiltration \
--downsampling_type NONE \
--variant $TMPDIR/$SAMP_ID.HC.Hard_indels.vcf \
-R $REF \
--out $TMPDIR/$SAMP_ID.HC.Hard_filtered_indels.vcf \
--filterExpression "QD < 2.0" --filterName "QD" \
--filterExpression "ReadPosRankSum < -20.0" --filterName "ReadPosRankSum" \
--filterExpression "FS > 200.0" --filterName "FS" \
--filterExpression "SOR > 10.0" --filterName "SOR" \
--log_to_file $SAMP_ID.HC.Hard_VariantFiltration_indel.vcf.log


echo "6) Extracting PASSing indels"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$SAMP_ID.HC.Hard_filtered_indels.vcf \
-R $REF \
--out $TMPDIR/$SAMP_ID.HC.Hard_filtered_indels.PASS.vcf \
-select "vc.isNotFiltered()" \
--log_to_file $SAMP_ID.HC.SelectRecaledVariants.Hard_filtered_indels.PASS.log


echo "Copying back output $TMPDIR/$SAMP_ID.HC.Hard_filtered_*.vc* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.HC.Hard_filtered_snps.*vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.HC.Hard_filtered_snps.*idx $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.HC.Hard_filtered_indels.*vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.HC.Hard_filtered_indels.*idx $PWD


# Stats and Plots
echo "Calculating per sample stats with bcftools stats on SAMP_ID.HC.Hard_filtered_snps.PASS.vcf"
/usr/bin/time --verbose $BCFTOOLS stats $TMPDIR/$SAMP_ID.HC.Hard_filtered_snps.PASS.vcf > $TMPDIR/$SAMP_ID.HC.Hard_filtered_snps.PASS.stats
echo "Copying back bcftools stats output"
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.HC.Hard_filtered_snps.PASS.stats $PWD

echo "Calculating per sample stats with bcftools stats on $SAMP_ID.HC.Hard_filtered_indels.PASS.vcf"
/usr/bin/time --verbose $BCFTOOLS stats $TMPDIR/$SAMP_ID.HC.Hard_filtered_indels.PASS.vcf > $TMPDIR/$SAMP_ID.HC.Hard_filtered_indels.PASS.stats
echo "Copying back bcftools stats output"
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.HC.Hard_filtered_indels.PASS.stats $PWD

cd $TMPDIR
echo "Plotting stats with plot-vcfstats using $TMPDIR/$SAMP_ID.HC.Hard_filtered_snps.PASS.stats input"
/usr/bin/time --verbose $PLOTVCFSTATS -s -t "$SAMP_ID.snps" -p $SAMP_ID.snps $TMPDIR/$SAMP_ID.HC.Hard_filtered_snps.PASS.stats
echo "Copying back $DEST/${SAMP_ID}.snps/summary.pdf to $DEST/$DEST/${SAMP_ID}.snps_summary.pdf"
/usr/bin/time --verbose cp -v "$SAMP_ID.snps/summary.pdf" $DEST/${SAMP_ID}.snps_summary.pdf

echo "Plotting stats with plot-vcfstats using $TMPDIR/$SAMP_ID.HC.Hard_filtered_indels.PASS.stats input"
/usr/bin/time --verbose $PLOTVCFSTATS -s -t "$SAMP_ID.indels" -p $SAMP_ID.indels $TMPDIR/$SAMP_ID.HC.Hard_filtered_indels.PASS.stats
echo "Copying back $DEST/${SAMP_ID}.indels/summary.pdf to $DEST/${SAMP_ID}.indels_summary.pdf"
/usr/bin/time --verbose cp -v "$SAMP_ID.indels/summary.pdf" $DEST/${SAMP_ID}.indels_summary.pdf
cd $DEST


echo "Deleting $TMPDIR/$SAMP_ID.*"
rm -rf $TMPDIR/$SAMP_ID.*

date
echo "END"
