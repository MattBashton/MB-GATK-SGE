#!/bin/bash -e                                                                                   

# Matthew Bashton 2012-2016

# A script to clean up the output following successful completion of the
# automated pipeline for MuTect1.

tput bold

echo -e "\nThis script will delete all intermediate files, .bam, and will leave all"
echo -e "MuTect1 output and log files intact.  The final split Tumour/Normal de-duplicated,"
echo -e "jontly realigned and recalibrated .bam files for each sample used for running"
echo -e "MuTect1 will also be left intact.\n\n"

read -p "Are you sure you want to delete intermediate output? " -n 1 -r
echo  ""

tput sgr0

if [[ $REPLY =~ ^[Yy]$ ]]
then
    # do dangerous stuff
    echo " - Deleting merged bam files"
    cd Merge_MuTect1_pairs
    rm *.ba*
    cd ..
    echo " - Deleting indel realigned bam files"
    cd MuTect1_Realn_pairs
    rm *.ba*
    cd ..
    echo " - Deleting BQSR output bam files"
    cd MuTect1_merged_BQSR
    rm *.ba*
    cd ..
    echo "All intermediate merged Tumour/Normal files deleted, the final split per sample"
    echo ".bam has been left intact in /MuTect1_split_bam along with MuTect1 output"
fi
