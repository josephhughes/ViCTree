#!/bin/bash

mkdir $2
taxid="txid40120"
outfile=`echo $3`
touch $2/$outfile
printf "RunNo\tNoOfSeeds\tMinLen\tMinCov\n" > $2/$outfile
esearch -db protein -query "txid40120[Organism]" |efetch -format fasta > ${taxid}.fa
mv ${taxid}.fa $2/${taxid}.fa
awk 'BEGIN {RS = ">" ; FS = "\n" ; ORS = ""} $2 {print ">"$0}' $2/${taxid}.fa > $2/${taxid}_checked.fa
makeblastdb -in $2/${taxid}_checked.fa -dbtype 'prot'
for i in `seq 1 100`;
do

  cat $1|awk '/^>/ { if(i>0) printf("\n"); i++; printf("%s\t",$0); next;} {printf("%s",$0);} END { printf("\n");}' |shuf |head -n $2 |awk '{printf("%s\n%s\n",$1,$2)}' > $2/${i}.fa
  echo $i;
  makeblastdb -in $2/${i}.fa -dbtype 'prot'
  blastp -query $2/${i}.fa -db $2/${i}.fa -outfmt '6 qseqid qlen sseqid stitle sacc evalue length qcovs' -out $2/${i}_blastp_output -num_threads 12
  minlen=`cat $2/${i}_blastp_output|sort -k7 -n|head -1|cut -f7`;
  mincov=`cat $2/${i}_blastp_output|sort -k8 -n|head -1|cut -f8`;
  echo "Minimum length is $minlen"
  echo "Minimum coverage is $mincov"
  printf $i"\t"$2"\t"$minlen"\t"$mincov"\n" >>$2/$outfile
  blastp -query $2/${i}.fa -db $2/${taxid}_checked.fa -outfmt '6 qseqid qlen sseqid stitle sacc evalue length qcovs' -out $2/${i}_${taxid}_blastout -num_threads 12
  awk -F"\t" '{if($7>='$minlen' && $8>='$mincov') print}' $2/${i}_${taxid}_blastout  > $2/${i}_filtered
done;
