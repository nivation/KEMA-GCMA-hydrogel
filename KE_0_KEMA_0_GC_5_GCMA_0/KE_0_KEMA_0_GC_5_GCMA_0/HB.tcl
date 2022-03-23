
set water [atomselect top "name OT HT "]
# intra 
for {set i 0} {$i <5} {incr i} {
	set a [atomselect top "fragment 0"]
	hbonds -sel1 $a -writefile yes -outfile intra.data -frames 50:100 -dist 3.5 -ang 30 -plot no -polar yes
	$a delete
}

# inter
# water
hbonds -sel1 $a -sel2 $water -writefile yes -outfile water.data -frames 50:100 -dist 3.5 -ang 30 -plot no -polar yes

$water delete