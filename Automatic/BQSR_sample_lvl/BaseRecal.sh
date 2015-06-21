#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 5
#$ -l h_vmem=22G
#$ -l h_rt=24:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs BaseRecalibrator needs an input .bam file, output is the Recal_data.grp
# file.
# Using -L intervals from kit will ensure off target reads are not used for
# Recalibration, 100bp padding should also be used on these.
# Output is .grp file 

set -o pipefail

hostname
date

source ../GATKsettings.sh

B_NAME=`basename $G_NAME.$SGE_TASK_ID.dedup.realigned.bam .bam`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/1stRealn/$G_NAME.$SGE_TASK_ID.dedup.realigned.* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/1stRealn/$G_NAME.$SGE_TASK_ID.dedup.realigned.bam $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/1stRealn/$G_NAME.$SGE_TASK_ID.dedup.realigned.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx18g -jar $GATK \
-T BaseRecalibrator \
-nct 5 \
$INTERVALS \
--interval_padding $PADDING \
-I $TMPDIR/$B_NAME.bam \
-knownSites $BUNDLE_DIR/dbsnp_138.hg19.vcf \
-knownSites $BUNDLE_DIR/Mills_and_1000G_gold_standard.indels.hg19.vcf \
-knownSites $BUNDLE_DIR/1000G_phase1.indels.hg19.vcf \
-R $BUNDLE_DIR/ucsc.hg19.fasta \
-o $TMPDIR/$B_NAME.Recal_data.grp \
--log_to_file $B_NAME.BaseRecal.log

echo "Deleting $TMPDIR/$B_NAME.bam"
rm $TMPDIR/$B_NAME.ba*

echo "Copying $TMPDIR/$B_NAME.Recal_data.grp to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.Recal_data.grp $PWD

date
echo "END"
