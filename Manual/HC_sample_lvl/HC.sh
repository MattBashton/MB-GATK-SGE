#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=20G
#$ -l h_rt=120:00:0
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs the HC against bam file passed in from command line.
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
# in GATKsettings.sh $MAX_READS_IN_REGION

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $1 .bam`
D_NAME=`dirname $1`
B_PATH_NAME=$D_NAME/$B_NAME
SAMP_NAME=`echo $B_NAME | cut -d'.' -f1`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - B_PATH_NAME = $B_PATH_NAME"
echo " - SAMP_NAME = $SAMP_NAME"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - PWD = $PWD"

echo "Copying input $B_PATH_NAME.* to $TMPDIR"
/usr/bin/time --verbose cp -v $B_PATH_NAME.bam $TMPDIR
/usr/bin/time --verbose cp -v $B_PATH_NAME.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx16g -jar $GATK \
-T HaplotypeCaller \
--maxReadsInRegionPerSample $MAX_READS_IN_REGION \
--pcr_indel_model $PCR \
-nct 1 \
--emitRefConfidence GVCF \
$INTERVALS \
--interval_padding $PADDING \
-I $TMPDIR/$B_NAME.bam \
--dbsnp $BUNDLE_DIR/dbsnp_138.hg19.vcf \
-R $BUNDLE_DIR/ucsc.hg19.fasta \
--max_alternate_alleles 50 \
-o $TMPDIR/$SAMP_NAME.HC.g.vcf \
--log_to_file $SAMP_NAME.HC.log

echo "Copying output TMPDIR/$SAMP_NAME.HC.g.vcf* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_NAME.HC.g.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_NAME.HC.g.vcf.idx $PWD

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

echo "Deleting $TMPDIR/$SAMP_NAME.*"
rm $TMPDIR/$SAMP_NAME.*

date
echo "END"
