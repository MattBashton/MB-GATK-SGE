#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=42G
#$ -l h_rt=120:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
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
# https://www.broadinstitute.org/gatk/gatkdocs/org_broadinstitute_gatk_tools_walkers_indels_IndelRealigner.php

# Note that --consensusDeterminationModel USE_READS is actually default so I've
# Not set it explicitly.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $1 .bam`
D_NAME=`dirname $1`
B_PATH_NAME=$D_NAME/$B_NAME

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - B_PATH_NAME = $B_PATH_NAME"
echo " - PWD = $PWD"

echo "Copying input $B_PATH_NAME.* to $TMPDIR"
/usr/bin/time --verbose cp -v $B_PATH_NAME.bam $TMPDIR
/usr/bin/time --verbose cp -v $B_PATH_NAME.bai $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx38g -jar $GATK \
-T IndelRealigner \
--maxReadsInMemory 10000000 \
--maxReadsForRealignment 10000000 \
--maxConsensuses 300 \
--maxReadsForConsensuses 1200 \
-known $BUNDLE_DIR/$MILLS_1KG_GOLD\
-known $BUNDLE_DIR/$PHASE1_INDELS \
-I $TMPDIR/$B_NAME.bam \
-R $BUNDLE_DIR/$REF \
-targetIntervals $B_NAME.RTC.intervals \
-o $TMPDIR/$B_NAME.2ndRealigned.bam \
-LOD 0.4 \
--log_to_file $B_NAME.IndelRealigner.log

echo "Copying output $TMPDIR/$B_NAME.Realigned.Recalibrated_L.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.2ndRealigned.bam $PWD
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.2ndRealigned.bai $PWD

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
