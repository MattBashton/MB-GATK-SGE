#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 2
#$ -l h_rt=24:00:00
#$ -l h_vmem=8G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs Picard MergeSamFiles in automated pipeline works on merger_list.txt
# this is a tab delimited file, the first column is a comma separated list of
# input run numbers such as 1,2 which expand and correspond to
# $G_NAME.SGE_TASK_ID.bam and a second column which corresponds to the new
# $SGE_TASK_ID or run ID of the merged Bam file such that an array job can
# be run on the new merged set.  Note master_list.txt needs to be updated
# accordingly where the first column should correspond to the $SGE_TASK_ID.

set -o pipefail
hostname
date

source ../GATKsettings.sh

# Merger list
MERGE_LIST="../merger_list.txt"

# Get info for pair using task id from array job
LINE=`awk "NR==$SGE_TASK_ID" $MERGE_LIST`
set $LINE
TOMERGE=$1
NEW_RUN_ID=$2
DEST=$PWD

# Input file path
INPUT_DIR="../SamToSortedBam"

# Input $G_NAME if different from current global setting change below
IN_G_NAME=$G_NAME

# Output name
OUTPUT=$G_NAME.$NEW_RUN_ID

# Get input file names from $TOMERGE
IFS=','
MERGE_LIST=($TOMERGE)
unset IFS

# Make $INPUT string
INPUT=""
for x in ${MERGE_LIST[@]}
do
    INPUT="$INPUT INPUT=$IN_G_NAME.$x.bam"
done

echo "** Variables **"
echo " - PWD = $PWD"
echo " - DEST = $DEST"
echo " - TOMERGE = $TOMERGE"
echo " - MERGE_LIST = ${MERGE_LIST[*]}"
echo " - NEW_RUN_ID = $NEW_RUN_ID"
echo " - IN_G_NAME = $IN_G_NAME"
echo " - G_NAME = $G_NAME"
echo " - INPUT_DIR = $INPUT_DIR"
echo " - INPUT = $INPUT"
echo " - OUTPUT = $OUTPUT"

# Copy all input BAM to $TMPDIR
for x in ${MERGE_LIST[@]}
do
    echo "Copying input file $INPUT_DIR/$IN_G_NAME.$x.ba* to $TMPDIR/"
    /usr/bin/time --verbose cp -v $INPUT_DIR/$IN_G_NAME.$x.bam $TMPDIR
    /usr/bin/time --verbose cp -v $INPUT_DIR/$IN_G_NAME.$x.bai $TMPDIR
done

echo "Running Picard MergeSamFiles on INPUT=$INPUT"
cd $TMPDIR
/usr/bin/time --verbose $JAVA -Xmx4g -XX:ParallelGCThreads=2 \
-jar $PICARD MergeSamFiles \
$INPUT \
OUTPUT=$OUTPUT.bam \
TMP_DIR=$TMPDIR \
MAX_RECORDS_IN_RAM=8000000 \
USE_THREADING=true \
SORT_ORDER=coordinate \
CREATE_INDEX=true \
VALIDATION_STRINGENCY=STRICT
cd $DEST

echo "Copying $TMPDIR/$OUTPUT.ba* to $PWD"
/usr/bin/time --verbose cp $TMPDIR/$OUTPUT.bam $PWD
/usr/bin/time --verbose cp $TMPDIR/$OUTPUT.bai $PWD

echo "Deleting $TMPDIR/*.ba*"
rm $TMPDIR/*.ba*

date
echo "END"
