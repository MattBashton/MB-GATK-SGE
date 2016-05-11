#!/bin/bash -e
# Matthew Bashton 2012-2016

# Runs MuTect1 pipeline as a series of array jobs, each array job will depend
# on its counterpart in the previous job array using -hold_jid_ad
tput bold
echo "Matt Basthon 2012-2016"
echo -e "Running MuTect1 pipeline\n"
tput sgr0

set -o pipefail

tput setaf 1
hostname
date
# Used by Audit_run.sh for calculating run length of whole analysis
date '+%s' > start.time
echo ""
tput sgr0

# Load settings for this run
source GATKsettings.sh

tput setaf 2
echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - G_NAME = $G_NAME"
echo " - MASTER_LIST = $MASTER_LIST"
echo " - MUTECT_LITS = $MUTECT_LIST"
echo " - PWD = $PWD"

# Determine number of samples in master list
N=`wc -l $MASTER_LIST | cut -d ' ' -f 1`
echo -e " - No of samples = $N\n"
tput sgr0

# Optional (uncomment for MuTect2)
# Determine number of pairs in MuTect2 list
MU_N=`wc -l $MUTECT_LIST | cut -d ' ' -f 1`

# This waits on all main run IDR jobs to finish
tput bold
echo " * Mu1 1 Merge per-sample realigned bams jobs submitted"
tput sgr0
qsub -t 1-$MU_N -N $G_NAME.Merge -hold_jid $G_NAME.IDR -wd $PWD/Merge_MuTect1_pairs Merge_MuTect1_pairs/MT1_merge_pairs.sh

tput bold
echo " * Mu1 2 Realignment Target Creation for merged bams jobs submitted"
tput sgr0
qsub -t 1-$MU_N -N $G_NAME.MT1_RTC -hold_jid_ad $G_NAME.Merge -wd $PWD/MuTect1_Realn_pairs MuTect1_Realn_pairs/MT1_RTC.sh

tput bold
echo " * Mu1 3 Indel Realignment of merged bams jobs submitted"
tput sgr0
qsub -t 1-$MU_N -N $G_NAME.MT1_IDR -hold_jid_ad $G_NAME.MT1_RTC -wd $PWD/MuTect1_Realn_pairs MuTect1_Realn_pairs/MT1_IDR.sh

tput bold
echo " * Mu1 4 Base Quality Score Recalibration - training jobs for merged bams submitted"
tput sgr0
qsub -t 1-$MU_N -N $G_NAME.MT1_BQSR -hold_jid_ad $G_NAME.MT1_IDR -wd $PWD/MuTect1_merged_BQSR MuTect1_merged_BQSR/MT1_BQSR.sh

tput bold
echo " * Mu1 5 Base Quality Score Recalibration - PrintReads jobs for merged bams submitted"
tput sgr0
qsub -t 1-$MU_N -N $G_NAME.MT1_PrintReads -hold_jid_ad $G_NAME.MT1_BQSR -wd $PWD/MuTect1_merged_BQSR MuTect1_merged_BQSR/MT1_PrintReads.sh

tput bold
echo " * Mu1 6 Split merged bams jobs submitted"
tput sgr0
qsub -t 1-$MU_N -N $G_NAME.MT1_split_bam -hold_jid_ad $G_NAME.MT1_BQSR -wd $PWD/MuTect1_split_bam MuTect1_split_bam/MT1_split_bam.sh

tput bold
echo " * Mu1 7 Run MuTect1"
tput sgr0
qsub -t 1-$MU_N -N $G_NAME.MT1 -hold_jid_ad $G_NAME.MT1_split_bam -wd $PWD/MuTect1 MuTect1/MT1.sh

tput bold
echo " * Mu1 8 Filter MuTect1 VCF"
tput sgr0
qsub -t 1-$MU_N -N $G_NAME.Filt_MT1 -hold_jid_ad $G_NAME.MT1 -wd $PWD/Filt_MT1_VCF Filt_MT1_VCF/Filt_MT1_VCF.sh

tput bold
echo " * Mu1 9 Ensembl VEP jobs submitted for MuTect output"
tput sgr0
qsub -t 1-$MU_N -N $G_NAME.VEP_MT1 -hold_jid_ad $G_NAME.Filt_MT1 -wd $PWD/VEP_MT1 $PWD/VEP_MT1/VEP_MT1.sh

echo ""
tput setaf 2
# Cowsay is optional!
#cowsay "All jobs submitted"
echo -e "All jobs submitted\n\n"
tput sgr0
