#!/bin/bash -eu

# Matthew Bashton 2016-2019
# Makes COSMIC b37 file for use with MuTect1 / MuTect2 sorts COSMIC to same order as
# Referance.  Username and Password for COSMIC required:

# Register for account here: https://cancer.sanger.ac.uk/cosmic/register
PASS=""
USER=""
HOST="https://cancer.sanger.ac.uk/"

# The version of COSMIC to download
COSMICVER="v87"
ASSEMBLY="GRCh37"

set -o pipefail
hostname
date

# Since running on head node
TMPDIR="/tmp"
BUNDLE_DIR="/opt/databases/GATK_bundle/2.8/b37"
REF_DICT="human_g1k_v37_decoy.dict"
# Add in module for Java 1.8 (FMS cluster specific)
module add apps/java/jre-1.8.0_92
JAVA="/opt/software/java/jdk1.8.0_92/bin/java -XX:-UseLargePages -Djava.io.tmpdir=$TMPDIR"
PICARD="/opt/software/bsu/bin/picard.jar"
AUTH=$(echo "${USER}:${PASS}" | base64)

echo "Downloading VCF files from Sanger cancer server: ${HOST} genome assembly version: ${ASSEMBLY}"
# Get dowload links
CODING_URL="${HOST}cosmic/file_download/${ASSEMBLY}/cosmic/${COSMICVER}/VCF/CosmicCodingMuts.vcf.gz"
NONE_CODING_URL="${HOST}cosmic/file_download/${ASSEMBLY}/cosmic/${COSMICVER}/VCF/CosmicNonCodingVariants.vcf.gz"
CODING_LINK=$(curl -sH "Authorization: Basic ${AUTH}" "${CODING_URL}")
NONE_CODING_LINK=$(curl -sH "Authorization: Basic ${AUTH}" "${NONE_CODING_URL}")
# Reprocess vile JSON
CODING_FIXED_LINK=$(echo "${CODING_LINK}" | grep -oP 'https:\S+(?=")')
NONE_CODING_FIXED_LINK=$(echo "${CODING_LINK}" | grep -oP 'https:\S+(?=")')
# Curl the file using authed time limited link
curl --progress-bar -o CosmicCodingMuts.vcf.gz "${CODING_FIXED_LINK}"
curl --progress-bar -o CosmicNonCodingVariants.vcf.gz "${NONE_CODING_FIXED_LINK}"

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

# Need to remove the index file so GATK re makes it (otherwise throws error)
rm COSMIC_b37_${COSMICVER}.vcf.idx

date
echo END
