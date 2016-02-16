#!/bin/bash -e
#$ -cwd -V
#$ -l h_vmem=6G
#$ -pe smp 2
#$ -l h_rt=24:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016                                                                                                                                                                                                        
# Takes a list of .bam files passed in via <path_to_files>/*.bam at command line
# and runs Picard tools MergeSamFiles on them.  Uses threading option in Picard
# which off loads IO/(de)compression to another tread ~ 20% faster.

set -o pipefail
hostname
date

source ../GATKsettings.sh

# .bam passed at command line via *.bam
# Need to strip out leading file path and insert Picard input arg for each file

BAMS="$*"
for x in $BAMS
do
    B_NAME=`basename $x`
    TMP=`echo "$B_NAME" | perl -ne '/^(\S+)$/; print "INPUT=$1"'`
    BAM_LIST="$BAM_LIST $TMP"
done

BAM_DIR=`dirname $1`
DEST=$PWD

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - BAM_DIR = $BAM_DIR"
echo " - PWD = $PWD"
echo " - BAM_LIST = $BAM_LIST"
echo " - DEST = $DEST"

echo "Copying input *.bam and *.bai to $TMPDIR"
for x in $BAMS
do
    B_NAME=`basename $x .bam`
    echo "Copying $BAM_DIR/$B_NAME.bam to $TMPDIR"
    /usr/bin/time --verbose cp -v $BAM_DIR/$B_NAME.bam $TMPDIR
    /usr/bin/time --verbose cp -v $BAM_DIR/$B_NAME.bai $TMPDIR
done

echo "Running Picard to merge BAM list"
cd $TMPDIR
/usr/bin/time --verbose $JAVA -Xmx4g -XX:ParallelGCThreads=2 \
-jar $PICARD MergeSamFiles \
$BAM_LIST \
OUTPUT=Dedup.Realigned.Merged.bam \
MAX_RECORDS_IN_RAM=8000000 \
USE_THREADING=true \
SORT_ORDER=coordinate \
CREATE_INDEX=true \
VALIDATION_STRINGENCY=LENIENT
cd $DEST

echo "Copying back merged BAM and index output to $DEST"
/usr/bin/time --verbose cp -v $TMPDIR/Dedup.Realigned.Merged.bam $DEST
/usr/bin/time --verbose cp -v $TMPDIR/Dedup.Realigned.Merged.bai $DEST

echo "Removing *.ba* from $TMPDIR"
rm $TMPDIR/*.ba*

date
echo "END"
