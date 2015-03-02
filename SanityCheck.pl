#!/usr/bin/perl

# use this to check the fasta file for good quality sequences

use Bio::SeqIO;
use strict;
my $file=$ARGV[0];
my $outfile=$ARGV[1];

my $inseq = Bio::SeqIO->new(-file => "$file" ,
                         -format => 'fasta');

my $outseq = Bio::SeqIO->new(-file => ">$outfile" ,
                         -format => 'fasta');

my $missing_seq=0;
while ( my $seq_obj = $inseq->next_seq() ) {  
   my $id=$seq_obj->display_id;
   my $seq=$seq_obj->seq;
   if ($seq=~/./){
    $outseq->write_seq($seq_obj);
   }else{
    $missing_seq++;
  }
}

print "$missing_seq missing sequences\n";