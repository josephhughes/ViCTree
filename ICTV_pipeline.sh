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
#		-t Taxa ID (Required)						#
#		-s Seed Set - Fasta (Required)					#
#		-l Hit Length for BLAST (Required)				#
#		-c Coverage for BLAST (Required)				#
#		-h Print usage help message (Optional)				#
#		-m Specify model for RAxML (Default is PTRGAMMJTT)		#
#		-i Identity for clustering sequences using cdhit 		#
#		-n Output name of the virus family or sub-family 		#
#		-p Number of threads"`;						#
#		-u A file with user-defined list of accessions"`;	#
#-------------------------------------------------------------------------------#

usage=`echo -e "\n Usage: ICTV_pipeline <OPTIONS> \n\n
		-t Taxa ID - INT(Required) \n 
		-s Seedset in fasta format (Required) \n
		-l Hit Length for BLAST - INT(Required) \n
		-c Coverage for BLAST -INT(Required) \n
		-h This helpful message\n
		-m Specify model for RAxML (Default is PTRGAMMJTT)\n
		-i Identity for clustering sequences using cdhit \n
		-n Output name of the virus family or sub-family \n
		-p Number of threads \n
		-u A file with user-defined list of accessions"`;

if [[ ! $1 ]] 
then
	printf "${usage}\n\n";
exit;
fi

alpha='[a-zA-Z]';
raxml='PROTGAMMAJTT';
threads='2';
genus=5;
while getopts t:s:l:c:m:p:i:n:u:h flag; do
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

	;;
    s)
	seeds=`echo "$OPTARG"`;
	
	if [[ ! -f $seeds ]]
	then
		printf "\nSpecified seeds file $seeds file does not exist \n \n";
		exit 1;
	else
		printf "Seed set\t: $seeds \n";
	fi
	#echo $seeds;
	;; 
    l)
	len=`echo "$OPTARG"`;
	
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
		printf "BLAST coverage\t: $cover \n";
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
     p)
	proc=`echo "$OPTARG"`;
	
	if [[ $proc =~ .*$alpha.* ]]
    	then
		printf "\n!!!! Invalid Number of Threads: Please enter a valid number of threads !!!! \n";
		exit 1;
	elif [[ -z $proc ]]
	then
		proc=`echo $threads`;
		printf "Default threads $threads \n";
	else
		printf "No of threads\t: $proc \n"; 	
	fi
	;;
     i)
	identity=`echo "$OPTARG"`;
	
	if [[ $identity =~ .*$alpha.* ]]
    	then
		printf "\n!!!! Invalid sequence identity value: Please enter a valid number of threads !!!! \n";
		exit 1;
	elif [[ -z $identity ]]
	then
		$identity="1.0";
		printf "Default Identity set to 100% \n";
	else
		printf "Identity \t: $identity \n"; 	
    	fi
	;;
      n)
	name=`echo $OPTARG`;
	if [[ -z $name ]]
	then
		printf "\n!!!! Must specify a family or sub-family name !!!! \n"
	else
		name=$name;
		printf "\nName set to $name \n\n";
	fi
	if [[ $name == *dae ]]
	then
		$genus=6
	elif [[ $name == *nae ]]
	then
		genus=5
	else
		printf "\n Virus family or sub-family name must end with either "dae" or "nae" \n"

	fi
	;;
      u)
	ulist=`echo "$OPTARG"`;
	if [[ ! -f $ulist ]]
	then
		printf "\nSpecified accession number file $ulist file does not exist \n \n";
		exit 1;
	else
		printf "Pipeline will re-set the accession numbers according to the\t: $ulist \n";
	fi
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

shift $(($OPTIND - 1))

if [ -z $taxid ]
then
    printf "\nTaxonomy ID must be specified with -t parameter\n" >&2
    exit 1
fi

if [ -z $cover ]
then
    printf "\nBLAST coverage must be specified with -c parameter\n" >&2
    exit 1
fi

if [ -z $len ]
then
    printf  "\nBLAST length must be specified with -l parameter\n" >&2
    exit 1
fi

if [ -z $seeds ]
then
    printf  "\nSeed file must be specified in fasta format using -s parameter\n" >&2
    exit 1
fi

if [ -f "$tid/${tid}.fa" ];
then
	printf "Previous analysis results exist, checking if any new sequences are submitted to GenBank\n\n"
	seq=`grep -c  "^>" $tid/${tid}.fa`;
	count=`esearch -db taxonomy -query "$tid[Organism]"|elink -target protein|xtract -element Count`;
	if [ "$seq" == "$count" ]
	then
		printf "No new sequences available in GenBank, ViCTree analysis for $tid is up-to-date\n\n" 
		exit 1
	fi
fi

##########################
# Processing begins here
##########################
printf "\nNow Downloading all protein sequences from NCBI for taxid $tid \n";
echo "-----------------Running Step 1 of Pipeline --------------------";
#perl DownloadProteinForTaxid.pl $tid/$tid.fa $tid;
echo  "Downloading sequences from NCBI"
echo $tid;
esearch -db taxonomy -query "$tid[Organism]"|elink -target protein -batch|efetch -format fasta > $tid/${tid}.fa
echo "-----------------Running Step 2 of Pipeline --------------------";

printf "Sequences downloaded successfully now running sanity check on them\n";
perl SanityCheck.pl $tid/$tid.fa $tid/${tid}_checked.fa;
# re-format sequences to suit newer version of NCBI fasta headers
sed -i 's/gi|[0-9]*|[a-z]*|//g;s/|//;s/\.[1-9].*//g' $tid/${tid}_checked.fa

echo "-----------------Running Step 3 of Pipeline --------------------";	
printf "Creating BLAST databases\n";
	
makeblastdb -in $tid/${tid}_checked.fa -dbtype 'prot'

echo "-----------------Running Step 4 of Pipeline --------------------";
printf "Running BLASTP \n";

blastp -query $seeds -db $tid/${tid}_checked.fa -out $tid/${tid}_blastp.txt -evalue 1 -num_alignments 1000000 -num_descriptions 1000000

echo "-----------------Running Step 5 of Pipeline --------------------";
printf "Compiling Sequences \n";

perl BlastParseToList.pl -inblast $tid/${tid}_blastp.txt -out $tid/${tid}_filtered.txt -hit_length $len -cover $cover;
grep --no-group-separator -A 1 -f $tid/${tid}_filtered.txt <(awk -v ORS= '/^>/ { $0 = (NR==1 ? "" : RS) $0 RS } END { printf RS }1' $tid/${tid}_checked.fa) >$tid/${tid}_set.fa
cat $tid/${tid}_set.fa $seeds > $tid/${tid}_set_seeds_combined.fa;

echo "-----------------Running Step 6 of Pipeline --------------------";
printf "Clustering identical sequences \n"; 

########################################################################################################
#Check if previous cd-hit analysis exist and if any new clusters are formed with newly added sequences
########################################################################################################
if [ -f "$tid/${tid}_final_set.clstr" ];
then
	printf "Previous cd-hit analysis results exist, checking if any new clusters are formed\n\n"
	clustold=`grep -c  "^>" $tid/${tid}_final_set.clstr`;
	printf "Number of clusters in the existing analysis $clust\n\n"
	
	cd-hit -i $tid/${tid}_set_seeds_combined.fa -o $tid/${tid}_final_set -c $identity -t 1
	mv $tid/${tid}_final_set $tid/${tid}_final_set.fa
	grep "^>" $tid/${tid}_final_set.fa |sed 's/>//' > $tid/${tid}_cdhit_rep_accession
	
	###########################################
	# Convert cd-hit raw output to csv format
	###########################################
	clstr2txt.pl $tid/${tid}_final_set.clstr|tr "\t" ","|awk 'BEGIN{ FS = ","; OFS = "," }; {if($5==1){ $5=$1} print}' > $tid/${tid}_final_set_cdhit_clusters.csv
	awk -F"," '{if($5!=0) print $1","$2}' $tid/${tid}_final_set_cdhit_clusters.csv|tail -n +2 >$tid/${tid}_cluster_reps
	awk -F"," 'FNR==NR{a[$2]=$0;next}{if(b=a[$2]) {print $0","a[$2]}}' $tid/${tid}_cluster_reps $tid/${tid}_final_set_cdhit_clusters.csv |cut -f1,3,4,8 -d ","|sed -e '1iAccessionNumber,ClusterSize,Length,ClusterRepresentative\'> $tid/${tid}_clusters_info.csv
		
	clustnew=`grep -c  "^>" $tid/${tid}_final_set.clstr`;
	
	####################################################
	# Reset the cd-hit cluster ID to userdefined list
	####################################################
	if [ -f "$ulist" ];
	then
		echo "Precompiled list of accession is provided, now resetting the centroids \n"
		grep -f "$ulist" $tid/${tid}_final_set_cdhit_clusters.csv|cut -f1-2 -d ","|sort -k2 -n -u -t',' > $tid/id_to_reset
		grep -f "$ulist" $tid/${tid}_final_set_cdhit_clusters.csv|cut -f1-2 -d ","| uniq|diff <(cut -f2 -d ",") <(seq 0 $clustnew)|grep ">"|cut -c 3- > $tid/cluster_no_rep
		grep -wf $tid/cluster_no_rep <(cut -f1-2,5 -d "," $tid/${tid}_final_set_cdhit_clusters.csv)|awk -F "," '{if($3!=0) print}' |cut -f1,2 -d"," > $tid/id_not_reset
		cat <(cut -f1 -d "," $tid/id_to_reset) <(cut -f1 -d "," $tid/id_not_reset) > $tid/${tid}_cdhit_rep_accession
		cat $tid/id_to_reset $tid/id_not_reset |sort -k2 -n -t ','> $tid/${tid}_cluster_reps
		awk -F"," 'FNR==NR{a[$2]=$0;next}{if(b=a[$2]) {print $0","a[$2]}}' $tid/${tid}_cluster_reps $tid/${tid}_final_set_cdhit_clusters.csv |cut -f1,3,4,8 -d ","|sed -e '1iAccessionNumber,ClusterSize,Length,ClusterRepresentative\'> $tid/${tid}_clusters_info.csv
		
		grep --no-group-separator -A1 -f $tid/${tid}_cdhit_rep_accession <(awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' $tid/${tid}_set_seeds_combined.fa)|awk '/^>/{f=!d[$1];d[$1]=1}f' > $tid/${tid}_final_set.fa
		temp=`awk 'BEGIN{RS=">"}{gsub("\n","\t",$0); print ">"$0}' $tid/${tid}_final_set.fa |cut -f1|sed 's/>//g'`
		for x in $(echo $temp)
		do
			if [[ "$x" == *"_"*  ]];
			then
				z=`elink -db protein -target nuccore -id "$x" -batch|esummary|xtract -element AssemblyAcc`;
				sed -i "s/$x/$x"__"$z/g" $tid/${tid}_final_set.fa
			else
				y=`elink -db protein -target nuccore -id "$x" -batch |efetch -format acc`
				sed -i "s/$x/$x"__"$y/g" $tid/${tid}_final_set.fa
			fi
		done
		rm $tid/id_not_reset $tid/cluster_no_rep $tid/id_to_reset $tid/${tid}_final_set_cdhit_clusters.csv
	fi
	
	#########################################################################
	# Check if any new clusters are formed with the newly added sequences
	#########################################################################
	if [ "$clustold" == "$clustnew" ]
	then
		printf "\n\nNo new clusters are formed, ViCTree analysis for $tid is up-to-date\n\n" 
		rm $tid/${tid}_set_seeds_combined.fa $tid/${tid}_blastp.txt $tid/${tid}_checked* $tid/${tid}_set.fa $tid/${tid}_final_set
		
		####################################
		# Push the updated files to github	
		####################################
		git add $tid
		git commit -m "Pipeline updated for $tid"
		git push
		exit 1
	fi
	
else
	cd-hit -i $tid/${tid}_set_seeds_combined.fa -o $tid/${tid}_final_set -c $identity -t 1
	mv $tid/${tid}_final_set $tid/${tid}_final_set.fa
	grep "^>" $tid/${tid}_final_set.fa |sed 's/>//' > $tid/${tid}_cdhit_rep_accession
	###########################################
	# Convert cd-hit raw output to csv format
	###########################################
	clstr2txt.pl $tid/${tid}_final_set.clstr|tr "\t" ","|awk 'BEGIN{ FS = ","; OFS = "," }; {if($5==1){ $5=$1} print}' > $tid/${tid}_final_set_cdhit_clusters.csv
	awk -F"," '{if($5!=0) print $1","$2}' $tid/${tid}_final_set_cdhit_clusters.csv|tail -n +2 >$tid/${tid}_cluster_reps
	awk -F"," 'FNR==NR{a[$2]=$0;next}{if(b=a[$2]) {print $0","a[$2]}}' $tid/${tid}_cluster_reps $tid/${tid}_final_set_cdhit_clusters.csv |cut -f1,3,4,8 -d ","|sed -e '1iAccessionNumber,ClusterSize,Length,ClusterRepresentative\'> $tid/${tid}_clusters_info.csv
	
	####################################################
	# Reset the cd-hit cluster ID to userdefined list
	####################################################
	clustnew=`grep -c  "^>" $tid/${tid}_final_set.clstr`;
	if [ -f "$ulist" ];
	then
		echo "Precompiled list of accession is provided, now resetting the centroids \n"
		echo "Now resetting the centroids"
		grep -f "$ulist" $tid/${tid}_final_set_cdhit_clusters.csv|cut -f1-2 -d ","|sort -k2 -n -u -t',' > $tid/id_to_reset
		grep -f "$ulist" $tid/${tid}_final_set_cdhit_clusters.csv|cut -f1-2 -d ","| uniq|diff <(cut -f2 -d ",") <(seq 0 $clustnew)|grep ">"|cut -c 3- > $tid/cluster_no_rep
		grep -wf $tid/cluster_no_rep <(cut -f1-2,5 -d "," $tid/${tid}_final_set_cdhit_clusters.csv)|awk -F "," '{if($3!=0) print}' |cut -f1,2 -d"," > $tid/id_not_reset
		cat <(cut -f1 -d "," $tid/id_to_reset) <(cut -f1 -d "," $tid/id_not_reset) > $tid/${tid}_cdhit_rep_accession
		cat $tid/id_to_reset $tid/id_not_reset |sort -k2 -n -t ','> $tid/${tid}_cluster_reps
		awk -F"," 'FNR==NR{a[$2]=$0;next}{if(b=a[$2]) {print $0","a[$2]}}' $tid/${tid}_cluster_reps $tid/${tid}_final_set_cdhit_clusters.csv |cut -f1,3,4,8 -d ","|sed -e '1iAccessionNumber,ClusterSize,Length,ClusterRepresentative\'> $tid/${tid}_clusters_info.csv
		
		grep --no-group-separator -A1 -f $tid/${tid}_cdhit_rep_accession <(awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' $tid/${tid}_set_seeds_combined.fa)|awk '/^>/{f=!d[$1];d[$1]=1}f' > $tid/${tid}_final_set.fa
		temp=`awk 'BEGIN{RS=">"}{gsub("\n","\t",$0); print ">"$0}' $tid/${tid}_final_set.fa |cut -f1|sed 's/>//g'`
		for x in $(echo $temp)
		do
			if [[ "$x" == *"_"*  ]];
			then
				z=`elink -db protein -target nuccore -id "$x" -batch|esummary|xtract -element AssemblyAcc`;
				sed -i "s/$x/$x"__"$z/g" $tid/${tid}_final_set.fa
			else
				y=`elink -db protein -target nuccore -id "$x" -batch |efetch -format acc`
				sed -i "s/$x/$x"__"$y/g" $tid/${tid}_final_set.fa
			fi
		done
		rm $tid/id_not_reset $tid/cluster_no_rep $tid/id_to_reset $tid/${tid}_final_set_cdhit_clusters.csv
	fi
fi

####################################################################
# Collect the metadata from NCBI for the representative sequences 
####################################################################

bash CollectMetadata.sh $tid/${tid}_cdhit_rep_accession ${tid}/${tid}_label.csv $genus

echo "-----------------Running Step 7 of Pipeline --------------------";
printf "Running Multiple Sequence Alignments Using CLUSTALO \n"; 
clustalo -i $tid/${tid}_final_set.fa -o $tid/${tid}_final_set_clustalo_aln.fa --outfmt="fasta" --force --full --distmat-out=$tid/${tid}_clustalo_dist_mat

##############################################
# Format matrix file for visualisation
##############################################
sed -e '1d' $tid/${tid}_clustalo_dist_mat| tr -s " "| sed 's/ /,/g' > $tid/${tid}.csv
header=`cut -f1 -d ',' $tid/${tid}.csv| tr '\n' ','|sed 's/,$//g'`
sed -i "1ispecies,"$header"" $tid/${tid}.csv 
rm $tid/${tid}_set_seeds_combined.fa $tid/${tid}_blastp.txt $tid/${tid}_checked* $tid/${tid}_set.fa $tid/${tid}_cdhit_rep_accession ${tid}_final_set_cdhit_clusters.csv

echo "-----------------Running Step 8 of Pipeline --------------------";
printf "Running Phylogenetic Analysis using RAXML \n";
printf "RAxML model is set to $raxml \n\n";
cd $tid;
rm -f RAxML*
printf "raxmlHPC-PTHREADS -f a -m $raxml -p 12345 -x 12345 -# 100 -s ${tid}_final_set_clustalo_aln.fa -n $tid -T $proc \n";
raxmlHPC-PTHREADS -f a -m $raxml -p 12345 -x 12345 -# 100 -s ${tid}_final_set_clustalo_aln.fa -n $tid -T $proc

#####################
# Reroot the tree
#####################
raxmlHPC-PTHREADS -f I -t RAxML_bipartitionsBranchLabels.$tid -m PROTGAMMAJTT -n ${tid}_reroot	
mv RAxML_rootedTree.${tid}_reroot ${tid}.nhx
cd ..

cp ${tid}/${tid}.nhx phylotree/data/${name}.nhx
cp ${tid}/${tid}_label.csv phylotree/data/${name}_label.csv
cp ${tid}/${tid}.csv phylotree/data/${name}.csv

####################################
#Upload the data to git repository
####################################
git add $tid
git commit -m "Pipeline updated for $tid"
git push
cd phylotree
#git pull
git add data/${name}.nhx data/${name}.csv data/${name}_label.csv
git commit -m "Data files updated for $name"
git push

