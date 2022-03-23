set total_frame [molinfo 0 get frame]
set a [atomselect top "fragment 0"]
for {set i 0} {$i < $total_frame} {incr i} {
	animate goto $i
	for {set j 0} {$j < 5} {incr j} {
		set gc_${j} [measure rgyr $a]
	}
	puts "$gc_0 $gc_1 $gc_2 $gc_3 $gc_4"
}