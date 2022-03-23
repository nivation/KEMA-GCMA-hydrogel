set total_frame [molinfo top get frame]
set a [atomselect top "fragment 0"]
set gc {}
for {set i 0} {$i < $total_frame} {incr i} {
	animate goto $i
	lappend gc [measure rgyr $a]
}
puts $gc