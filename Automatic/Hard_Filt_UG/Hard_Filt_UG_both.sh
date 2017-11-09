#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=10G
#$ -l h_rt=4:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs Select Variants to filter with pre set cut-offs, this script is for UG
# SNP and indel data.  Note will get errors for undefined variables this is normal not
# all sites have all variables depending on zygosity.  Updated with SOR filters from:
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
SNPS=$SAMP_ID.UG_snps
INDELS=$SAMP_ID.UG_indels
DEST=$PWD

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - G_NAME = $G_NAME"
echo " - SAMP_ID = $SAMP_ID"
echo " - SNPS = $SNPS"
echo " - INDELS = $INDELS"
echo " - PWD = $PWD"
echo " - DEST = $DEST"

echo "Copying input $BASE_DIR/UG_sample_lvl/$SAMP_ID*.vcf* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/UG/$SAMP_ID.*.vcf $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/UG/$SAMP_ID.*.vcf.idx $TMPDIR

echo "UG called SNPs separately - skip SNP extraction from VCF"

echo "Applying filter to raw SNP call set"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T VariantFiltration \
--downsampling_type NONE \
--variant $TMPDIR/$SNPS.vcf \
-R $REF \
--out $TMPDIR/$SNPS.Hard_filtered.vcf \
--filterExpression "QD < 2.0"  --filterName "QD" \
--filterExpression "MQ < 40.0" --filterName "MQ" \
--filterExpression "FS > 60.0" --filterName "FS" \
--filterExpression "SOR > 3.0" --filterName "SOR" \
--filterExpression "MQRankSum < -12.5" --filterName "MQRankSum" \
--filterExpression "ReadPosRankSum < -8.0" --filterName "ReadPosRankSum" \
--filterExpression "HaplotypeScore > 13.0" --filterName "HaplotypeScore" \
--log_to_file $SNPS.Hard_VariantFiltration_snps.vcf.log

echo "Extracting PASSing variants"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$SNPS.Hard_filtered.vcf \
-R $REF \
--out $TMPDIR/$SNPS.Hard_filtered.PASS.vcf \
-select "vc.isNotFiltered()" \
--log_to_file $SNPS.SelectRecaledVariants.Hard_filtered.PASS.log


echo "UG called indels separately - skip indel extraction from VCF"

echo "Applying filter to raw indel call set"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T VariantFiltration \
--downsampling_type NONE \
--variant $TMPDIR/$INDELS.vcf \
-R $REF \
--out $TMPDIR/$INDELS.Hard_filtered.vcf \
--filterExpression "QD < 2.0" --filterName "QD" \
--filterExpression "ReadPosRankSum < -20.0" --filterName "ReadPosRankSum" \
--filterExpression "FS > 200.0" --filterName "FS" \
--filterExpression "SOR > 10.0" --filterName "SOR" \
--log_to_file $INDELS.Hard_filtered.vcf.log

echo "Extracting PASSing variants"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$INDELS.Hard_filtered.vcf \
-R $REF \
--out $TMPDIR/$INDELS.Hard_filtered.PASS.vcf \
-select "vc.isNotFiltered()" \
--log_to_file $INDELS.SelectRecaledVariants.Hard_filtered.PASS.log


echo "Copying back output $TMPDIR/$SNPS.Hard_filtered.*.vcf* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$SNPS.Hard_filtered.*.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$SNPS.Hard_filtered.*.vcf.idx $PWD

echo "Copying back output $TMPDIR/$INDELS.Hard_filtered.*.vcf* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$INDELS.Hard_filtered.*.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$INDELS.Hard_filtered.*.vcf.idx $PWD

# Stats and Plots
echo "Calculating per sample stats with bcftools stats on $SNPS.Hard_filtered.PASS.vcf"
/usr/bin/time --verbose $BCFTOOLS stats $TMPDIR/$SNPS.Hard_filtered.PASS.vcf > $TMPDIR/$SNPS.Hard_filtered.PASS.stats
echo "Copying back bcftools stats output"
/usr/bin/time --verbose cp -v $TMPDIR/$SNPS.Hard_filtered.PASS.stats $PWD

echo "Calculating per sample stats with bcftools stats on $INDELS.Hard_filtered.PASS.vcf"
/usr/bin/time --verbose $BCFTOOLS stats $TMPDIR/$INDELS.Hard_filtered.PASS.vcf > $TMPDIR/$INDELS.Hard_filtered.PASS.stats
echo "Copying back bcftools stats output"
/usr/bin/time --verbose cp -v $TMPDIR/$INDELS.Hard_filtered.PASS.stats $PWD

cd $TMPDIR
echo "Plotting stats with plot-vcfstats using $TMPDIR/$SAMP_ID.HC.Hard_filtered_snps.PASS.stats input"
/usr/bin/time --verbose $PLOTVCFSTATS -s -t "$SAMP_ID.snps" -p $SAMP_ID.snps $TMPDIR/$SAMP_ID.Hard_filtered_snps.PASS.stats
echo "Copying back $DEST/${SAMP_ID}.snps/summary.pdf to $DEST/$DEST/${SAMP_ID}.snps_summary.pdf"
/usr/bin/time --verbose cp -v "$SAMP_ID.snps/summary.pdf" $DEST/${SAMP_ID}.snps_summary.pdf

echo "Plotting stats with plot-vcfstats using $TMPDIR/$SAMP_ID.HC.Hard_filtered_indels.PASS.stats input"
/usr/bin/time --verbose $PLOTVCFSTATS -s -t "$SAMP_ID.indels" -p $SAMP_ID.indels $TMPDIR/$SAMP_ID.Hard_filtered_indels.PASS.stats
echo "Copying back $DEST/${SAMP_ID}.indels/summary.pdf to $DEST/${SAMP_ID}.indels_summary.pdf"
/usr/bin/time --verbose cp -v "$SAMP_ID.indels/summary.pdf" $DEST/${SAMP_ID}.indels_summary.pdf
cd $DEST


echo "Deleting $TMPDIR/$SAMP_ID*"
rm -rf $TMPDIR/$SAMP_ID*

date
echo "END"
