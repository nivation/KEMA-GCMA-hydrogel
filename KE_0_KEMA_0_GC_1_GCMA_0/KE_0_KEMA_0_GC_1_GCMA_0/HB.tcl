set a [atomselect top "fragment 0"]
set water [atomselect top "name OT HT "]
# intra 
hbonds -sel1 $a -writefile yes -outfile intra.data -frames 50:100 -dist 3.5 -ang 30 -plot no -polar yes
# inter
# water
hbonds -sel1 $a -sel2 $water -writefile yes -outfile water.data -frames 50:100 -dist 3.5 -ang 30 -plot no -polar yes

$a delete
$water delete