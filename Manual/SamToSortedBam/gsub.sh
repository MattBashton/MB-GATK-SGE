#!/bin/bash -e

# Matthew Bashton 2015
# Generic cluster job submission script

# Takes shell expanded wildcard input from command-line and submits a qsub job
# for each element of array passed to it by the shell i.e.
# "script.sh /dir/*.bam" will qsub the specified shell script in $1 with all
# other variables passed in at command-line.

[ $# -eq 0 ] && { echo -e "\n*** This script submits a qsub job on the specified shell script for each file\n passed to it via the shell in a dir via "../*.ext" ***\n\nError nothing to do!\n\n
Usage: <script>  <../dir/*.ext>\n\n" ; exit 1; }

SCRIPT=$1
shift

for i in $@
do
    qsub $SCRIPT $i
done
