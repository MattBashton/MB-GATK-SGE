#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_rt=24:00:00
#$ -l h_vmem=20G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs CollectInsertSizeMetrics, note that -XX:ParallelGCThreads=1 is needed to prevent
# Picard using all the threads on a node.  Default runtime is 24hrs.  Not part of default
# pipeline.

set -o pipefail
hostname
date

source ../GATKsettings.sh

SAMP_ID=$(awk "NR==$SGE_TASK_ID" ../master_list.txt | perl -ne '/SM:(\S+)\\t/; print "$1\n"')
B_NAME=$(basename $G_NAME.$SGE_TASK_ID.dedup.bam .bam)

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - SAMP_ID = $SAMP_ID"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/MarkDuplicates/$G_NAME.$SGE_TASK_ID.dedup.ba* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/MarkDuplicates/$G_NAME.$SGE_TASK_ID.dedup.bam $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/MarkDuplicates/$G_NAME.$SGE_TASK_ID.dedup.bai $TMPDIR

echo "Running CollectInsertSizeMetrics for $B_NAME.bam"
/usr/bin/time --verbose $JAVA -Xmx16g -XX:ParallelGCThreads=1 -jar $PICARD CollectInsertSizeMetrics \
INPUT=$TMPDIR/$B_NAME.bam \
OUTPUT=$TMPDIR/$B_NAME.CollectInsertSizeMetrics.txt \
HISTOGRAM_FILE=$TMPDIR/$B_NAME.CollectInsertSizeMetrics.pdf \
TMP_DIR=$TMPDIR \
VALIDATION_STRINGENCY=STRICT \
MAX_RECORDS_IN_RAM=4000000

echo "Copying $TMPDIR/$B_NAME.CollectInsertSizeMetrics.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.CollectInsertSizeMetrics.* $PWD

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
