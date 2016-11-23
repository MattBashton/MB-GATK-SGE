#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=10G
#$ -l h_rt=24:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Uses PrintReads to extract Tumour and Normal samples from a merged bam file.

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

# Input name for this run
INPUT=$NORMAL.vs.$TUMOUR

#Input file path
INPUT_DIR="../MuTect1_merged_BQSR"

echo "** Variables **"
echo " - PWD = $PWD"
echo " - NORMAL = $NORMAL"
echo " - TUMOUR = $TUMOUR"
echo " - INPUT_DIR = $INPUT_DIR"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - INPUT = $INPUT"

echo "Copying merged input $INPUT_DIR/$INPUT.merged.realigned.recalibrated.ba* to $TMPDIR/"
/usr/bin/time --verbose cp -v $INPUT_DIR/$INPUT.merged.realigned.recalibrated.bam $TMPDIR
/usr/bin/time --verbose cp -v $INPUT_DIR/$INPUT.merged.realigned.recalibrated.bai $TMPDIR

echo "Running GATK PrintReads and outputing reads from normal sample: $NORMAL"
/usr/bin/time --verbose $JAVA -Xmx6g -jar $GATK \
-T PrintReads \
-nct 1 \
--sample_name $NORMAL \
-I $TMPDIR/$INPUT.merged.realigned.recalibrated.bam \
-R $REF \
-o $TMPDIR/Normal.$NORMAL.$INPUT.bam \
--log_to_file Normal.$NORMAL.$INPUT.PrintReads.log

echo "Running GATK PrintReads and outputing reads from tumour sample: $TUMOUR"
/usr/bin/time --verbose $JAVA -Xmx6g -jar $GATK \
-T PrintReads \
-nct 1 \
--sample_name $TUMOUR \
-I $TMPDIR/$INPUT.merged.realigned.recalibrated.bam \
-R $REF \
-o $TMPDIR/Tumour.$TUMOUR.$INPUT.bam \
--log_to_file Tumour.$TUMOUR.$INPUT.PrintReads.log

echo "Copying $TMPDIR/Normal.$NORMAL.$INPUT.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/Normal.$NORMAL.$INPUT.bam $PWD
/usr/bin/time --verbose cp -v $TMPDIR/Normal.$NORMAL.$INPUT.bai $PWD

echo "Copying $TMPDIR/Tumour.$TUMOUR.$INPUT.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/Tumour.$TUMOUR.$INPUT.bam $PWD
/usr/bin/time --verbose cp -v $TMPDIR/Tumour.$TUMOUR.$INPUT.bai $PWD

echo "Deleting $TMPDIR/$INPUT.*"
rm $TMPDIR/$INPUT.*

echo "Deleting $TMPDIR/Normal.*"
rm $TMPDIR/Normal.*

echo "Deleting $TMPDIR/Tumour.*"
rm $TMPDIR/Tumour.*

date
echo "END"
