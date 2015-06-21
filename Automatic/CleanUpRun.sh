B#!/bin/bash -e                                                                                                                                                   

# Matthew Bashton 2012-2015 

# A script to clean up the output following successful completion of the 
# automated pipeline.

tput bold

echo -e "\nThis script will delete all intermediate files, .sam, .bam, and will leave all"
echo -e "g.vcf/.vcf and log files intact.  The de-duplicated, realigned and recalibrated"
echo -e ".bam files for each sample will also be left intact.\n\n"

read -p "Are you sure you want to delete intermediate output? " -n 1 -r
echo  ""

tput sgr0 

if [[ $REPLY =~ ^[Yy]$ ]]
then
    # do dangerous stuff
    echo " - Deleting sam files"
    cd BWA_MEM 
    rm *.sam
    cd ..
    echo " - Deleting inital bam files"
    cd SamToSortedBam
    rm *.bam
    cd ..
    echo " - Deleting duplicate marked bam"
    cd MarkDuplicates
    rm *.bam
    cd ..
    echo " - Deleting realigned bam"
    cd 1stRealn
    rm *.bam
    cd ..
    echo "All intermediate files deleted, de-duplicated, realigned and recalibrated" 
    echo ".bam in /BQSR left intact along with .vcf/g.vcf and log files" 
fi