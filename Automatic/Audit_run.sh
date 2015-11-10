#!/bin/bash -e

# Matthew Bashton 2015

# This script audits a run of the automated pipeline to check all jobs ran
# correctly.  It also sums run time of all stages.

source GATKsettings.sh

# Set up global totals
TOTUSRSYS=0
TOTREAL=0

# Determing number of samples in master list
N=`wc -l $MASTER_LIST | cut -d ' ' -f 1`
N2=$(($N*2))

# Function to change second to H:M:S
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

# Define a function for auditing a run
function auditrun {

    # Get passed variables
    local DIR=$1
    local RUNNAME=$2
    local NOJOBS=$3

    if [ $NOJOBS -eq 1 ]
    then
        echo -e "\n * Checking $NOJOBS "$RUNNAME" job:"
    else
        echo -e "\n * Checking $NOJOBS "$RUNNAME" jobs:"
    fi

    # Check jobs than ran/failed and get times
    local END=`grep -cHe 'END' $DIR/*.o* | grep -o ':1' | wc -l`
    local NO_END=`grep -cHe 'END' $DIR/*.o* | grep -o ':0' | wc -l`
    local ERRORS=`grep -e 'Exit status: [1-9]' FastQC/*.e* | wc -l`
    local USRSYS=`grep 'time (seconds)' $DIR/*.e* | grep -oP '\d+\.\d+$' | paste -s -d+ | bc`
    local MS=`grep 'Elapsed (wall clock)' $DIR/*.e* | perl -lne ' if (/(\d+):(\d+)\.(\d+)/) {$ms=$1*60; $tot=$ms+$2; print "$tot"."."."$3";}' | paste -s -d+ | bc`
    local HMS=`grep 'Elapsed (wall clock)' $DIR/*.e* | perl -lne ' if (/(\d+):(\d+):(\d+)/) {$hs=$1*60*60; $ms=$2*60; print $hs+$ms+$3}' | paste -s -d+ | bc`

    # If there were no jobs that ran for over an hour Hours Mins Secs variable
    # $HMS will be undefined, if so set it to 0
    if [ -z "$MHS" ]; then
        HMS=0
    fi

    # Add up two local seconds taken variables
    local REAL=`echo $MS + $HMS | bc`

    # Rround up decimal places in variables
    ROUNDUSRSYS=`printf "%.*f" 0 $USRSYS`
    ROUNDREAL=`printf "%.*f" 0 $REAL`

    # Convert REAL and USRSYS to seconds
    DISPUSRSYS=$(displaytime $ROUNDUSRSYS)
    DISPREAL=$(displaytime $ROUNDREAL)

    # Update global seconds counters
    TOTUSRSYS=`echo $TOTUSRSYS + $USRSYS | bc`
    TOTREAL=`echo $TOTREAL + $REAL | bc`

    # Echo jobs and seconds
    echo -e "  - $END jobs ran fully"
    echo -e "  - $NO_END failed to finish"
    echo -e "  - $ERRORS non-zero exit statuses reported"
    echo -e "  - $USRSYS user and system time (seconds)"
    echo -e "  - $DISPUSRSYS user and system time"
    echo -e "  - $REAL real world time (seconds)"
    echo -e "  - $DISPREAL real world time"
}

# Use auditrun function on all stages of pipeline
auditrun "FastQC" "FastQC" $N2
auditrun "BWA_MEM" "BWA" $N
auditrun "SamToSortedBam" "SortSam" $N
auditrun "MarkDuplicates" "MarkDuplicates" $N
auditrun "1stRealn" "Realignment (both RTC and IDR)" $N2
auditrun "BQSR_sample_lvl" "BQSR (both BQSR and PrintReads)" $N2
auditrun "HC_sample_lvl" "HaplotypeCaller" $N
auditrun "GenotypeGVCFs" "GenotypeGVFs" 1
auditrun "VQSR_HC" "VQSR (training and apply)" 4
auditrun "Filt_Recaled_VCF" "Filter VCF" 1
auditrun "Split_VCF" "Split VCF" 1
auditrun "VEP" "VEP" $N2

# Rround up decimal places in variables
TOTUSRSYS=`printf "%.*f" 0 $TOTUSRSYS`
TOTREAL=`printf "%.*f" 0 $TOTREAL`

# Call to displaytime function
DISPTOTUSRSYS=$(displaytime $TOTUSRSYS)
DISPTOTREAL=$(displaytime $TOTREAL)

# Echo global totals
echo -e "\n * CPU and job time cumulative totals:"
echo -e "  - $TOTUSRSYS total user and system time seconds"
echo -e "  - $DISPTOTUSRSYS total user and system time"

echo -e "  - $TOTREAL total additive real world time of all jobs (seconds)"
echo -e "  - $DISPTOTREAL total additive real world time of all jobs"

# Get whole run start time
START=`grep . start.time`
DSTART=`date -d @$START`

# Get whole run end time
END=`grep Timestamp VEP/*.o* | grep -oP '\d+$' | sort | tail -n 1`
DEND=`date -d @$END`

# Work out diff
DIFF=`echo $END - $START | bc`

# Round up
DIFF=`printf "%.*f" 0 $DIFF`

# Convert
DISPLAYDIFF=`displaytime $DIFF`



echo -e "\n * Real world timings"

echo -e " - Jobs sumbitted to queue on $DSTART"
echo -e " - Final job finished on $DEND"
echo -e " - $DISPLAYDIFF time taken for whole analysis of $N samples (submission to final job finish)"

echo -e "\nEND\n"
