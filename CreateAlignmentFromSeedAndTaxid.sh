# bash script

# project name
name="Herpesviridae"
# taxonomic id
id="txid10292"
# the file name with the seed sequences
seed="SeedSet.fa"
# hit_length
hit_length=1000
# coverage of the hit as a percentage
cover=70

# may need to change the script below to specify the taxid from the command line
#perl ~/Documents/ICTV/Scripts/DownloadProteinForTaxid.pl
#perl DownloadProteinForTaxid.pl seqtest.fa txid10292,txid548682
#######perl DownloadProteinForTaxid.pl ${name}.fa $id

# report how many have been downloaded

# formatdb for the protein set
# error as some sequences don't have sequences
# need a sanity check of the sequences downloaded
# report how many have been excluded

 #####perl SanityCheck.pl ${name}.fa ${name}_checked.fa
 
 #####formatdb -i ${name}_checked.fa -p T
 
#### blastall -p blastp -i $seed -d ${name}_checked.fa -o ${name}_blastp.txt -e 1 -v 1000000 -b 1000000
 
 # specify the length of a protein to include and
 # the proportion of the seed sequences that need to overlap with it
 # (not the percent identity) but the number of aa that align
 # default length is 700 and cover of 50%
perl BlastParseToList.pl -inblast ${name}_blastp.txt -out ${name}_filtered.txt -hit_length $hit_length -cover $cover
 
 # the next step is to filter so we only have one 
 # sequence per organism, ideally the reference sequence
 # and if not reference can be identified, the longest one
# We don't really know what we want included at this stage as we do
# not have a clear idea of the phylogeny/taxonomy
# everything needs to be included
# Getting species name and additional information from GenbBank

#perl CompileSequences.pl ${name}_checked.fa ${name}_filtered.txt ${name}_set

#clustalo -i ${name}_set.fa -o ${name}_set_aln.fa

Fasta2Phy.pl ${name}_set_aln.fa ${name}_set_aln.phy

raxmlHPC -m PROTGAMMAGTR -p 12345 -x 12345 -# 100 -s ${name}_set_aln.phy -n $name


# create a phyloxml tree
# https://sites.google.com/site/cmzmasek/home/software/forester/decorator
# create svg graphics from phyloxml
# http://www.jsphylosvg.com
