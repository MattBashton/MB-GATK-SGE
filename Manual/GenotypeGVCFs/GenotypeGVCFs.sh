#!/bin/bash -eu
#$ -cwd -V
#$ -l h_vmem=14G
#$ -pe smp 5
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015
# Runs GenotypeGVCFs which takes the sample level genomic VCF files and fuses
# them into a normal VCF file which can then be used for recalibration.

set -o pipefail
hostname
date

source ../GATKsettings.sh

# gVFC passed at command line via *.g.vcf
# Need to strip out leading file path and insert GATK input arg for each file

VCFS="$@"
for x in $VCFS
do
    SAMP_NAME=`basename $x`
    TMP=`echo $SAMP_NAME | perl -ne '/^(\S+)$/; print "--variant $1"'`
    #TMP="`echo \"$SAMP_NAME\" | sed -e 's/^/ --variant &/g'`"
    VCF_LIST="$VCF_LIST $TMP"
done

VCF_DIR=`dirname $1`
DEST=$PWD

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - VCF_DIR = $VCF_DIR"
echo " - PWD = $PWD"
echo " - DEST = $DEST"
echo " - VCF_LIST = $VCF_LIST"

echo "Copying input *.g.vcf and *.g.vcf.idx to $TMPDIR"
/usr/bin/time --verbose cp -v $VCF_DIR/*.g.vcf $TMPDIR
/usr/bin/time --verbose cp -v $VCF_DIR/*.g.vcf.idx $TMPDIR

echo "Running GenotypeGVCFs on gVCF list"
cd $TMPDIR
/usr/bin/time --verbose $JAVA -Xmx10g -jar $GATK \
-T GenotypeGVCFs \
-nt 5 \
-R $REF \
--dbsnp $DBSNP \
--max_alternate_alleles 50 \
$VCF_LIST \
-o HC_genotyped.vcf \
--log_to_file $DEST/$G_NAME.GenotypeGVCFs.log
cd $DEST

echo "Copying back merged VCF and index output to $DEST"
/usr/bin/time --verbose cp -v $TMPDIR/HC_genotyped.vcf $DEST
/usr/bin/time --verbose cp -v $TMPDIR/HC_genotyped.vcf.idx $DEST

echo "Removing * from $TMPDIR"
rm $TMPDIR/*

date
echo "END"
