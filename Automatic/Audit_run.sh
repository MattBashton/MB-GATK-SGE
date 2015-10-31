#!/bin/bash -e

# Matthew Bashton 2015

# This script audits a run of the automated pipe-line to check all jobs ran
# correctly.

source GATKsettings.sh

# Set up totals
TOTUSRSYS=0
TOTREAL=0

#Determing number of samples in master list
N=`wc -l $MASTER_LIST | cut -d ' ' -f 1`
N2=$(($N*2))

echo -e "\n This run $G_NAME has $N samples"

echo -e "\n * Checking $N2 FastQC jobs:"
END=`grep -cHe 'END' FastQC/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' FastQC/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' FastQC/*.e* | wc -l`
USRSYS=`grep 'time (seconds)' FastQC/*.e* | grep -oP '\d+\.\d+$' | paste -s -d+ | bc`
MS=`grep 'Elapsed (wall clock)' FastQC/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
HMS=`grep 'Elapsed (wall clock)' FastQC/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`
if [ -z "$MHS" ]; then
    HMS=0
fi
REAL=`echo $MS + $HMS | bc`
TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
TOTREAL=`echo $TOTREAL + $REAL | bc`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"
echo -e "  - $USRSYS user and system time (seconds)"
echo -e "  - $REAL real world time (seconds)"

echo -e "\n * Checking $N BWA jobs:"
END=`grep -cHe 'END' BWA_MEM/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' BWA_MEM/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' BWA_MEM/*.e* | wc -l`
USRSYS=`grep 'time (seconds)' BWA_MEM/*.e* | grep -oP '\d+\.\d+$' | paste -s -d+ | bc`
MS=`grep 'Elapsed (wall clock)' BWA_MEM/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
HMS=`grep 'Elapsed (wall clock)' BWA_MEM/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`
if [ -z "$MHS" ]; then
    HMS=0
fi
REAL=`echo $MS + $HMS | bc`
TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
TOTREAL=`echo $TOTREAL + $REAL | bc`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"
echo -e "  - $USRSYS user and system time (seconds)"
echo -e "  - $REAL real world time (seconds)"

echo -e "\n * Checking $N SortSam jobs:"
END=`grep -cHe 'END' SamToSortedBam/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' SamToSortedBam/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' SamToSortedBam/*.e* | wc -l`
USRSYS=`grep 'time (seconds)' SamToSortedBam/*.e* | grep -oP '\d+\.\d+$' | paste -s -d+ | bc`
MS=`grep 'Elapsed (wall clock)' SamToSortedBam/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
HMS=`grep 'Elapsed (wall clock)' SamToSortedBam/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`
if [ -z "$MHS" ]; then
    HMS=0
fi
REAL=`echo $MS + $HMS | bc`
TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
TOTREAL=`echo $TOTREAL + $REAL | bc`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"
echo -e "  - $USRSYS user and system time (seconds)"
echo -e "  - $REAL real world time (seconds)"

echo -e "\n * Checking $N MarkDuplicates jobs:"
END=`grep -cHe 'END' MarkDuplicates/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' MarkDuplicates/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' MarkDuplicates/*.e* | wc -l`
USRSYS=`grep 'time (seconds)' MarkDuplicates/*.e* | grep -oP '\d+\.\d+$' | paste -s -d+ | bc`
MS=`grep 'Elapsed (wall clock)' MarkDuplicates/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
HMS=`grep 'Elapsed (wall clock)' MarkDuplicates/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`
if [ -z "$MHS" ]; then
    HMS=0
fi
REAL=`echo $MS + $HMS | bc`
TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
TOTREAL=`echo $TOTREAL + $REAL | bc`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"
echo -e "  - $USRSYS user and system time (seconds)"
echo -e "  - $REAL real world time (seconds)"

echo -e "\n * Checking $N2 Realignment jobs (both RTC and IDR) :"
END=`grep -cHe 'END' 1stRealn/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' 1stRealn/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' 1stRealn/*.e* | wc -l`
USRSYS=`grep 'time (seconds)' 1stRealn/*.e* | grep -oP '\d+\.\d+$' | paste -s -d+ | bc`
MS=`grep 'Elapsed (wall clock)' 1stRealn/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
HMS=`grep 'Elapsed (wall clock)' 1stRealn/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`
if [ -z "$MHS" ]; then
    HMS=0
fi
REAL=`echo $MS + $HMS | bc`
TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
TOTREAL=`echo $TOTREAL + $REAL | bc`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"
echo -e "  - $USRSYS user and system time (seconds)"
echo -e "  - $REAL real world time (seconds)"

echo -e "\n * Checking $N2 BQSR jobs (both BQSR and PrintReads):"
END=`grep -cHe 'END' BQSR_sample_lvl/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' BQSR_sample_lvl/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' BQSR_sample_lvl/*.e* | wc -l`
USRSYS=`grep 'time (seconds)' BQSR_sample_lvl/*.e* | grep -oP '\d+\.\d+$' | paste -s -d+ | bc`
MS=`grep 'Elapsed (wall clock)' BQSR_sample_lvl/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
HMS=`grep 'Elapsed (wall clock)' BQSR_sample_lvl/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`
if [ -z "$MHS" ]; then
    HMS=0
fi
REAL=`echo $MS + $HMS | bc`
TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
TOTREAL=`echo $TOTREAL + $REAL | bc`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"
echo -e "  - $USRSYS user and system time (seconds)"
echo -e "  - $REAL real world time (seconds)"

echo -e "\n * Checking $N HaplotypeCaller jobs:"
END=`grep -cHe 'END' HC_sample_lvl/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' HC_sample_lvl/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' HC_sample_lvl/*.e* | wc -l`
USRSYS=`grep 'time (seconds)' HC_sample_lvl/*.e* | grep -oP '\d+\.\d+$' | paste -s -d+ | bc`
MS=`grep 'Elapsed (wall clock)' HC_sample_lvl/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
HMS=`grep 'Elapsed (wall clock)' HC_sample_lvl/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`
if [ -z "$MHS" ]; then
    HMS=0
fi
REAL=`echo $MS + $HMS | bc`
TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
TOTREAL=`echo $TOTREAL + $REAL | bc`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"
echo -e "  - $USRSYS user and system time (seconds)"
echo -e "  - $REAL real world time (seconds)"

echo -e "\n * Checking 1 GenotypeGVFs run:"
END=`grep -cHe 'END' GenotypeGVCFs/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' GenotypeGVCFs/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' GenotypeGVCFs/*.e* | wc -l`
USRSYS=`grep 'time (seconds)' GenotypeGVCFs/*.e* | grep -oP '\d+\.\d+$' | paste -s -d+ | bc`
MS=`grep 'Elapsed (wall clock)' GenotypeGVCFs/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
HMS=`grep 'Elapsed (wall clock)' GenotypeGVCFs/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`
if [ -z "$MHS" ]; then
    HMS=0
fi
REAL=`echo $MS + $HMS | bc`
TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
TOTREAL=`echo $TOTREAL + $REAL | bc`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"
echo -e "  - $USRSYS user and system time (seconds)"
echo -e "  - $REAL real world time (seconds)"

echo -e "\n * Checking 4 VQSR jobs (training and apply):"
END=`grep -cHe 'END' VQSR_HC/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' VQSR_HC/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' VQSR_HC/*.e* | wc -l`
USRSYS=`grep 'time (seconds)' VQSR_HC/*.e* | grep -oP '\d+\.\d+$' | paste -s -d+ | bc`
MS=`grep 'Elapsed (wall clock)' VQSR_HC/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
HMS=`grep 'Elapsed (wall clock)' VQSR_HC/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`
if [ -z "$MHS" ]; then
    HMS=0
fi
REAL=`echo $MS + $HMS | bc`
TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
TOTREAL=`echo $TOTREAL + $REAL | bc`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"
echo -e "  - $USRSYS user and system time (seconds)"
echo -e "  - $REAL real world time (seconds)"

echo -e "\n * Checking 1 Filter VCF run:"
END=`grep -cHe 'END' Filt_Recaled_VCF/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' Filt_Recaled_VCF/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' Filt_Recaled_VCF/*.e* | wc -l`
USRSYS=`grep 'time (seconds)' Filt_Recaled_VCF/*.e* | grep -oP '\d+\.\d+' | paste -s -d+ | bc`
MS=`grep 'Elapsed (wall clock)' Filt_Recaled_VCF/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
HMS=`grep 'Elapsed (wall clock)' Filt_Recaled_VCF/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`
if [ -z "$MHS" ]; then
    HMS=0
fi
REAL=`echo $MS + $HMS | bc`
TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
TOTREAL=`echo $TOTREAL + $REAL | bc`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"
echo -e "  - $USRSYS user and system time (seconds)"
echo -e "  - $REAL real world time (seconds)"

echo -e "\n * Checking 1 Split VCF run:"
END=`grep -cHe 'END' Split_VCF/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' Split_VCF/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' Split_VCF/*.e* | wc -l`
USRSYS=`grep 'time (seconds)' Split_VCF/*.e* | grep -oP '\d+\.\d+$' | paste -s -d+ | bc`
MS=`grep 'Elapsed (wall clock)' Split_VCF/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
HMS=`grep 'Elapsed (wall clock)' Split_VCF/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`
if [ -z "$MHS" ]; then
    HMS=0
fi
REAL=`echo $MS + $HMS | bc`
TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
TOTREAL=`echo $TOTREAL + $REAL | bc`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"
echo -e "  - $USRSYS user and system time (seconds)"
echo -e "  - $REAL real world time (seconds)"

echo -e "\n * Checking $N2 VEP jobs:"
END=`grep -cHe 'END' VEP/*.o* | grep -o ':1' | wc -l`
NO_END=`grep -cHe 'END' VEP/*.o* | grep -o ':0' | wc -l`
ERRORS=`grep -e 'Exit status: [1-9]' VEP/*.e* | wc -l`
USRSYS=`grep 'time (seconds)' VEP/*.e* | grep -oP '\d+\.\d+$' | paste -s -d+ | bc`
MS=`grep 'Elapsed (wall clock)' VEP/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
HMS=`grep 'Elapsed (wall clock)' VEP/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`
if [ -z "$MHS" ]; then
    HMS=0
fi
REAL=`echo $MS + $HMS | bc`
TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
TOTREAL=`echo $TOTREAL + $REAL | bc`
echo -e "  - $END jobs ran fully"
echo -e "  - $NO_END failed to finish"
echo -e "  - $ERRORS non-zero exit statuses reported"
echo -e "  - $USRSYS user and system time (seconds)"
echo -e "  - $REAL real world time (seconds)"


# Rround up decimal places in variables
TOTUSRSYS=`printf "%.*f" 0 $TOTUSRSYS`
TOTREAL=`printf "%.*f" 0 $TOTREAL`

function displaytime {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  [[ $D > 0 ]] && printf '%d days ' $D
  [[ $H > 0 ]] && printf '%d hours ' $H
  [[ $M > 0 ]] && printf '%d minutes ' $M
  [[ $D > 0 || $H > 0 || $M > 0 ]] && printf 'and '
  printf '%d seconds\n' $S
}

DISPTOTUSRSYS=$(displaytime $TOTUSRSYS)
DISPTOTREAL=$(displaytime $TOTREAL)

tput bold
echo -e "\n * Totals:"
echo -e "  - $TOTUSRSYS total user and system time (seconds)"
echo -e "  - $DISPTOTUSRSYS total user and system time"

echo -e "  - $TOTREAL total additive real world time of all jobs (seconds)"
echo -e "  - $DISPTOTREAL total additive real world time of all jobs"
tput sgr0

echo -e "\nEND\n"
