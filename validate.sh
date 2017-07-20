#! /bin/bash

#Script to calculate number of false positive and false negatives
# This script uses a file with list of currently classified sequences and *_filtered files generated from shuffle.sh
# $1 -> txid40120_current_ns1_accession
# $2 -> OutputfileName
# $3 -> Number of Seeds
printf "NoSeeds\tRunNo\tLength\tCoverage\tSeqFound\tFalsePos\tFalseNeg\n" >$2

for file in `ls -tr *_combination`
do
        echo "Processing $file"
	RunNo=`echo "$file"|cut -f1 -d "_"`
	Length=`echo "$file"|cut -f4 -d "_"`
	Coverage=`echo "$file"|cut -f5 -d "_"`
        cut -f3 $file |cut -f1 -d "."|sort|uniq > ${file}_acc
        #number of sequences identified
        found=`grep -c -wf $1 ${file}_acc`
        #number of false positive
        fp=`grep -c -v -wf $1 ${file}_acc`
	#number false negative
        fn=`grep -c -v -wf ${file}_acc $1`

	printf "$3\t$RunNo\t$Length\t$Coverage\t$found\t$fp\t$fn\n" >>$2
	
done
