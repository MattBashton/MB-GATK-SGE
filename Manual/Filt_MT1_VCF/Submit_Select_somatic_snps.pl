#! /usr/bin/perl -w
use strict;

# Matthew Bashton 2014-2015
# This script takes a master list as tab-delimited input used for running MuTect
# the 2nd col somatic variants are then split out form the MuTect VCF via SGE
# jobs.

my $list = $ARGV[0];

unless (defined $list) {
    die "\n*** You need to supply a tab-delimited file with the following cols: ***\n\nNormal.bam, Tumor.bam\n\nRead groups don't need to be quoted.\n\n";
}

my $count=1;

open (INPUT, "$list");
while (<INPUT>) {
    if (/^(\S+)\.bam\t(\S+)\.bam$/) {
	print "Submitting job No. $count, to extract somatic SNPs for sample: $2 from MuTect output: $1.vs.$2.vcf\n";
	system "qsub Select_somatic_snps.sh ../MuTect/$1.vs.$2.vcf $2";
	$count++
    }
}
close INPUT;
