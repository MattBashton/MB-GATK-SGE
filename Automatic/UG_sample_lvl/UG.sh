#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 5
#$ -l h_vmem=30G
#$ -l h_rt=120:00:0
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs the UnifiedGenotyper, -dcov from global settings file.
# This script runs the UnifiedGenotyper in a per sample way
# against a bam file from $SGE_TASK_ID in automated pipeline.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=$(basename $G_NAME.$SGE_TASK_ID.dedup.realigned.recalibrated.bam .bam)
#╔======================================================================╗
#║ WARNING this script will assume all runs have unique SM: sample IDs! ║
#╚======================================================================╝
SAMP_ID=$(awk "NR==$SGE_TASK_ID" ../master_list.txt | perl -ne '/SM:(\S+)\\t/; print "$1\n"')

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - G_NAME = $G_NAME"
echo " - B_NAME = $B_NAME"
echo " - SAMP_ID = $SAMP_ID"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/BQSR_sample_lvl/$G_NAME.$SGE_TASK_ID.dedup.realigned.recalibrated.* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/BQSR_sample_lvl/$G_NAME.$SGE_TASK_ID.dedup.realigned.recalibrated.bam $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/BQSR_sample_lvl/$G_NAME.$SGE_TASK_ID.dedup.realigned.recalibrated.bai $TMPDIR

echo "Running GATK UnifiedGenotyper to call snps"
/usr/bin/time --verbose $JAVA -Xmx24g -jar $GATK \
-T UnifiedGenotyper \
-dcov $DCOV \
-nt 5 \
$INTERVALS \
--interval_padding $PADDING \
-I $TMPDIR/$B_NAME.bam \
--dbsnp $DBSNP \
-R $REF \
-stand_emit_conf 30 \
-stand_call_conf 30 \
--max_alternate_alleles 50 \
--genotype_likelihoods_model SNP \
-o $TMPDIR/$SAMP_ID.UG_snps.vcf \
--log_to_file $SAMP_ID.UG_snps.log

echo "Running GATK UnifiedGenotyper to call indels"
/usr/bin/time --verbose $JAVA -Xmx24g -jar $GATK \
-T UnifiedGenotyper \
-dcov $DCOV \
-nt 5 \
$INTERVALS \
--interval_padding $PADDING \
-I $TMPDIR/$B_NAME.bam \
--dbsnp $DBSNP \
-R $REF \
-stand_emit_conf 30 \
-stand_call_conf 30 \
--max_alternate_alleles 50 \
--genotype_likelihoods_model INDEL \
-o $TMPDIR/$SAMP_ID.UG_indels.vcf \
--log_to_file $SAMP_ID.UG_indels.log

echo "Copying output TMPDIR/$SAMP_ID.*.vcf to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.*.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.*.vcf.idx $PWD

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

echo "Deleting $TMPDIR/$SAMP_ID.*"
rm $TMPDIR/$SAMP_ID.*

date
echo "END"
