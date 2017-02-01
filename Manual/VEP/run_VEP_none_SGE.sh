#!/bin/bash -eu

# Matthew Bashton 2015-2017
# Runs VEP with a whole dir of vcf input from $1 given as ../dir/*.vcf $2 is output dir which is created
[ $# -eq 0 ] && { echo -e "\nMatt Bashton 2015-2017\n\n*** This script runs VEP on *.vcf in given dir ***\n\nError nothing to do!\n\nUsage: <input dir>  <output dir>\n\nThe output dir will be created\n\n" ; exit 1; }

set -o pipefail
hostname
date

OUTPUT=${2%/}

echo "Creating output dir $OUTPUT"
mkdir -p $OUTPUT

# Get sample names
list=( $(ls -1 $1/*.vcf) )
for i in ${list[@]}
do
    echo "*** Working on $i  ***"
    # Not needed for b37
    #echo " - Converting $i to ensembl chr ids using sed"
    #sed -i.bak s/chr//g $i
    SAMP_NAME=$(basename $i .vcf)
    echo " - Basename is $SAMP_NAME"
    echo " - Running VEP on $i"

    /usr/bin/time --verbose variant_effect_predictor.pl \
    -i $i \
    --no_progress \
    --cache \
    --port 3337 \
    --everything \
    --force_overwrite \
    --maf_exac \
    --html \
    --tab \
    -o $OUTPUT/$SAMP_NAME.VEP.txt \
    --buffer_size 5000 \
    --fork 10 \
    --pick_allele
done
echo "END"
