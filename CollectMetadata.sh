#/bin/bash

#########################################################################################################
## This script takes a file with list of protein accessions and collects metadata			#
## Results are saved in $2 - Protein Acc,Taxonomy ID,Species Name,Genome Accession,Lineage,Genus,URL	#
#########################################################################################################

touch $2
echo "ProteinAccession,TaxonomyID,SpeciesName,GenomeAccession,Lineage,Genus,URL" > $2
while read line
do
{
	taxid=`elink -db protein -id "$line" -target taxonomy | efetch -format uid`
	sciname=`elink -db protein -id "$line" -target taxonomy | esummary |xtract -element ScientificName`
	lineage=`elink -db protein -id "$line" -target taxonomy | efetch -format xml|xtract -pattern TaxaSet -element Lineage|sed 's/; /;/g'`
	genomeacc=`elink -db protein -id "$line" -target nuccore|efetch -format acc`
	genus=`echo $lineage|cut -f5 -d";"`
	echo $line,$taxid,$sciname,$genomeacc,$lineage,$genus,"http://www.ncbi.nlm.nih.gov/nuccore/"$genomeacc >> $2
	
	
}
done <$1
