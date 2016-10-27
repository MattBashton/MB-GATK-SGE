#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=24G
#$ -l h_rt=48:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs Indel Realigner, needs an input .bam file and intervals file for
# realignment targets, outputs a new realigned .bam file.
# 24hrs run time by default.

# Note you may want to use lower maxReads* settings defaults are:
# maxReadsInMemory 150,000
# maxReadsForRealignment 20,000

# Using 10,000,000 which means all regions should pass, possible memory usage
# issue with very high depth.  Will lead to inc runtime too, lower if need be.

# Also decreased LOD threshold for setting off realignment process (cleaning)
# to 0.4 default is 5.0.  Smaller numbers are better when looking for indels
# with low allele frequency.  Lower LOD means realignment process is triggered
# more often, which will lead to increased run time.  If runtime critical
# inc LOD value.

# Perviously didn't restrict realignment with -L at RTC stage since off target
# spots sometimes can yeild good SNPs and don't want to restrict ability to use
# file for global calling if need be at later date.  However it's really not a
# good idea to call off target sites for exomes and also using -L for speed
# up, as will generate less targets for IDR.  Note you don't need -L here since
# RTC will have not generated targets outside interval ranges.

# maxConsensuses and maxReadsForConsensuses settings, should help with deep data
# - runtime could be long.  Both are x10 defaults.  Omit for defaults.
# GATK documentation now states inc these for better results on high
# depth data.
# https://www.broadinstitute.org/gatk/guide/tooldocs/org_broadinstitute_gatk_tools_walkers_indels_IndelRealigner.php

# Note that --consensusDeterminationModel USE_READS is actually default so I've
# Not set it explicitly.  See:
# http://gatkforums.broadinstitute.org/gatk/discussion/comment/20385#Comment_20385
# Advice on USE_READS and LOD:
# http://gatkforums.broadinstitute.org/gatk/discussion/38/local-realignment-around-indels

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=$(basename $G_NAME.$SGE_TASK_ID.dedup.bam .bam)

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/MarkDuplicates/$G_NAME.$SGE_TASK_ID.dedup.* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/MarkDuplicates/$G_NAME.$SGE_TASK_ID.dedup.bam $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/MarkDuplicates/$G_NAME.$SGE_TASK_ID.dedup.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx20g -jar $GATK \
-T IndelRealigner \
--maxReadsInMemory 10000000 \
--maxReadsForRealignment 10000000 \
--maxConsensuses 300 \
--maxReadsForConsensuses 1200 \
-known $MILLS_1KG_GOLD \
-known $PHASE1_INDELS \
-I $TMPDIR/$B_NAME.bam \
-R $REF \
-targetIntervals $B_NAME.RTC.intervals \
-o $TMPDIR/$B_NAME.realigned.bam \
-LOD 0.4 \
--log_to_file $B_NAME.IndelRealigner.log

echo "Copying output $TMPDIR/$B_NAME.realigned.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.realigned.bam $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.realigned.bai $PWD

echo "Deleting $TMPDIR/$B_NAME.realigned.*"
rm $TMPDIR/$B_NAME.realigned.*

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
