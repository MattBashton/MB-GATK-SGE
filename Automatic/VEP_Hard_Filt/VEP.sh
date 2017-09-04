#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 10
#$ -l h_rt=24:00:00
#$ -l h_vmem=10G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2015-2017
# Runs Ensembl VEP this needs modules for VEP since it has a lot of
# dependancies which are not trivial to install.

# Using local cache copied from that installed to luster FS via head node as
# multiple jobs all writing to same files may cause issues, also cache works
# by streaming zcat of .gz files so rather suboptimal for cluster.

module add compilers/gnu/4.9.3
module add apps/perl/5.22.3
module add apps/VEP/v90

set -o pipefail
hostname
date

source ../GATKsettings.sh

# snps or indels passed in at command-line
VAR_TYPE=$1
VCF=$(ls -1 $BASE_DIR/Split_VCF_Hard_Filt/*.PerSample.vcf | grep $VAR_TYPE | awk "NR==$SGE_TASK_ID")
B_NAME=$(basename $VCF .vcf)

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - VCF = $VCF"
echo " - B_NAME = $B_NAME"
echo " - PWD = $PWD"

echo "Copying input $VCF to $TMPDIR/"
/usr/bin/time --verbose cp -v $VCF $TMPDIR

echo "Creating VEP cache dirs on local scratch in $TMPDIR"
# Note just using 86_GRCh37 this will need to change from release to release  / organism / reference
mkdir $TMPDIR/vep_cache

echo "Copying VEP cache: $GLOBAL_VEP_CACHE to $TMPDIR/vep_cache"
/usr/bin/time --verbose cp -R --preserve=all $GLOBAL_VEP_CACHE/homo_sapiens $TMPDIR/vep_cache/
/usr/bin/time --verbose cp -R --preserve=all $GLOBAL_VEP_CACHE/Plugins $TMPDIR/vep_cache/

echo "Setting VEP cache location to $TMPDIR/vep_cache"
VEP_CACHEDIR="$TMPDIR/vep_cache"

# Not needed for b37
#echo "Converting $B_NAME.vcf to ensembl chr ids using sed"
#sed -i.bak s/chr//g $TMPDIR/$B_NAME.vcf

echo "Running VEP on $TMPDIR/$B_NAME.vcf"
/usr/bin/time --verbose vep \
-i $TMPDIR/$B_NAME.vcf \
--cache \
--port 3337 \
--everything \
--nearest symbol \
--total_length \
--force_overwrite \
--plugin FATHMM_MKL,$TMPDIR/vep_cache/Plugins/fathmm-MKL_Current.tab.gz \
--plugin LoFtool,$TMPDIR/vep_cache/Plugins/LoFtool_scores.txt \
--plugin Carol \
--plugin Blosum62 \
--tab \
-o $TMPDIR/$B_NAME.txt \
--dir $TMPDIR/vep_cache/ \
--buffer_size 5000 \
--fork 10 \
--pick_allele

echo "Copying back VEP *.txt output from $TMPDIR to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/*.txt $PWD

# Cleaning up
echo "Removing *.txt *.vcf from $TMPDIR"
rm $TMPDIR/*.txt
rm $TMPDIR/*.vcf

date

# Used by Audit_run.sh for calculating run length of whole analysis
ENDTIME=$(date '+%s')
echo "Timestamp $ENDTIME"

echo "END"
