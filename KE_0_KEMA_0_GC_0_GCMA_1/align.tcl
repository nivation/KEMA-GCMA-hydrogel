package require Orient                                         
namespace import Orient::orient                                
mol new KE_0_KEMA_0_GC_0_GCMA_1/KE_0_KEMA_0_GC_0_GCMA_1.pdb
set sel [atomselect top "all"]                                 
set fragment_num [llength [lsort -unique [$sel get fragment]]] 
puts $fragment_num                                             
if { $fragment_num == 1} {                                     
	set I [draw principalaxes $sel]                              
	set A [orient $sel [lindex $I 2] {0 0 1}]                    
	$sel move $A                                                 
	set I [draw principalaxes $sel]                              
	set A [orient $sel [lindex $I 1] {0 1 0}]                    
	$sel move $A                                                 
	set I [draw principalaxes $sel]                              
	set A [orient $sel [lindex $I 1] {1 0 0}]                    
	$sel move $A                                                 
	set test [measure minmax $sel]                               
	$sel writepdb KE_0_KEMA_0_GC_0_GCMA_1/KE_0_KEMA_0_GC_0_GCMA_1.pdb                   
}                                                              
exit                                                           
