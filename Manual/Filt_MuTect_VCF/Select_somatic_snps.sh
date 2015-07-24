#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 1
#$ -l h_vmem=8G
#$ -l h_rt=1:00:00
#$ -R y
#$ -q all.q,bigmem.q 

# Matthew Bashton 2012-2015
# Splits out the germline variants from MuTect VCF output then selects KEEP 
# flagged variants from MuTect VCF output.  Needs input MuTect .vcf as $1
# and sample name to extract (i.e. somatic sample) as $2.
 
set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $1 .vcf`
D_NAME=`dirname $1`
B_PATH_NAME=$D_NAME/$B_NAME
SAMP_NAME=$2

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - B_PATH_NAME = $B_PATH_NAME"
echo " - SAMP_NAME = $SAMP_NAME"
echo " - PWD = $PWD"

echo "Copying input $B_PATH_NAME.* to $TMPDIR"
/usr/bin/time --verbose cp -v $B_PATH_NAME.vcf $TMPDIR
/usr/bin/time --verbose cp -v $B_PATH_NAME.vcf.idx $TMPDIR

echo "Running GATK outputing PASSing variants"
/usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
-T SelectVariants \
--downsampling_type NONE \
--variant $TMPDIR/$B_NAME.vcf \
-R $BUNDLE_DIR/ucsc.hg19.fasta \
--out $TMPDIR/$B_NAME.PASS.vcf \
-select "vc.isNotFiltered()" \
-selectType SNP \
--log_to_file $B_NAME.SelectRecaledVariants.PASS.log

echo "Extracting sample $SAMP_NAME from $B_NAME.PASS.vcf and annotating INFO/TYPE with vcf-annotate"
/usr/bin/time --verbose $VCFUTILS subsam $TMPDIR/$B_NAME.PASS.vcf $SAMP_NAME | $VCFANNOTATE --fill-type > $TMPDIR/$SAMP_NAME.somatic_snps.vcf

echo "Copying back output $TMPDIR/$SAMP_NAME.* to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_NAME.* $PWD

echo "Deleting $TMPDIR/$B_NAME*"
rm $TMPDIR/$B_NAME*

echo "Delecting $TMPDIR/$SAMP_NAME*"
rm $TMPDIR/$SAMP_NAME*

date
echo "END"
