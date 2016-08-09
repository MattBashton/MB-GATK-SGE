#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_rt=120:00:00
#$ -l h_vmem=16G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs MuTect2 in automated pipeline
# Needs MuTect2_pairs.txt in base dir which sets up pairs of sample (SM) names,
# also uses master_list.txt to workout corresponding .bam file for each sample.

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

# Make output name for this run
OUTPUT=$NORMAL.vs.$TUMOUR

# Get files for tumour and normal
ID_N=$(grep -P "SM:\K$NORMAL(?=\\\tPL)" $MASTER_LIST | awk '{print $1}')
ID_T=$(grep -P "SM:\K$TUMOUR(?=\\\tPL)" $MASTER_LIST | awk '{print $1}')
N_FILE="$G_NAME.$ID_N.dedup.realigned.recalibrated"
T_FILE="$G_NAME.$ID_T.dedup.realigned.recalibrated"

#Input file path
INPUT_DIR="../BQSR_sample_lvl"

echo "** Variables **"
echo " - REF = $REF"
echo " - dbSNP = $DBSNP"
echo " - COSMIC = $COSMIC"
echo " - PWD = $PWD"
echo " - NORMAL = $NORMAL"
echo " - TUMOUR = $TUMOUR"
echo " - G_NAME = $G_NAME"
echo " - INPUT_DIR = $INPUT_DIR"
echo " - N_FILE = $N_FILE"
echo " - T_FILE = $T_FILE"
echo " - INTERVALS = $INTERVALS"
echo " - PADDING = $PADDING"
echo " - OUTPUT = $OUTPUT"

echo "Copying normal input $INPUT_DIR/$N_FILE.ba* to $TMPDIR/"
/usr/bin/time --verbose cp -v $INPUT_DIR/$N_FILE.bam $TMPDIR
/usr/bin/time --verbose cp -v $INPUT_DIR/$N_FILE.bai $TMPDIR

echo "Copying tumour input $INPUT_DIR/$T_FILE.ba* to $TMPDIR/"
/usr/bin/time --verbose cp -v $INPUT_DIR/$T_FILE.bam $TMPDIR
/usr/bin/time --verbose cp -v $INPUT_DIR/$T_FILE.bai $TMPDIR

echo "Running MuTect2 on normal:$N_FILE.bam vs tumor:$T_FILE.bam"
/usr/bin/time --verbose $JAVA -Xmx10g -jar $GATK \
-T MuTect2 \
-nct 1 \
$INTERVALS \
--interval_padding $PADDING \
-R $REF \
--cosmic $COSMIC \
--dbsnp $DBSNP \
--input_file:normal $TMPDIR/$N_FILE.bam \
--input_file:tumor $TMPDIR/$T_FILE.bam \
--out $TMPDIR/$OUTPUT.vcf \
--bamOutput $TMPDIR/$OUTPUT.bam \
--log_to_file $TMPDIR/$OUTPUT.log

echo "Copying $TMPDIR/$OUTPUT.* to $PWD"
/usr/bin/time --verbose cp $TMPDIR/$OUTPUT.vcf $PWD
/usr/bin/time --verbose cp $TMPDIR/$OUTPUT.vcf.idx $PWD
/usr/bin/time --verbose cp $TMPDIR/$OUTPUT.bam $PWD
/usr/bin/time --verbose cp $TMPDIR/$OUTPUT.bai $PWD

echo "Deleting $TMPDIR/$N_FILE.*"
rm $TMPDIR/$N_FILE.*

echo "Deleting $TMPDIR/$T_FILE.*"
rm $TMPDIR/$T_FILE.*

echo "Deleting $TMPDIR/$OUTPUT.*"
rm $TMPDIR/$OUTPUT.*

date
echo "END"
