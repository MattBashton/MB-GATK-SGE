#!/bin/bash -eu

# Matthew Bashton 2016
# Runs BamQC on a bam file(s).  This is the none SGE version since SGE currelty
# causes silent fail.

set -o pipefail
hostname
date

# Java 1.8 on FMS cluster
module add apps/java/jre-1.8.0_92
# BamQC perl script (calls java)
BAMQC="/opt/software/bsu/bin/bamqc"
# BamQC genome download
BAMQC_GENOMES="/opt/databases/genomes/BamQC_files/genomes/"
# Number of threads to run analysis on, means x many samples can be processed
# at once.  Extra sample can be analysed in parallel per thread given, memory
# usage is approx 250MB per thread.
CORES="1"
TMP="/localscratch/"

INPUT=$@

echo "** Variables **"
echo " - INPUT = $INPUT"
echo " - PWD = $PWD"

echo "Running BamQC"
/usr/bin/time --verbose $BAMQC -s "Homo sapiens" -t $CORES -a GRCh37 -g $BAMQC_GENOMES --noextract -o $PWD -d $TMP $INPUT

date
echo "END"
