#!/bin/bash -eu

# Matthew Bashton 2016
# Makes COSMIC b37 file for use with MuTect1 / MuTect2 sorts COSMIC to same order as
# Referance.  Username and Password for COSMIC required:

# Register for account here: https://cancer.sanger.ac.uk/cosmic/register
SSHPASS=""
SSHUSER=""
SSHHOST="sftp-cancer.sanger.ac.uk"
# The version of COSMIC to download
COSMICVER="v79"

set -o pipefail
hostname
date

# Since running on head node
TMPDIR="/tmp"
BUNDLE_DIR="/opt/databases/GATK_bundle/2.8/b37"
REF_DICT="human_g1k_v37_decoy.dic"
# Add in module for Java 1.8 (FMS cluster specific)
module add apps/java/jre-1.8.0_92
JAVA="/opt/software/java/jdk1.8.0_92/bin/java -XX:-UseLargePages -Djava.io.tmpdir=$TMPDIR"
PICARD="/opt/software/bsu/bin/picard.jar"

echo "Downloading VCF from Sanger Cancer SFTP server"
export SSHPASS
sshpass -e sftp -oBatchMode=no -b - $SSHUSER@$SSHHOST << !
   cd cosmic
   cd grch37
   cd cosmic
   cd $COSMICVER
   cd VCF
   mget *.gz
   bye
!

echo "Uncompressing VCF"
pigz -d *.gz
# If you don't have the pigz binary then use good old gzip uncomment below:
# gunzip *.gz

echo "Running Picard SortVcf on CosmicCodingMuts.vcf and CosmicNonCodingVariants.vcf"
/usr/bin/time --verbose $JAVA -Xmx2g -XX:ParallelGCThreads=1 -jar $PICARD SortVcf \
INPUT=CosmicCodingMuts.vcf \
INPUT=CosmicNonCodingVariants.vcf \
OUTPUT=COSMIC_b37_${COSMICVER}.vcf \
SEQUENCE_DICTIONARY=$BUNDLE_DIR/$REF_DICT

# Clean up intermediate files
rm CosmicCodingMuts.vcf
rm CosmicNonCodingVariants.vcf

date
echo END
