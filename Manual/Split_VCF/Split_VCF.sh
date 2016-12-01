#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_rt=6:00:00
#$ -l h_vmem=10G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2015-2016
# Runs bcftools and SelectVariants to split a multi sample .vcf file in to all samples, one .vcf
# file produced for each sample.

set -o pipefail
hostname
date

# Make sure matplotlib works on FMS cluster
module add apps/python27/2.7.8
module add libs/python/numpy/1.9.1-python27-2.7.8
module add libs/python/matplotlib/1.3.1-python27

source ../GATKsettings.sh
VCF=$1
B_NAME=$(basename $1 .vcf)
DEST=$PWD

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - VCF=$VCF"
echo " - PWD=$PWD"
echo " - DEST=$DEST"
echo " - B_NAME=$B_NAME"
echo ""

echo "Copying input $1 to $TMPDIR/"
/usr/bin/time --verbose cp -v $1 $TMPDIR

echo "Splitting $TMPDIR/$B_NAME.vcf by sample"
# Get sample names
list=( $($BCFTOOLS query -l $TMPDIR/$B_NAME.vcf) )

# Print these
echo ""
echo " - Samples in $B_NAME.vcf file are:"
echo ""
printf '%s\n' "${list[@]}"
echo ""

# Loop over array of names
for i in ${list[@]}
do
    echo "Extracting sample $i from $VCF with SelectVariants"
    /usr/bin/time --verbose $JAVA -Xmx4g -jar $GATK \
    -T SelectVariants \
    --downsampling_type NONE \
    --variant $TMPDIR/$B_NAME.vcf \
    -R $REF \
    --sample_name "$i" \
    --excludeNonVariants \
    --out $TMPDIR/$B_NAME.$i.PerSample.vcf \
    --log_to_file $B_NAME.$i.log
    # Annotating INFO/TYPE with vcf-annotate as GATK will not populate this, some tools need this
    cat $TMPDIR/$B_NAME.$i.PerSample.vcf | $VCFANNOTATE --fill-type > $TMPDIR/$B_NAME.$i.TYPE.vcf
    echo "Calculating per sample stats with bcftools stats on $B_NAME.$i.PerSample.vcf"
    /usr/bin/time --verbose $BCFTOOLS stats $TMPDIR/$B_NAME.$i.PerSample.vcf > $TMPDIR/$B_NAME.$i.stats

    # Copying output back to $PWD
    echo "Copying $B_NAME.$i.* to $PWD"
    /usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.$i.* $PWD/
    echo "Copying back bcftools stats output"
    /usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.$i.stats $PWD

    # Stats plot
    cd $TMPDIR
    echo "Plotting stats with plot-vcfstats using $B_NAME.$i.stats input"
    /usr/bin/time --verbose $PLOTVCFSTATS -s -t "$i" -p $B_NAME.$i $B_NAME.$i.stats
    echo "Copying back $B_NAME.${i}-summary.pdf to $DEST"
    /usr/bin/time --verbose cp -v $B_NAME.${i}-summary.pdf $DEST
    cd $DEST

    # old
    #echo "Extracting sample $i from $VCF with vcfutils and annotating INFO/TYPE with vcf-annotate"
    #/usr/bin/time --verbose $VCFUTILS subsam $TMPDIR/$B_NAME.vcf $i | $VCFANNOTATE --fill-type > $TMPDIR/$B_NAME.$i.vcf
    #echo "Filtering out alleles which are not present in sample $i for use in VEP"
    #/usr/bin/time --verbose $VCFTOOLS --non-ref-ac-any 1 --vcf $TMPDIR/$B_NAME.$i.vcf --stdout --recode | $VCFANNOTATE --fill-type > $TMPDIR/$B_NAME.$i.VEP.vcf
    #echo "Copying $B_NAME.$i.VEP.vcf to $PWD"
    #/usr/bin/time --verbose cp -v $TMPDIR/$B_NAME.$i.VEP.vcf $PWD/

done

# Cleaning up
echo "Removing *.vcf from $TMPDIR"
rm $TMPDIR/*.vcf

echo "END"
