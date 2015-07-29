#!/bin/bash -e
#$ -cwd -V
#$ -pe smp 10
#$ -l h_rt=4:00:00
#$ -l h_vmem=40G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2015
# Runs Ensembl VEP with input from $1 this needs modules for VEP since it has a
# lot of dependancies which are not trivial to install.

# Using local cache copied from that installed to luster FS via head node as 
# multiple jobs all writing to same files may cause issues, also cache works 
# by streaming zcat of .gz files so rather suboptimal for cluster.

module add apps/perl
module add apps/samtools
module add apps/VEP

set -o pipefail
hostname
date

source ../GATKsettings.sh
B_NAME=`basename $1 .vcf`

echo "** Variables **"
echo " - PWD=$PWD"
echo " - B_NAME=$B_NAME"

echo "Copying input $1 to $TMPDIR/"
/usr/bin/time --verbose cp -v $1 $TMPDIR

echo "Creating VEP cache dirs on local scratch in $TMPDIR"
# Note just using 79_GRCh37 this will need to change from release to release  / organism / reference 
mkdir $TMPDIR/vep_cache
mkdir $TMPDIR/vep_cache/homo_sapiens
mkdir $TMPDIR/vep_cache/homo_sapiens/79_GRCh37

echo "Copying VEP cache: $GLOBAL_VEP_CACHE to $TMPDIR/vep_cache"
/usr/bin/time --verbose cp -R -v $GLOBAL_VEP_CACHE/homo_sapiens/79_GRCh37/* $TMPDIR/vep_cache/homo_sapiens/79_GRCh37

echo "Setting VEP cache location to $TMPDIR/vep_cache"
VEP_CACHEDIR="$TMPDIR/vep_cache"

echo "Converting $B_NAME.vcf to ensembl chr ids using sed"
sed -i.bak s/chr//g $TMPDIR/$B_NAME.vcf

echo "Running VEP on $TMPDIR/$B_NAME.vcf"
/usr/bin/time --verbose variant_effect_predictor.pl \
-i $TMPDIR/$B_NAME.vcf \
--cache \
--port 3337 \
--everything \
--force_overwrite \
--pubmed \
--fields Uploaded_variation,Location,Allele,Gene,Feature,Feature_type,Consequence,cDNA_position,CDS_position,Protein_position,Amino_acids,Codons,Existing_variation,IMPACT,DISTANCE,STRAND,SYMBOL,SYMBOL_SOURCE,HGNC_ID,BIOTYPE,CANONICAL,TSL,CCDS,ENSP,SWISSPROT,TREMBL,UNIPARC,SIFT,PolyPhen,EXON,INTRON,DOMAINS,HGVSc,HGVSp,GMAF,AFR_MAF,AMR_MAF,ASN_MAF,EAS_MAF,EUR_MAF,SAS_MAF,AA_MAF,EA_MAF,CLIN_SIG,SOMATIC,PUBMED,MOTIF_NAME,MOTIF_POS,HIGH_INF_POS,MOTIF_SCORE_CHANGE \
--html \
-o $TMPDIR/$B_NAME.VEP.txt \
--dir_cache $TMPDIR/vep_cache/ \
--buffer_size 50000 \
--fork 10 \
--pick

echo "Copying back VEP output from $TMPDIR to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/*VEP* $PWD

# Cleaning up                                                                                                                                 
echo "Removing *.txt *.html *.vcf from $TMPDIR"
rm $TMPDIR/*.txt
rm $TMPDIR/*.html
rm $TMPDIR/*.vcf

echo "END"
