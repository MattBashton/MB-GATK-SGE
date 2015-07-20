#! /usr/bin/perl -w
use strict;

# Matthew Bashton 2015
# This script takes a sample list of SM ids and runs PrintReads to extract the
# desired samples from the merged bam file.


my $list = $ARGV[0];
my $bam = $ARGV[1];

unless (defined $list) {
    die "\n*** You need to supply a file with each SM (sample ID from the \@RG line) on a new line, and the input .bam file to split as a second argument***\n\n";
}

my $count=1;


print "\n Input .bam is $bam\n\n";

open (INPUT, "$list");
while (<INPUT>) {
    if (/^(\S+)$/) {
	print "Submitting $count - $1\n";
	system "qsub PrintReads_for_sample.sh $1 $bam";
	$count++;
    }
}
close INPUT;
