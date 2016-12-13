#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 10
#$ -l h_vmem=42G
#$ -l h_rt=120:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs the Unified Genotyper on a merged BAM as per GATK 2.x best practices
# -dcov from global settings file.  5 days run time by default.

# Now using -newQual and default -stand_call_conf of 10, -stand_emit_conf is
# now deprecated as per GATK 3.7 see:
# https://software.broadinstitute.org/gatk/documentation/version-history

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=$(basename $1 .bam)
D_NAME=$(dirname $1)
B_PATH_NAME=$D_NAME/$B_NAME

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - B_PATH_NAME = $B_PATH_NAME"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - DCOV = $DCOV"
echo " - PWD = $PWD"

echo "Copying input $B_PATH_NAME.* to $TMPDIR"
/usr/bin/time --verbose cp -v $B_PATH_NAME.bam $TMPDIR
/usr/bin/time --verbose cp -v $B_PATH_NAME.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx38g -jar $GATK \
-T UnifiedGenotyper \
-dcov $DCOV \
-nt 10 \
$INTERVALS \
--interval_padding $PADDING \
-I $TMPDIR/$B_NAME.bam \
--dbsnp $DBSNP \
-R $REF \
-newQual \
--max_alternate_alleles 50 \
--genotype_likelihoods_model INDEL \
-o $TMPDIR/$B_NAME.UG_indels_ccQ10.vcf \
--log_to_file $B_NAME.UG_indels_ccQ10.log

echo "Copying output TMPDIR/$B_NAME.vcf* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.UG_indels_ccQ10.vcf $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.UG_indels_ccQ10.vcf.idx $PWD

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
