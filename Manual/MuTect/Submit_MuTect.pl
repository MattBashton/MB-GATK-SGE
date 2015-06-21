#! /usr/bin/perl -w
use strict;

# Matthew Bashton 2014
# This script takes a master list as tab-delimited input and runs MuTect

my $list = $ARGV[0];

unless (defined $list) {
    die "\n*** You need to supply a tab-delimited file with the following cols: ***\n\nNormal.bam, Tumor.bam\n\nRead groups don't need to be quoted.\n\n";
}

my $count=1;

open (INPUT, "$list");
while (<INPUT>) {
    if (/^(\S+)\t(\S+)$/) {
	print "Submitting $count - Normal: $1, Tumor: $2\n";
	system "qsub MT.sh $1 $2";
	$count++;
    }
}
close INPUT;
