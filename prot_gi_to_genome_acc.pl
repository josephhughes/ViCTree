#!/usr/bin/perl
# This script can take a list of protein GIs as input and fetches nucleotide GI, genome accession number from NCBI
use Bio::DB::EUtilities;

#my @ids     = qw(817524604 726965494);

my $infile = $ARGV[0];
#my $outfile = $ARGV[1];
my @ids;
#my (%taxa, @taxa);
my (%names, %idmap);
open (IN,"$infile")||die "can't open $infile\n";

while(<IN>)
{
	chomp($_);
#	$ids{$_}++;
	my @ids=$_;
#	print @ids."\n";	
 
my $factory = Bio::DB::EUtilities->new(-eutil          => 'elink',
                                       -email          => 'mymail@foo.bar',
                                       -db             => 'nucleotide',
                                       -dbfrom         => 'protein',
                                       #-correspondence => 1,
                                       -id             => \@ids);
 
	# iterate through the LinkSet objects
	while (my $ds = $factory->next_LinkSet) 
	{
		#print "   Link name: ",$ds->get_link_name,"\n";
		my $protid = join(',',$ds->get_submitted_ids);
		print "Protein ID:" . $protid ."\t";
		#print "Protein ID: ",join(',',$ds->get_submitted_ids),"\t";
		my $nucid = join(',',$ds->get_ids);
		print "Nuc ID:" . $nucid ."\t";
	
my $factory = Bio::DB::EUtilities->new(-eutil   => 'efetch',
					-db      => 'nucleotide',
					-id      => $nucid,
                                       	-email   => 'mymail@foo.bar',
                                       	-rettype => 'acc');
 
my @accs = split(m{\n},$factory->get_Response->content);
 
	print "Genome Accession: " .join(',',@accs), "\n";

	}
}

close(<IN>);
