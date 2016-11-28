#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 2
#$ -l h_rt=24:00:00
#$ -l h_vmem=8G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs Picard MergeSamFiles in automated pipeline works on merger_list.txt
# this is a tab delimited file, the second column is a comma separated list of
# input run numbers such as 1,2 which expands and corresponds to the input file
# names: $G_NAME.SGE_TASK_ID.bam.  The first column corresponds to a new
# new $SGE_TASK_ID or run ID of the merged Bam file such that an array job can
# be run on the new merged set.  Note master_list.txt needs to be updated
# accordingly where the first column should now correspond to the $NEW_RUN_ID
# and thus $SGE_TASK_ID of per-sample BAM post merger

set -o pipefail
hostname
date

source ../GATKsettings.sh

# Merger list
MERGE_LIST="../merger_list.txt"

# Get info for pair using task id from array job
LINE=$(awk "NR==$SGE_TASK_ID" $MERGE_LIST)
set $LINE
TOMERGE=$2
NEW_RUN_ID=$1
DEST=$PWD

# Input file path
INPUT_DIR="../SamToSortedBam"

# Input $G_NAME if different from current global setting change below
IN_G_NAME=$G_NAME

# Output name
OUTPUT=$G_NAME.$NEW_RUN_ID

# Output dir Bacause output may have same name as input and both are in $TMPDIR
OUTPUT_DIR=$TMPDIR/output
mkdir $OUTPUT_DIR

# Get input file names from $TOMERGE
IFS=','
MERGE_LIST=($TOMERGE)
unset IFS

# Make $INPUT string
INPUT=""
for x in ${MERGE_LIST[@]}
do
    INPUT="$INPUT INPUT=$TMPDIR/$IN_G_NAME.$x.bam"
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

echo "Running Picard MergeSamFiles on $INPUT and saving to $OUTPUT_DIR/$OUTPUT.bam"
cd $TMPDIR
/usr/bin/time --verbose $JAVA -Xmx4g -XX:ParallelGCThreads=2 \
-jar $PICARD MergeSamFiles \
$INPUT \
OUTPUT=$OUTPUT_DIR/$OUTPUT.bam \
TMP_DIR=$TMPDIR \
MAX_RECORDS_IN_RAM=8000000 \
USE_THREADING=true \
SORT_ORDER=coordinate \
CREATE_INDEX=true \
VALIDATION_STRINGENCY=STRICT
cd $DEST

echo "Copying $OUTPUT_DIR/$OUTPUT.ba* to $PWD"
/usr/bin/time --verbose cp $OUTPUT_DIR/$OUTPUT.bam $PWD
/usr/bin/time --verbose cp $OUTPUT_DIR/$OUTPUT.bai $PWD

echo "Deleting $TMPDIR/*.ba*"
rm $TMPDIR/*.ba*

echo "Deleting $OUTPUT_DIR"
rm -rf $OUTPUT_DIR

date
echo "END"
