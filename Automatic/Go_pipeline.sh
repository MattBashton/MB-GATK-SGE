#!/bin/bash -e
# Matthew Bashton 2012-2015

# Runs GATK pipeline as a series of array jobs, for most stages each array job
# will depend on its counterpart in the previous job array using -hold_jid_ad
tput bold
echo "Matt Basthon 2012-2015"
echo -e "Running GATK exome pipeline\n"
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
echo " - PWD = $PWD"

# Determine number of samples in master list
N=`wc -l $MASTER_LIST | cut -d ' ' -f 1`
echo -e " - No of samples = $N\n"
tput sgr0


#### Preprocessing
tput bold
echo " * 1 FastQC Jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.FastQC -wd $PWD/FastQC FastQC/FastQC.sh

tput bold
echo " * 2 BWA jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.BWA -wd $PWD/BWA_MEM BWA_MEM/BWA.sh

tput bold
echo " * 3 SortSam jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.SamToSortedBam -hold_jid_ad $G_NAME.BWA -wd $PWD/SamToSortedBam SamToSortedBam/SamToSortedBam.sh

tput bold
echo " * 4 Mark Duplicates jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.MarkDuplicates -hold_jid_ad $G_NAME.SamToSortedBam -wd $PWD/MarkDuplicates MarkDuplicates/MarkDuplicates.sh

tput bold
echo " * 5 Depth of Coverage jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.DofC -hold_jid_ad $G_NAME.MarkDuplicates -wd $PWD/DofC DofC/DofC.sh

tput bold
echo " * 6 Realignment Target Creation jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.RTC -hold_jid_ad $G_NAME.MarkDuplicates -wd $PWD/1stRealn 1stRealn/RTC.sh

tput bold
echo " * 7 Indel Realignment jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.IDR -hold_jid_ad $G_NAME.RTC -wd $PWD/1stRealn 1stRealn/IDR.sh

tput bold
echo " * 8 Base Quality Score Recalibration - traning jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.BQSR -hold_jid_ad $G_NAME.IDR -wd $PWD/BQSR_sample_lvl BQSR_sample_lvl/BaseRecal.sh

tput bold
echo " * 9 Base Quality Score Recalibration - training jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.PrintReads -hold_jid_ad $G_NAME.BQSR -wd $PWD/BQSR_sample_lvl BQSR_sample_lvl/PrintReads.sh


#### Calling
tput bold
echo " * 10 Haplotype Caller jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.HC -hold_jid_ad $G_NAME.PrintReads -wd $PWD/HC_sample_lvl HC_sample_lvl/HC.sh

#### GenotypeGVCFs gVCF joint genotyping stage, waits for all of the
#### above HC jobs to finish before running
tput bold
echo " * 11 GenotypeGVFs submitted"
tput sgr0
qsub -N $G_NAME.GenotypeGVCFs -hold_jid $G_NAME.HC -wd $PWD/GenotypeGVCFs GenotypeGVCFs/GenotypeGVCFs.sh $BASE_DIR/HC_sample_lvl/*.g.vcf

tput bold
echo " * 12 VQSR model building jobs submitted"
tput sgr0
qsub -N $G_NAME.VQSR_snps -hold_jid $G_NAME.GenotypeGVCFs -wd $PWD/VQSR_HC VQSR_HC/VQSR_snps_HC.sh
qsub -N $G_NAME.VQSR_indels -hold_jid $G_NAME.GenotypeGVCFs -wd $PWD/VQSR_HC VQSR_HC/VQSR_indels_HC.sh

tput bold
echo " * 13 Apply VQSR jobs submitted"
tput sgr0
qsub -N $G_NAME.ApplyRecal_snps -hold_jid $G_NAME.VQSR_snps -wd $PWD/VQSR_HC VQSR_HC/ApplyRecalibration_snps_HC.sh
qsub -N $G_NAME.ApplyRecal_indels -hold_jid $G_NAME.VQSR_indels -wd $PWD/VQSR_HC VQSR_HC/ApplyRecalibration_indels_HC.sh

tput bold
echo " * 14 Filter VCF jobs submitted"
tput sgr0
qsub -N $G_NAME.SelectRecaledVariants_snps -hold_jid $G_NAME.ApplyRecal_snps -wd $PWD/Filt_Recaled_VCF Filt_Recaled_VCF/SelectRecaledVariants_snps.sh
qsub -N $G_NAME.SelectRecaledVariants_indels -hold_jid $G_NAME.ApplyRecal_indels -wd $PWD/Filt_Recaled_VCF Filt_Recaled_VCF/SelectRecaledVariants_indels.sh

tput bold
echo " * 15 Split VCF jobs submitted"
tput sgr0
qsub -N $G_NAME.Split_VCF_snps -hold_jid $G_NAME.SelectRecaledVariants_snps -wd $PWD/Split_VCF Split_VCF/Split_VCF.sh $BASE_DIR/Filt_Recaled_VCF/$G_NAME.snps.PASS.vcf
qsub -N $G_NAME.Split_VCF_indels -hold_jid $G_NAME.SelectRecaledVariants_indels -wd $PWD/Split_VCF Split_VCF/Split_VCF.sh $BASE_DIR/Filt_Recaled_VCF/$G_NAME.indels.PASS.vcf

tput bold
echo " * 16 Ensembl VEP jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.VEP_snps -hold_jid $G_NAME.Split_VCF_snps -wd $PWD/VEP $PWD/VEP/VEP.sh snps
qsub -t 1-$N -N $G_NAME.VEP_indels -hold_jid $G_NAME.Split_VCF_indels -wd $PWD/VEP $PWD/VEP/VEP.sh indels

echo -e "\n"
tput setaf 2
# Cowsay is optional!
#cowsay "All jobs submitted"
echo -e "All jobs submitted\n\n"
tput sgr0
