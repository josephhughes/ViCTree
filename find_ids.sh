exec < $1
while read id
do
	 awk -v OFS="\t" 'BEGIN{id=ARGV[1]; delete ARGV[1];}{for (i=2;i<=NF;i++) if($i==id) print $i,$0}' $id $2
done
