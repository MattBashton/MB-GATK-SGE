#!/bin/bash -e

# Matthew Bashton 2015

# This script audits a run of the automated pipe-line to check all jobs ran 
# correctly.

source GATKsettings.sh

#Determing number of samples in master list
N=`wc -l $MASTER_LIST | cut -d ' ' -f 1`
N2=$(($N*2))

echo -e "\n This run $G_NAME has $N samples"

echo -e "\n * Checking $N2 FastQC jobs:"
END=`grep -cHe 'END' FastQC/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' FastQC/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' FastQC/*.e* | wc -l`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"

echo -e "\n * Checking $N BWA jobs:"
END=`grep -cHe 'END' BWA_MEM/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' BWA_MEM/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' BWA_MEM/*.e* | wc -l`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"

echo -e "\n * Checking $N SortSam jobs:"
END=`grep -cHe 'END' SamToSortedBam/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' SamToSortedBam/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' SamToSortedBam/*.e* | wc -l`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"

echo -e "\n * Checking $N MarkDuplicates jobs:"
END=`grep -cHe 'END' MarkDuplicates/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' MarkDuplicates/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' MarkDuplicates/*.e* | wc -l`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"

echo -e "\n * Checking $N2 Realignment jobs (both RTC and IDR) :"
END=`grep -cHe 'END' 1stRealn/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' 1stRealn/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' 1stRealn/*.e* | wc -l`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"

echo -e "\n * Checking $N2 BQSR jobs (both BQSR and PrintReads):"
END=`grep -cHe 'END' BQSR_sample_lvl/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' BQSR_sample_lvl/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' BQSR_sample_lvl/*.e* | wc -l`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"

echo -e "\n * Checking $N HaplotypeCaller jobs:"
END=`grep -cHe 'END' HC_sample_lvl/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' HC_sample_lvl/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' HC_sample_lvl/*.e* | wc -l`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"

echo -e "\n * Checking 1 GenotypeGVFs run:"
END=`grep -cHe 'END' GenotypeGVCFs/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' GenotypeGVCFs/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' GenotypeGVCFs/*.e* | wc -l`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"

echo -e "\n * Checking 4 VQSR jobs (training and apply):"
END=`grep -cHe 'END' VQSR_HC/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' VQSR_HC/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' VQSR_HC/*.e* | wc -l`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"

echo -e "\n * Checking 1 Filter VCF run:"
END=`grep -cHe 'END' Filt_Recaled_VCF/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' Filt_Recaled_VCF/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' Filt_Recaled_VCF/*.e* | wc -l`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"

echo -e "\n * Checking 1 Split VCF run:"
END=`grep -cHe 'END' Split_VCF/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' Split_VCF/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' Split_VCF/*.e* | wc -l`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"

echo -e "\n * Checking $N2 VEP jobs:"
END=`grep -cHe 'END' VEP/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' VEP/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' VEP/*.e* | wc -l`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"

echo -e "\nEND\n"