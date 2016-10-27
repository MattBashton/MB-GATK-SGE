#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=30G
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

# Get info for pair using task id from array job
LINE=$(awk "NR==$SGE_TASK_ID" $MUTECT_LIST)
set $LINE
RUN_ID=$1
NORMAL=$2
TUMOUR=$3

# Make output name for this run
OUTPUT=$NORMAL.vs.$TUMOUR

#Input file path
INPUT_DIR="../Merge_MuTect1_pairs"

echo "** Variables **"
echo " - PWD = $PWD"
echo " - NORMAL = $NORMAL"
echo " - TUMOUR = $TUMOUR"
echo " - G_NAME = $G_NAME"
echo " - INPUT_DIR = $INPUT_DIR"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - OUTPUT = $OUTPUT"

echo "Copying normal input $INPUT_DIR/$OUTPUT.dedup.realigned.merged.ba* to $TMPDIR/"
/usr/bin/time --verbose cp -v $INPUT_DIR/$OUTPUT.dedup.realigned.merged.bam $TMPDIR
/usr/bin/time --verbose cp -v $INPUT_DIR/$OUTPUT.dedup.realigned.merged.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx24g -jar $GATK \
-T IndelRealigner \
--maxReadsInMemory 10000000 \
--maxReadsForRealignment 10000000 \
--maxConsensuses 300 \
--maxReadsForConsensuses 1200 \
-known $MILLS_1KG_GOLD \
-known $PHASE1_INDELS \
-I $TMPDIR/$OUTPUT.dedup.realigned.merged.bam \
-R $REF \
-targetIntervals $OUTPUT.RTC.intervals \
-o $TMPDIR/$OUTPUT.merged.realigned.bam \
-LOD 0.4 \
--log_to_file $OUTPUT.IndelRealigner.log

echo "Copying $TMPDIR/$OUTPUT.merged.realigned.ba* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$OUTPUT.merged.realigned.bam $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$OUTPUT.merged.realigned.bai $PWD

echo "Deleting $TMPDIR/$OUTPUT.*"
rm $TMPDIR/$OUTPUT.*

date
echo "END"
