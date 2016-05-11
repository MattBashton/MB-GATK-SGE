#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 10
#$ -l h_rt=24:00:00
#$ -l h_vmem=70G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2015-2016
# Runs Ensembl VEP with input from $1 this needs modules for VEP since it has a
# lot of dependancies which are not trivial to install.

# Using local cache copied from that installed to luster FS via head node as
# multiple jobs all writing to same files may cause issues, also cache works
# by streaming zcat of .gz files so rather suboptimal for cluster.

module add apps/perl
module add apps/samtools/1.3
module add apps/VEP/v83

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
# Note just using 83_GRCh37 this will need to change from release to release  / organism / reference
mkdir $TMPDIR/vep_cache

echo "Copying VEP cache: $GLOBAL_VEP_CACHE to $TMPDIR/vep_cache"
/usr/bin/time --verbose cp -R -v $GLOBAL_VEP_CACHE/homo_sapiens $TMPDIR/vep_cache/
/usr/bin/time --verbose cp -R -v $GLOBAL_VEP_CACHE/Plugins $TMPDIR/vep_cache/

echo "Setting VEP cache location to $TMPDIR/vep_cache"
VEP_CACHEDIR="$TMPDIR/vep_cache"

# Not needed for b37
#echo "Converting $B_NAME.vcf to ensembl chr ids using sed"
#sed -i.bak s/chr//g $TMPDIR/$B_NAME.vcf

echo "Running VEP on $TMPDIR/$B_NAME.vcf"
/usr/bin/time --verbose variant_effect_predictor.pl \
-i $TMPDIR/$B_NAME.vcf \
--no_progress \
--cache \
--port 3337 \
--everything \
--force_overwrite \
--pubmed \
--maf_exac \
--variant_class \
--regulatory \
--fields Uploaded_variation,Location,Allele,Gene,Feature,Feature_type,Consequence,cDNA_position,CDS_position,Protein_position,Amino_acids,Codons,Existing_variation,IMPACT,VARIANT_CLASS,DISTANCE,STRAND,SYMBOL,SYMBOL_SOURCE,HGNC_ID,BIOTYPE,CANONICAL,TSL,CCDS,ENSP,SWISSPROT,TREMBL,UNIPARC,SIFT,PolyPhen,MOTIF_NAME,MOTIF_POS,HIGH_INF_POS,MOTIF_SCORE_CHANGE,CELL_TYPE,EXON,INTRON,DOMAINS,HGVSc,HGVSp,GMAF,AFR_MAF,AMR_MAF,ASN_MAF,EAS_MAF,EUR_MAF,SAS_MAF,AA_MAF,EA_MAF,ExAC_MAF,ExAC_Adj_MAF,ExAC_AFR_MAF,ExAC_AMR_MAF,ExAC_EAS_MAF,ExAC_FIN_MAF,ExAC_NFE_MAF,ExAC_OTH_MAF,ExAC_SAS_MAF,CLIN_SIG,SOMATIC,PHENO,GENE_PHENO,PUBMED,MOTIF_NAME,MOTIF_POS,HIGH_INF_POS,MOTIF_SCORE_CHANGE,PICK \
--html \
-o $TMPDIR/$B_NAME.txt \
--dir $TMPDIR/vep_cache/ \
--buffer_size 25000 \
--fork 10 \
--pick_allele

echo "Copying back VEP *.txt output from $TMPDIR to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/*.txt $PWD

echo "Copying back VEP *.html output from $TMPDIR to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/*.html $PWD

# Cleaning up
echo "Removing *.txt *.html *.vcf from $TMPDIR"
rm $TMPDIR/*.txt
rm $TMPDIR/*.html
rm $TMPDIR/*.vcf

date
echo "END"
