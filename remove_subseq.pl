#!/usr/bin/perl
#	Input file: a fasta file
#	Output file: a unique fasta file
#	System Requirements: linux, perl
#	Usage: perl remove_subseq.pl infile.fasta 
################################################################################
use strict;
use warnings;
#read the file into a hash
my %seq;
my $title;
my $infile=$ARGV[0];# shift or die "give me a infile\n";
my $outfile=$ARGV[1];# or die "give me a outfile\n";
open (IN,"$infile");
while (<IN>){
	$_=~s/\n//;
	$_=~s/\r//;
	if ($_=~/>/){
		$title=$_;
		$title=~s/>//;
	}
	else{
		$seq{$_}=$title;
	}
}
close IN;
#remove the abundant sequences
my @seq=keys (%seq);
my @uniqueseq;
my $find=0;
foreach (@seq){
	$find=0;
	my $seq=uc($_);
	foreach (@uniqueseq){
		if ($seq=~/$_/){
			$_=$seq;#replace with longer seq
			$find=1;
		}
		if ($_=~/$seq/){
			$find=1;
		}
	}
	if ($find==0){
		push @uniqueseq,$seq;
	}
}
#outout the final result
#open (OUT,">output.fasta");
open (OUT,">$outfile");
foreach (@uniqueseq){
	print OUT ">$seq{$_}\n$_\n";
}
close OUT;
