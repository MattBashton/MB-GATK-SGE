#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=24G
#$ -l h_rt=120:00:0
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs the HC against a bam file from $SGE_TASK_ID in automated pipeline.
# This uses the classic mode of HC operation outputting standard VCF files.
# New vectorised Pair-HMM engine using AVX disables parallelisation so -pe smp
# set to 1.  5 days run time allocated, change if need be.
#
# SAMP_NAME is used to shorten output file names removing the various stages
# from file name at this point if that causes issues fallback to B_NAME or
# edit line.  Have set max alt alleles higher than default.  Using PCR
# --pcr_indel_model CONSERVATIVE is use - set to NONE for WGS.
# --maxReadsInRegionPerSample defaults to 10000 for the active region changed
# in GATKsettings.sh $MAX_READS_IN_REGION - Note now disabled!
# See GATKsettings.sh for notes on this.

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

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx18g -jar $GATK \
-T HaplotypeCaller \
--pcr_indel_model $PCR \
-nct 1 \
$INTERVALS \
--interval_padding $PADDING \
-I $TMPDIR/$B_NAME.bam \
--dbsnp $DBSNP \
-R $REF \
--max_alternate_alleles 50 \
-o $TMPDIR/$SAMP_ID.HC.vcf \
--bamOutput $TMPDIR/$SAMP_ID.HC.bam \
-stand_call_conf 30 \
-stand_emit_conf 30 \
--log_to_file $SAMP_ID.log

echo "Copying output TMPDIR/$SAMP_ID.HC.vcf* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.HC.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.HC.vcf.idx $PWD

echo "Copying output TMPDIR/$SAMP_ID.HC.ba* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.HC.bam $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.HC.bai $PWD

echo "Deleting $TMPDIR/$SAMP_ID.*"
rm $TMPDIR/$SAMP_ID.*

echo "Deleting $TMPDIR/$G_NAME.*"
rm $TMPDIR/$G_NAME.*

date
echo "END"
