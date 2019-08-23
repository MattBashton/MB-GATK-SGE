#!/bin/bash -e

# Matthew Bashton 2015
# Generate run stats for a GATK run

echo -e "\n### GATK run Stats ###\n"

source GATKsettings.sh

date

echo -e "\n\n - SAMtools flagstat info:\n"
cd MarkDuplicates
awk 'BEGIN {print "Run ID\t\tTotal Reads\tDuplicate Reads \tMapped Reads\tPercent mapped\tMate Pairs\tProperly Paired \tPercent Properly Paired"}; FNR == 1 {printf $1"\t"}; FNR == 2 {printf "%11s", $1"\t"}; FNR == 5 {printf "%13s", $1"\t\t"}; FNR == 6 {printf "%11s", $1"\t"} FNR == 6 {printf "%14s", $5"\t"}; FNR == 8 {printf "%10s", $1"\t"}; FNR == 10 {printf "%14s", $1"\t\t"}; FNR == 10 {printf "%14s", $6"\n"}' *.flagstat.txt

echo -e "\n\n - MarkDuplicates, duplication rates:\n"
awk 'FNR == 8 {printf $1": "}; FNR == 8 {printf "%.2f%%\n", $9*100}' *.metrics.txt | sort -u
cd ..

echo -e "\n\n - Depth of Coverage:\n"
cd DofC
echo -e "Sample ID\tMean depth"; awk 'FNR == 2 {printf $1"\t"$3"\n"}' *.sample_summary | sort -u
cd ..

function count_snps {
    local FILE=$1
    echo $FILE | cut -d'.' -f 4 | tr -d '\n'
    cat $FILE | $VCFANNOTATE --fill-type | grep -oP "TYPE=\w+" | sort | uniq -c | awk 'BEGIN {printf " SNPs: "}; FNR == 1 {print $1}'
}

echo -e "\n\n - SNP counts\n"

cd Split_VCF
for VCF in *snps.*.vcf
do
    count_snps $VCF
done

function count_indels {
    local FILE=$1
    echo $FILE | cut -d'.' -f 4 | tr -d '\n'
    cat $FILE | $VCFANNOTATE --fill-type | grep -oP "TYPE=\w+" | sort | uniq -c | awk 'FNR == 1 {printf " Del: "$1"  "}; FNR == 2 {printf "Ins: "$1"\n"}'
}

echo -e "\n\n - Indel counts\n"
for VCF in *indels.*.vcf
do
  count_indels $VCF
done

cd ..

echo -e "\n\nEND\n"
