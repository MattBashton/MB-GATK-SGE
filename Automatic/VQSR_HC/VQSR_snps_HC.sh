#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 2
#$ -l h_vmem=14G
#$ -l h_rt=12:00:00
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2015

# Runs the Variant Recalibrator input is raw VCF from the HC and output is a
# recal file which can be applied using Apply Recalibration.
# Not using -an DP since this is a bad idea for exome + targeted panels.
# maxGuassians 4 needed to get things working with targeted data, drop this for
# exomes, unless small < 10 sample number or you have issues with too few bad
# variants.  Also leaving out InbreedingCoeff some discussion of this being
# problematic too on forums, needs at least 10 samples which are not related.
# Settings as given in GATK doc #1259 and #2805:
# https://www.broadinstitute.org/gatk/guide/article?id=2805
# https://www.broadinstitute.org/gatk/guide/article?id=1259
# Also you need to use dbsnp_138.hg19.excluding_sites_after_129.vcf see bottom of
# comments section on above link.

set -o pipefail
hostname
date

source ../GATKsettings.sh

B_NAME=`basename $G_NAME.HC_genotyped.vcf .vcf`

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - B_NAME = $B_NAME"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/GenotypeGVCFs/$G_NAME.HC_genotyped.vcf* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/GenotypeGVCFs/$G_NAME.HC_genotyped.vcf $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/GenotypeGVCFs/$G_NAME.HC_genotyped.vcf.idx $TMPDIR

echo "Running GATK"
/usr/bin/time --verbose $JAVA -Xmx10g -jar $GATK \
-T VariantRecalibrator \
-nt 2 \
-input $TMPDIR/$B_NAME.vcf \
-R $REF \
-recalFile $B_NAME.VR_HC_snps.recal \
-tranchesFile $B_NAME.VR_HC_snps.tranches \
-rscriptFile $B_NAME.VR_HC_snps.R \
-resource:hapmap,known=false,training=true,truth=true,prior=15.0 $HAPMAP \
-resource:omni,known=false,training=true,truth=true,prior=12.0 $OMNI \
-resource:1000G,known=false,training=true,truth=false,prior=10.0 $PHASE1_SNPS \
-resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $DBSNP129 \
-an QD \
-an FS \
-an SOR \
-an MQ \
-an MQRankSum \
-an ReadPosRankSum \
-mode SNP \
-tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 90.0 \
--log_to_file $B_NAME.VR_HC_snps.log

echo "Deleting $TMPDIR/$B_NAME.*"
rm $TMPDIR/$B_NAME.*

date
echo "END"
