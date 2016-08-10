#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 2
#$ -l h_rt=24:00:00
#$ -l h_vmem=8G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs Picard MergeSamFiles in automated pipeline prior to joint realignment for
# MuTect1 run.  Needs MuTect2_pairs.txt in base dir which sets up pairs of
# sample (SM) names, also uses master_list.txt to workout corresponding .bam
# file for each sample.

set -o pipefail
hostname
date

source ../GATKsettings.sh

# Get info for pair using task id from array job
LINE=`awk "NR==$SGE_TASK_ID" $MUTECT_LIST`
set $LINE
RUN_ID=$1
NORMAL=$2
TUMOUR=$3
DEST=$PWD

# Make output name for this run
OUTPUT=$NORMAL.vs.$TUMOUR

# Get files for tumour and normal
ID_N=$(grep -P "SM:\K$NORMAL(?=\\\tPL)" $MASTER_LIST | awk '{print $1}')
ID_T=$(grep -P "SM:\K$TUMOUR(?=\\\tPL)" $MASTER_LIST | awk '{print $1}')
N_FILE="$G_NAME.$ID_N.dedup.realigned"
T_FILE="$G_NAME.$ID_T.dedup.realigned"

#Input file path
INPUT_DIR="../1stRealn"

echo "** Variables **"
echo " - PWD = $PWD"
echo " - DEST = $DEST"
echo " - NORMAL = $NORMAL"
echo " - TUMOUR = $TUMOUR"
echo " - G_NAME = $G_NAME"
echo " - INPUT_DIR = $INPUT_DIR"
echo " - N_FILE = $N_FILE"
echo " - T_FILE = $T_FILE"
echo " - OUTPUT = $OUTPUT"

echo "Copying normal input $INPUT_DIR/$N_FILE.ba* to $TMPDIR/"
/usr/bin/time --verbose cp -v $INPUT_DIR/$N_FILE.bam $TMPDIR
/usr/bin/time --verbose cp -v $INPUT_DIR/$N_FILE.bai $TMPDIR

echo "Copying tumour input $INPUT_DIR/$T_FILE.ba* to $TMPDIR/"
/usr/bin/time --verbose cp -v $INPUT_DIR/$T_FILE.bam $TMPDIR
/usr/bin/time --verbose cp -v $INPUT_DIR/$T_FILE.bai $TMPDIR

echo "Running Picard MergeSamFiles on normal:$N_FILE.bam and tumor:$T_FILE.bam"
cd $TMPDIR
/usr/bin/time --verbose $JAVA -Xmx4g -XX:ParallelGCThreads=2 \
-jar $PICARD MergeSamFiles \
INPUT=$N_FILE.bam \
INPUT=$T_FILE.bam \
OUTPUT=$OUTPUT.dedup.realigned.merged.bam \
TMP_DIR=$TMPDIR \
MAX_RECORDS_IN_RAM=8000000 \
USE_THREADING=true \
SORT_ORDER=coordinate \
CREATE_INDEX=true \
VALIDATION_STRINGENCY=STRICT
cd $DEST

echo "Copying $TMPDIR/$OUTPUT.dedup.realigned.merged.* to $PWD"
/usr/bin/time --verbose cp $TMPDIR/$OUTPUT.dedup.realigned.merged.bam $PWD
/usr/bin/time --verbose cp $TMPDIR/$OUTPUT.dedup.realigned.merged.bai $PWD

echo "Deleting $TMPDIR/$N_FILE.*"
rm $TMPDIR/$N_FILE.*

echo "Deleting $TMPDIR/$T_FILE.*"
rm $TMPDIR/$T_FILE.*

echo "Deleting $TMPDIR/$OUTPUT.*"
rm $TMPDIR/$OUTPUT.*

date
echo "END"
