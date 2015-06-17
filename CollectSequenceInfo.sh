#!/bin/bash

########################## ICTV Pipeline ################################################
# This script is written by Sejal Modha							#
#											#
# This script can be used to download sequences from NCBI				#
# and process them through this pipeline and produce a raxML tree as output		#
#-------------------------------------------------------------------------------	#
# This script is hardcoded to 								#
#											#					
# Usage:										#
#	./CollectSequenceInfo <options>							#
#	 OPTIONS:									#
#		-i Input file - tabular outpur from CompileSequences.pl(Required)	#
#		   e.g. txid40120_set_table.txt						#
#		-o Basename for output (required)					#	
#		-r Run this script with the params provided (Required)			#
#		-h Print usage help message (Optional)					#
#---------------------------------------------------------------------------------------#

usage=`echo -e "\n Usage: CollectSequenceInfo <OPTIONS>\n
		-i Input file - tabular outpur from CompileSequences.pl(Required)
		   e.g. txid40120_set_table.txt \n
		-o Basename for output (Required) \n
		-r Run this script with the params provided (Required) \n
		-h Print usage help message (Optional) \n"`;

if [[ ! $1 ]] 
then
	printf "${usage}\n\n";
exit;
fi


while getopts i:o:rh flag; do
  case $flag in
	
    i)
	input=`echo "$OPTARG"`;
	if [[ ! -f $input ]]
	then
		printf "$input file does not exist \n";
	else
		printf "Input file set to $input \n";
	fi
	#echo $seeds;
	;; 	

    o)
	out=`echo "$OPTARG"`;
	echo $out;
	;;
    r)
	touch ${out}_table;
	printf "Protein_GI\tNucleotide_GI\tGenome_Accession\tSpecies_Name\tDescription\n"> ${out}_table;
	cut -f1,4,7 $input >temp_table;
	cut -f1 $input > prot_gi_list;
	perl prot_gi_to_genome_acc.pl prot_gi_list > prot_gi_to_genome_acc;
	sed -i 's/Protein ID://g;s/Nuc ID://g;s/Genome Accession://g' prot_gi_to_genome_acc;
	join <(sort <(uniq prot_gi_to_genome_acc)) <(sort temp_table) -t $'\t' >>  ${out}_table;
	sed -i 's/TAXONOMY_SN://g;s/SEQ_ANNOTATION_DESC://g' ${out}_table;
	rm temp_table prot_gi_list prot_gi_to_genome_acc;
	;;
    h)
     	printf "${usage}\n\n";
	;;
    \?)
	echo -e "\n Option you selected doesn't exist \n Please use -h flag for usage";
	exit;
      ;;
  esac
done
