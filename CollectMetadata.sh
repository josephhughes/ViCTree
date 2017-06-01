#/bin/bash

#########################################################################################################################################################
## This script takes a file with list of protein accessions and collects metadata									#
## Results are saved in $2 - ProteinAccession__GenomeAcc,GenomeAcc_ScientificName,TaxonomyID,ScientificName,Lineage,GenomeAccession,Genus,Species,URL	#
#########################################################################################################################################################

if [ -f $2 ]
then
    rm -f $2
    touch $2
fi
#echo "ProteinAccession__GenomeAcc,GenomeAcc_ScientificName,TaxonomyID,ScientificName,Lineage,GenomeAccession,Genus,Species,GenomeAcc_Lineage,ProteinAccession,URL" > $2
filename=$1
IFS=$'\n'
for line in `cat $filename`
do
{
 	taxonomy=`esearch -db protein -query "$line"|elink -target taxonomy |efetch -format xml|xtract -pattern Taxon -first TaxId ScientificName Lineage  -tab " "|sed 's/; /;/g;s/, /-/g;s/\t/,/g'`
		
	if [[ "$line" == *"_"*  ]];
	then
	
		genomeacc=`elink -db protein -id "$line" -target nuccore -batch|efetch -format docsum|xtract -pattern DocumentSummary -element AssemblyAcc`
	else
	
		genomeacc=`elink -db protein -id "$line" -target nuccore -batch|efetch -format acc`
	fi

	genus=`echo $taxonomy|cut -f $3 -d";"`
	species=`echo $taxonomy|awk -F ";" '{print $NF}'`
	sciname=`echo $taxonomy|cut -f2 -d ","`
	lineage=`echo $taxonomy|cut -f3 -d ","`
	if [ -z "$genus" ]
	then
	    genus="undef"
	fi
	if [ -z "$genomeacc" ]
	then
	    genomeacc="undef"
	fi
	if [ -z "$lineage" ]
	then
	    lineage="undef"
	fi
	if [ -z "$species" ]
	then
	    species="undef"
	fi
	if [ -z "$sciname" ]
	then
	    sciname="undef"
	fi
	if [ -z "$taxonomy" ]
	then
	    taxonomy="undef"
	fi   	
	echo $line"__"$genomeacc,$genomeacc"_"$sciname,$taxonomy,$genomeacc,$genus,$species,$genomeacc"_"$lineage,$line,$genomeacc >> $2
	
	
}
done
