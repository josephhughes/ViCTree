#!/usr/bin/perl -w

# Use this to parse a blast output to get the hits that are longer op hit and CMTV hit, percent identity and more


use strict;
use Bio::SearchIO;
use Getopt::Long; 

my $cover=50; #percentage of the query that is covered
my $min_hit_len=700; #minimum length of the hit

my ($inblast,$inseq,$outfile,$indb);
&GetOptions(
	    'inblast:s'      => \$inblast,#the blast results
	    'out:s'   => \$outfile,#output if the gi IDs
	    'hit_length:i' => \$min_hit_len,
	    'cover:i' => \$cover,
           );

my $report_obj = new Bio::SearchIO(-format => 'blast',                                   
                                  -file   => "$inblast");   
                                  
open(LIST,">$outfile")||die "Can't open $outfile\n";
my %gi; 
while( my $result = $report_obj->next_result ) {  
  my $id=$result->query_name; 
  my $q_len=$result->query_length;
  while( my $hit = $result->next_hit ) {   
    my $hit_len=$hit->length;  
    if ($hit_len>$min_hit_len){  
      while( my $hsp = $hit->next_hsp ) {           
        my $hitname= $hit->name;
        my $hitdesc= $hit -> description;
        my $qid=$result->query_name;
        my $len = $hsp->hsp_length();
        if ((100*$len/$q_len)>$cover){
          print "$id\t$hitname\t$hit_len\t$len\n";
          $gi{$hitname}++;
        }elsif ((100*$len/$q_len)<=$cover){
          print "$id\t$hitname\n";
        }
      }     
    }
  }   
}

my $hitcnt=keys %gi;
print "Total number of hits = $hitcnt\n";
for my $gi (keys %gi){
  print LIST "$gi\n";
}