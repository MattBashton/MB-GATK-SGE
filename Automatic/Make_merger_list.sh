#!/bin/bash -eu

# Matthew Bashton 2016
# Simple hack to generate merger_list.txt on the basis of identical sample IDs
# Can be used to supply merger_list.txt for MergeBamFromList.sh

set -o pipefail
hostname
date

tput bold
echo "Making merger_list.txt using identical SM: field values as basis for merger"
tput sgr0

# Extract sample IDs
cut -d$'\t' -f 2 master_list.txt | grep -oP 'SM:\K\S+(?=\\tPL)' | uniq > sample_IDs.txt

# Now make our list
count=1
cat sample_IDs.txt | while read -r line; do echo -ne "$count\t";  grep -P 'SM:\K'"$line"'(?=\\tPL)' master_list.txt | grep -oP '^\S+' | tr '\n' ',' | sed 's/,$//'; ((count++)); echo ""; done > merger_list.txt

echo "Done"
