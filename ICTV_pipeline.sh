#!/bin/bash

########################## ICTV Pipeline ########################################
# This script is written by Sejal Modha						#
#										#
# This script can be used to download sequences from NCBI			#
# and process them through this pipeline and produce a raxML tree as output	#
#-------------------------------------------------------------------------------#
# This script is hardcoded to 							#
#	* Use a number of scripts including 					#
#		* DownloadProteinForTaxid.pl					#
#		* SanityCheck.pl						#
#		* BlastParseToList.pl						#
#		* CompileSequences.pl						#
#	  	* remove_subseq.pl						#
#										#
# Usage:									#
#	./ICTV_pipeline <options>						#
#	 OPTIONS:								#
#		-t Taxa ID (Required)
#		-s Seed Set - Fasta (Required)
#		-l Hit Length for BLAST (Required)
#		-c Coverage for BLAST (Required)
#		-r Run pipeline with specified parameters (Required) 
#		-h Print usage help message (Optional)				#
#-------------------------------------------------------------------------------#

usage=`echo -e "\n Usage: ICTV_pipeline <OPTIONS> \n\n
		-t Taxa ID (Required) \n 
		-s Seedset in fasta format (Required) \n
		-l Hit Length for BLAST (Required) \n
		-c Coverage for BLAST (Required) \n
		-r Run pipeline with specified parameters (Required) \n 
		-h This helpful message\n"`;

if [[ ! $1 ]] 
then
	printf "${usage}\n\n";
exit;
fi

alpha='[a-zA-Z]';

while getopts t:s:l:c:hr flag; do
  case $flag in

    t)
	taxid=`echo "$OPTARG"`;
	if [[ $taxid =~ .*$alpha.* ]]
        then
		printf "Invalid Taxa ID: Please enter a valid Taxa ID. \n";
	else
		tid=`echo txid$taxid`;
		printf "TaxaID validated \nRunning pipeline for Taxa ID $tid \n";	
        fi
	
#	echo $taxid;
	;;
    s)
	seeds=`echo "$OPTARG"`;
	if [[ ! -f $seeds ]]
	then
		printf "$seeds file does not exist \n";
	else
		printf "Seed set is set to $seeds \n";
	fi
	#echo $seeds;
	;; 
    l)
	len=`echo "$OPTARG"`;
	#echo $len;
	if [[ $len =~ .*$alpha.* ]]
        then
		printf "Invalid Length: Please enter a valid length value. \n";
	else
		printf "BLAST length is set to $len \n";	
        fi
	;;
    c)
	cover=`echo "$OPTARG"`;
	if [[ $cover =~ .*$alpha.* ]]
        then
		printf "Invalid Coverage Value: Please enter a valid Taxa ID. \n";
	else
		printf "Coverage value for BLAST is set to $cover \n";
        fi	
	;;
    r)
	printf "Now Downloading all protein sequences from NCBI for taxid $tid \n";	
	echo "-----------------Running Step 1 of Pipeline --------------------";
	perl DownloadProteinForTaxid.pl $tid.fa $tid;
	echo "-----------------Running Step 2 of Pipeline --------------------";
	printf "Sequences downloaded successfully now running sanity check on them\n";
	perl SanityCheck.pl $tid.fa ${tid}_checked.fa;
	echo "-----------------Running Step 3 of Pipeline --------------------";	
	printf "Creating BLAST databases\n";
	formatdb -i ${tid}_checked.fa -p T
	echo "-----------------Running Step 4 of Pipeline --------------------";
	printf "Running BLASTP \n";
	blastall -p blastp -i $seeds -d ${tid}_checked.fa -o ${tid}_blastp.txt -e 1 -v 1000000 -b 1000000
	echo "-----------------Running Step 5 of Pipeline --------------------";
	printf "Compiling Sequences \n";
	perl BlastParseToList.pl -inblast ${tid}_blastp.txt -out ${tid}_filtered.txt -hit_length $len -cover $cover;
	perl CompileSequences.pl ${tid}_checked.fa ${tid}_filtered.txt ${tid}_set;
	#combine seeds and blast sets
	cat ${tid}_set.fa $seeds > ${tid}_set_seeds_combined.fa;
	echo "Removing Exact Duplicates";
	#fasta_formatter -i ${tid}_set_seeds_combined.fa -o ${tid}_set_seeds_combined_formatted.fa	
	#prinseq sometimes keep two copies of a seq - reason unknown - find alternative?
	# bash solution to remove exact dups however it doesn't keep track of removed seqs
	#fasta_formatter -t -i ${tid}_set_seeds_combined.fa  |sort -u -t $'\t' -f -k 2,2  | sed -e 's/^/>/' -e 's/\t/\n/';	
	prinseq -fasta ${tid}_set_seeds_combined.fa -derep 1 -out_good ${tid}_combined_set_dups_removed -out_bad ${tid}_set_dups
	fasta_formatter -i ${tid}_combined_set_dups_removed.fasta -o ${tid}_combined_set_dups_removed_formatted.fa
	#grep -c "^>" ${tid}_combined_set_dups_removed_formatted.fa;
	echo "Removing Shorter Sequences";
	perl remove_subseq.pl ${tid}_combined_set_dups_removed_formatted.fa ${tid}_final_set.fa;
	#grep -c "^>" ${tid}_final_set.fa;
	perl -p -i -e 's/>(.+?) .+/>$1/g' ${tid}_final_set.fa;
	echo "-----------------Running Step 6 of Pipeline --------------------";
	printf "Running Multiple Sequence Alignments Using CLUSTALO \n"; 
	clustalo -i ${tid}_final_set.fa -o ${tid}_final_set_clustalo_aln.phy --outfmt="phy" --force --full --distmat-out=${tid}_clustalo_dist_mat
	
	echo "-----------------Running Step 7 of Pipeline --------------------";
	printf "Grouping identical sequences \n"; 
	perl -p  -e 's/>(.+?) .+/>$1/g' ${tid}_set_seeds_combined.fa | fasta_formatter -t |awk -v OFS='\t' -F "\t" '{t=$1; $1=$2; $2=t; print}' | sort | awk -F "\t" '{if($1==seq) {printf("\t%s",$2)} else { printf("\n%s",$0); seq=$1;}};END{printf "\n"}' > seq_id_grouped
	# Combine file specified in above additional step to provide a list of representative set as well as the extended set
	fasta_formatter -t -i ${tid}_final_set.fa | cut -f1 > file_with_id_list
	bash find_ids.sh file_with_id_list seq_id_grouped |  sed  -e '1iRepresentative_GI\tProtein_Sequence\tExtended_GI_List' > ${tid}_seq_info 
	rm file_with_id_list seq_id_grouped ${tid}_set_seeds_combined.fa ${tid}_set.fa ${tid}_combined_set_dups_removed_formatted.fa ${tid}_checked.fa*  ${tid}_blastp.txt
	echo "-----------------Running Step 8 of Pipeline --------------------";
	printf "Running Phylogenetic Analysis using RAXML \n";
	raxmlHPC-PTHREADS -T 10 -f a -m PROTGAMMAGTR -p 12345 -x 12345 -# 100 -s ${tid}_final_set_clustalo_aln.phy -n $tid	
	
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
