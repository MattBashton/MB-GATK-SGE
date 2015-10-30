#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 1
#$ -l h_rt=1:00:00
#$ -l h_vmem=1G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2015
# Runs vcfutils.pl to split a multi sample .vcf file in to all samples, one .vcf file produced for each sample

set -o pipefail
hostname
date

source ../GATKsettings.sh
VCF=$1
B_NAME=`basename $1 .vcf`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - VCF=$VCF"
echo " - PWD=$PWD"
echo " - B_NAME=$B_NAME"

echo "Copying input $1 to $TMPDIR/"
/usr/bin/time --verbose cp -v $1 $TMPDIR

echo "Splitting $TMPDIR/$B_NAME.vcf by sample"
# Get sample names
list=(`$VCFUTILS listsam $TMPDIR/$B_NAME.vcf`)

# Loop over array of names
for i in ${list[@]}
do
    echo "Extracting sample $i from $VCF with and annotating INFO/TYPE with vcf-annotate"
    /usr/bin/time --verbose $VCFUTILS subsam $TMPDIR/$B_NAME.vcf $i | $VCFANNOTATE --fill-type > $TMPDIR/$B_NAME.$i.vcf
    echo "Filtering out alleles which are not present in sample $i for use in VEP"
    /usr/bin/time --verbose $VCFTOOLS --non-ref-ac-any 1 --vcf $TMPDIR/$B_NAME.$i.vcf --stdout --recode | $VCFANNOTATE --fill-type > $TMPDIR/$B_NAME.$i.VEP.vcf
    echo "Copying $B_NAME.$i.VEP.vcf to $PWD"
    /usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.$i.VEP.vcf $PWD/
done

# Cleaning up
echo "Removing *.vcf from $TMPDIR"
rm $TMPDIR/*.vcf

echo "END"
