#! /usr/bin/perl -w
use strict;

# Matthew Bashton 2014
# This script takes a master list as tab-delimited input and runs BWA Picard to
# generate .bam files for input fastq / fastq.gz

my $list = $ARGV[0];

unless (defined $list) {
    die "\n*** You need to supply a tab-delimited file with the following cols: ***\n\nSample ID, Read group for BWA, fastq file 1, fastq file 2\n\nRead groups don't need to be quoted.\n\n";
}

my $count=1;

open (INPUT, "$list");
while (<INPUT>) {
    if (/^(\S+)\t(\S+)\t(\S+)\t(\S+)$/) {
	print "Submitting $count - $1\n";
	system "qsub BWA.sh $1 '$2' $3 $4";
	$count++;
    }
}
close INPUT;
