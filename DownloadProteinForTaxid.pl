#!/usr/bin/perl

# use this compile the dataset from a particular taxonomic level
# for a particular protein specified by 1 or more seed protein sequences or nucleotide

# input will be a taxonomic id from Genbank taxonomy
# a fasta set of proteins from a gene of interest
# a threshold for the coverage of the protein relative to the reference protein

# Step 1: use eutil to download protein sequences for a particular taxnomic id
# Step 2: blast the protein sequences against the downloaded dataset (get all hits)
# Step 3: parse the results for sequences that have a coverage above the threshold specified

use Bio::DB::EUtilities;
use Bio::SeqIO;
use strict;

my $outfile=$ARGV[0];
my @ids=split(/,/,$ARGV[1]);

#my @ids     = qw/txid10292 txid548682/;
open (my $out, '>', "$outfile") || die "Can't open file:$!\n";

foreach my $id (@ids){
  # set optional history queue
  my $factory = Bio::DB::EUtilities->new(-eutil      => 'esearch',
                                       -email      => 'mymail@foo.bar',
                                       -db         => 'protein',
                                       -term       => "$id\[ORGN]",
                                       -usehistory => 'y');

  my $count = $factory->get_count;
  # get history from queue
  my $hist  = $factory->next_History || die 'No history data returned\n';
  print "History returned\n";
  # note db carries over from above
  $factory->set_parameters(-eutil   => 'efetch',
                         -rettype => 'fasta',
                         -history => $hist);

  my $retry = 0;
  my ($retmax, $retstart) = (500,0);


  RETRIEVE_SEQS:
  while ($retstart < $count) {
    $factory->set_parameters(-retmax   => $retmax,
                             -retstart => $retstart);
    eval{
        $factory->get_Response(-cb => sub {my ($data) = @_; print $out $data} );
    };
    if ($@) {
        die "Server error: $@.  Try again later\n" if $retry == 5;
        print STDERR "Server error, redo #$retry\n";
        $retry++ && redo RETRIEVE_SEQS;
    }
    print "Retrieved $retstart\n";
    $retstart += $retmax;
  }
  
}
close $out;