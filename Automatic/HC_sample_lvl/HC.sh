#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=24G
#$ -l h_rt=120:00:0
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs the HC against a bam file from $SGE_TASK_ID in automated pipeline.
# New vectorised Pair-HMM engine using AVX disables parallelisation so -pe smp
# set to 1.  5 days run time allocated, change if need be.
#
# SAMP_NAME is used to shorten output file names removing the various stages
# from file name at this point if that causes issues fallback to B_NAME or
# edit line.  Have set max alt alleles higher than default.
# In GATK 3.4 --variant_index_type LINEAR --variant_index_parameter 128000 won't
# be needed as long as .g.vcf is used.  In GVCF mode -stand_emit_conf and
# -stand_call_conf are both ignored and set to zero.  Also using PCR
# --pcr_indel_model CONSERVATIVE is use - set to NONE for WGS.
# --maxReadsInRegionPerSample defaults to 10000 for the active region changed
# in GATKsettings.sh $MAX_READS_IN_REGION - Note now disabled!
# See GATKsettings.sh for notes on this.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=$(basename $G_NAME.$SGE_TASK_ID.dedup.realigned.recalibrated.bam .bam)

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/BQSR_sample_lvl/$G_NAME.$SGE_TASK_ID.dedup.realigned.recalibrated.* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/BQSR_sample_lvl/$G_NAME.$SGE_TASK_ID.dedup.realigned.recalibrated.bam $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/BQSR_sample_lvl/$G_NAME.$SGE_TASK_ID.dedup.realigned.recalibrated.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx18g -jar $GATK \
-T HaplotypeCaller \
--pcr_indel_model $PCR \
--emitRefConfidence GVCF \
$INTERVALS \
--interval_padding $PADDING \
-I $TMPDIR/$B_NAME.bam \
--dbsnp $DBSNP \
-R $REF \
--max_alternate_alleles 50 \
-o $TMPDIR/${G_NAME}_${SGE_TASK_ID}_HC.g.vcf \
--bamOutput $TMPDIR/${G_NAME}_${SGE_TASK_ID}_HC.bam \
--log_to_file ${G_NAME}_${SGE_TASK_ID}_HC.log

echo "Copying output TMPDIR/${G_NAME}_${SGE_TASK_ID}_HC.g.vcf* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/${G_NAME}_${SGE_TASK_ID}_HC.g.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/${G_NAME}_${SGE_TASK_ID}_HC.g.vcf.idx $PWD

echo "Copying output TMPDIR/${G_NAME}_${SGE_TASK_ID}_HC.ba* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/${G_NAME}_${SGE_TASK_ID}_HC.bam $PWD
/usr/bin/time --verbose cp -v $TMPDIR/${G_NAME}_${SGE_TASK_ID}_HC.bai $PWD

echo "Deleting $TMPDIR/$G_NAME.*"
rm $TMPDIR/$G_NAME.*

date
echo "END"
