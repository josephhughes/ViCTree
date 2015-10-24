#!/usr/bin/perl

# use this to compile the filtered sequences

# and rename them according to species names


use Bio::DB::EUtilities;
use Bio::SeqIO;
use strict;

my $infasta = $ARGV[0];
my $list = $ARGV[1];
my $outstub=$ARGV[2];
my %ids;

my $lineage;

open (LIST,"<$list")||die "can't open $list\n";
while(<LIST>){
  chomp($_);
  $ids{$_}++;
}
open(TABLE,">$outstub\_table.txt")||die "Can't open $outstub\_table.txt\n";
my $seq_in  = Bio::SeqIO->new(-format => 'fasta',-file   => $infasta,);
my $seq_out = Bio::SeqIO->new(-format => 'fasta',-file   => ">$outstub\.fa",);
while( my $seq = $seq_in->next_seq() ) {
  my $id=$seq->display_id();
  if ($ids{$id}){
	# rename the id according to accession number and organism name
    my $gi=$1 if $id=~/gi\|(\d+)\|.+/;
    $seq->display_id($gi);
    $seq_out->write_seq($seq);
    my $factory = Bio::DB::EUtilities->new(-eutil  => 'elink',
                                       -email  => 'mymail@foo.bar',
                                       -db     => 'taxonomy',
                                       -dbfrom => 'protein',
                                       -id     => $gi);
    # iterate through the LinkSet objects
    my ($taxid);
    while (my $ds = $factory->next_LinkSet) {
      #print "   Link name: ",$ds->get_link_name,"\n";
      #print "Protein IDs: ",join(',',$ds->get_submitted_ids),"\n";
      $taxid=join(',',$ds->get_ids),"\n";
     # print "    Taxid: ",join(',',$ds->get_ids),"\n";
     # print "$taxid\n";
      my $factory = Bio::DB::EUtilities->new(-eutil => 'esummary',
                                                -email => 'mymail@foo.bar',
                                                -db    => 'taxonomy',
                                                -id    => $taxid );
     my ($name)  = $factory->next_DocSum->get_contents_by_name('ScientificName');
    # print "$name\n";
####Edited by SM - need to fix the STDOUT error
   system ($lineage=`xmllint  --xpath "/eSearchResult/IdList/Id/text()" "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=taxonomy&term=${name}[SCIN]"| xargs -I TAXON xmllint --noout --xpath "/TaxaSet/Taxon/Lineage/text()" "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=taxonomy&id=TAXON&retmode=xml&rettype=full"`);

   print "$lineage\n";

   print TABLE "$gi\tTAXONOMY_ID:$taxid\tTAXONOMY_ID_PROVIDER:ncbi\tTAXONOMY_SN:$name\tSEQ_ACCESSION:$gi\tSEQ_ACCESSION_SOURCE:gi\tSEQ_ANNOTATION_DESC:$id\tLINEAGE:$lineage\n";
}
  }elsif (!$ids{$id}){
    #print "$id does not exist in the file $list\n";	
  }	
}

