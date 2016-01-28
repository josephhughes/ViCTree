#!/bin/bash

########################## ICTV Pipeline ########################################
# This script is written by Sejal Modha											#
#																				#
# This script can be used to download sequences from NCBI						#
# and process them through this pipeline and produce a raxML tree as output		#
#-------------------------------------------------------------------------------#
# This script is hardcoded to 													#
#	* Use a number of scripts including 										#
#		* DownloadProteinForTaxid.pl											#
#		* SanityCheck.pl														#
#		* BlastParseToList.pl													#
#		* CompileSequences.pl													#
#	  	* remove_subseq.pl														#
#																				#
# Usage:																		#
#	./ICTV_pipeline <options>													#
#	 OPTIONS:																	#
#		-t Taxa ID (Required)
#		-s Seed Set - Fasta (Required)
#		-l Hit Length for BLAST (Required)
#		-c Coverage for BLAST (Required)
#		-r Run pipeline with specified parameters (Required) 
#		-h Print usage help message (Optional)									#
#		-m Specify model for RAxML (Default is PTRGAMMJTT)
#-------------------------------------------------------------------------------#

usage=`echo -e "\n Usage: ICTV_pipeline <OPTIONS> \n\n
		-t Taxa ID - INT(Required) \n 
		-s Seedset in fasta format (Required) \n
		-l Hit Length for BLAST - INT(Required) \n
		-c Coverage for BLAST -INT(Required) \n
		-r Run pipeline with specified parameters (Required) \n 
		-h This helpful message\n
		-m Specify model for RAxML (Default is PTRGAMMJTT)"`;

if [[ ! $1 ]] 
then
	printf "${usage}\n\n";
exit;
fi

alpha='[a-zA-Z]';
raxml='PROTGAMMAJTT';
while getopts t:s:l:c:m:hr flag; do
  case $flag in

    t)
	taxid=`echo "$OPTARG"`;
	if [[ $taxid =~ .*$alpha.* ]]
        then
		printf "\n!!!! Invalid Taxa ID: Please enter a valid Taxa ID !!!! \nExample: 40120\n";
		exit 1;
	else
		tid=`echo txid$taxid`;
		if [ ! -d "$tid" ]; then
		mkdir $tid;
		fi
		printf "\nTaxaID validated \n\nRunning pipeline with following parameters:\n\nTaxa ID\t\t: $tid \n";	
        fi
	
#	echo $taxid;
	;;
    s)
	seeds=`echo "$OPTARG"`;
	if [[ ! -f $seeds ]]
	then
		printf "$seeds file does not exist \n";
		exit 1;
	else
		printf "Seed set\t: $seeds \n";
	fi
	#echo $seeds;
	;; 
    l)
	len=`echo "$OPTARG"`;
	#echo $len;
	if [[ $len =~ .*$alpha.* ]]
        then
		printf "\n!!!! Invalid Length: Please enter a valid length value !!!! \n";
		exit 1;
	else
		printf "BLAST length\t: $len \n";	
        fi
	;;
    c)
	cover=`echo "$OPTARG"`;
	if [[ $cover =~ .*$alpha.* ]]
        then
		printf "\n!!!! Invalid Coverage Value: Please enter a valid coverage value !!!! \n";
		exit 1;
	else
		printf "BLAST coverage\t: $cover \n\n";
        fi	
	;;
    m)
	raxModel=`echo "$OPTARG"`;
	if [[ -z $raxModel ]]
		then
		raxModel=$raxml;
		printf "Selecting default RAxML model PROTGAMMAJTT \n";
	else
		raxml=$raxModel;
		printf "RAxML model set to $raxModel \n";
		fi	
	;;
	r)
	
	printf "Now Downloading all protein sequences from NCBI for taxid $tid \n";
	echo "-----------------Running Step 1 of Pipeline --------------------";

	perl DownloadProteinForTaxid.pl $tid/$tid.fa $tid;
	echo "-----------------Running Step 2 of Pipeline --------------------";

	printf "Sequences downloaded successfully now running sanity check on them\n";
	perl SanityCheck.pl $tid/$tid.fa $tid/${tid}_checked.fa;

	echo "-----------------Running Step 3 of Pipeline --------------------";	
	printf "Creating BLAST databases\n";
	
	formatdb -i $tid/${tid}_checked.fa -p T

	echo "-----------------Running Step 4 of Pipeline --------------------";
	printf "Running BLASTP \n";

	blastall -p blastp -i $seeds -d $tid/${tid}_checked.fa -o $tid/${tid}_blastp.txt -e 1 -v 1000000 -b 1000000

	echo "-----------------Running Step 5 of Pipeline --------------------";
	printf "Compiling Sequences \n";

	perl BlastParseToList.pl -inblast $tid/${tid}_blastp.txt -out $tid/${tid}_filtered.txt -hit_length $len -cover $cover;
	perl CompileSequences.pl $tid/${tid}_checked.fa $tid/${tid}_filtered.txt $tid/${tid}_set > /dev/null 2>&1;

	#combine seeds and blast sets
	cat $tid/${tid}_set.fa $seeds > $tid/${tid}_set_seeds_combined.fa;
	echo "Removing Exact Duplicates";
	#prinseq sometimes keep two copies of a seq - reason unknown - find alternative?
	#prinseq -fasta $tid/${tid}_set_seeds_combined.fa -derep 1 -out_good $tid/${tid}_combined_set_dups_removed -out_bad $tid/${tid}_set_dups
	# bash solution to remove exact dups however it doesn't keep track of removed seqs
	#fasta_formatter -t -i ${tid}_set_seeds_combined.fa  |sort -u -t $'\t' -f -k 2,2  | sed -e 's/^/>/' -e 's/\t/\n/';	

	## Truncate seq ID in fasta file
	perl -p -i -e 's/>(.+?) .+/>$1/g' $tid/${tid}_set_seeds_combined.fa
	# Sort and group exact same sequences in a table and sort gi to generate a fasta with oldest gi as description and sequence
	fasta_formatter -t -i $tid/${tid}_set_seeds_combined.fa |sort -t $'\t' -f -k 2,2 -k 1,1n|awk -F'\t' -v OFS='\t' '{x=$2;$2="";a[x]=a[x]$0}END{for(x in a)print x,a[x]}' > ${tid}/${tid}_sequences_grouped
	
	awk -F$'\t' '{print ">"$2"\n"$1}' ${tid}/${tid}_sequences_grouped >$tid/${tid}_combined_set_dups_removed.fa
	fasta_formatter -i $tid/${tid}_combined_set_dups_removed.fa -o $tid/${tid}_combined_set_dups_removed_formatted.fa
	
	echo "Removing Shorter Sequences";
	perl remove_subseq.pl $tid/${tid}_combined_set_dups_removed_formatted.fa $tid/${tid}_final_set.fa;

	echo "-----------------Running Step 6 of Pipeline --------------------";
	printf "Running Multiple Sequence Alignments Using CLUSTALO \n"; 
	clustalo -i $tid/${tid}_final_set.fa -o $tid/${tid}_final_set_clustalo_aln.phy --outfmt="phy" --force --full --distmat-out=$tid/${tid}_clustalo_dist_mat

	echo "-----------------Running Step 7 of Pipeline --------------------";
	printf "Grouping identical sequences \n"; 

	perl -p  -e 's/>(.+?) .+/>$1/g' $tid/${tid}_set_seeds_combined.fa | fasta_formatter -t |awk -v OFS='\t' -F "\t" '{t=$1; $1=$2; $2=t; print}' | sort | awk -F "\t" '{if($1==seq) {printf("\t%s",$2)} else { printf("\n%s",$0); seq=$1;}};END{printf "\n"}' > seq_id_grouped
	# Combine file specified in above additional step to provide a list of representative set as well as the extended set
	fasta_formatter -t -i $tid/${tid}_final_set.fa | cut -f1 > file_with_id_list
	bash find_ids.sh file_with_id_list seq_id_grouped |  sed  -e '1iRepresentative_GI\tProtein_Sequence\tExtended_GI_List' > $tid/${tid}_seq_info 
	rm file_with_id_list seq_id_grouped $tid/${tid}_set_seeds_combined.fa $tid/${tid}_set.fa $tid/${tid}_combined_set_dups_removed_formatted.fa $tid/${tid}_checked.fa*  $tid/${tid}_blastp.txt


	echo "-----------------Running Step 8 of Pipeline --------------------";
	printf "Running Phylogenetic Analysis using RAXML \n";
	printf "RAxML model is set to $raxml \n\n";
	cd $tid;
	printf "raxmlHPC-PTHREADS -T 10 -f a -m $raxml -p 12345 -x 12345 -# 100 -s ${tid}_final_set_clustalo_aln.phy -n $tid \n";
	raxmlHPC-PTHREADS -T 10 -f a -m $raxml -p 12345 -x 12345 -# 100 -s ${tid}_final_set_clustalo_aln.phy -n $tid;
	
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
