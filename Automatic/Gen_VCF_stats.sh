#!/bin/bash -e

# Matthew Bashton 2016
# Runs bcftools and collects stats on .vcf files in supplied dir given via $1

[ $# -eq 0 ] && { echo -en "\n*** This script gathers and plots stats on VCF files given at command-line via: dir/*.ext.vcf using bcftools ***\n\nError nothing to do!\n
Usage: <dir/*.ext.vcf>\n\n" ; exit 1; }
set -o pipefail
hostname
date

# Make sure matplotlib works on FMS cluster
module add apps/python27/2.7.8
module add libs/python/numpy/1.9.1-python27-2.7.8
module add libs/python/matplotlib/1.3.1-python27

source GATKsettings.sh

# Set so bound
VCF_LIST=()

# Get VCF files
VCFS="$@"
for x in $VCFS
do
    VCF=$(basename $x .vcf)
    VCF_LIST+=($VCF)
done

# Get dir of VCF
VCF_DIR=$(dirname $1)

echo ""
echo "** Variables **"
echo " - PWD = $PWD"
echo " - VCF_DIR = $VCF_DIR"
echo -ne " - VCF_LIST = "
printf '%s ' "${VCF_LIST[@]}"
echo -ne "\n\n"


# Change to VCF dir
echo "cd $VCF_DIR"
cd $VCF_DIR
echo ""

# Loop over VCF here
TOTAL=${#VCF_LIST[@]}
COUNT=1
for i in ${VCF_LIST[@]}
do
    echo "### Working on $COUNT of $TOTAL: $1 ###"
    echo "Calculating per sample stats with bcftools stats on $i.vcf"
    $BCFTOOLS stats $i.vcf > $i.stats
    echo "Plotting stats with plot-vcfstats using $i.stats input"
    $PLOTVCFSTATS -s -t "$i" -p $i/ $i.stats
    cp -v $i/summary.pdf $PWD/${i}-summary.pdf
    rm -vrf $i/
    ((COUNT++))
    echo ""
done

echo "END"
