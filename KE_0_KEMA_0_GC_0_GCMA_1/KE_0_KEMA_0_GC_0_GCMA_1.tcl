package require psfgen                                   
package require solvate                                  
package require autoionize                               
resetpsf                                                 
topology top_all36m_prot.rtf                
mol new KE_0_KEMA_0_GC_0_GCMA_1/KE_0_KEMA_0_GC_0_GCMA_1.pdb
set all_atom [atomselect top "all"]                      
set chain_list [lsort -unique [$all_atom get fragment]]     
foreach chain_id $chain_list {                           
    puts $chain_id                                       
    set select_atoms [atomselect top "fragment ${chain_id}"]
    $select_atoms set segname $chain_id                  
    $select_atoms writepdb ${chain_id}.pdb               
    segment ${chain_id} {pdb ${chain_id}.pdb}            
    coordpdb ${chain_id}.pdb ${chain_id}                 
    guesscoord                                           
    regenerate angles dihedrals                          
    $select_atoms delete                                 
    file delete ${chain_id}.pdb                          
}                                                        
writepdb KE_0_KEMA_0_GC_0_GCMA_1/KE_0_KEMA_0_GC_0_GCMA_1_autopsf.pdb                                 
writepsf KE_0_KEMA_0_GC_0_GCMA_1/KE_0_KEMA_0_GC_0_GCMA_1_autopsf.psf                                 
resetpsf                                                 
solvate KE_0_KEMA_0_GC_0_GCMA_1/KE_0_KEMA_0_GC_0_GCMA_1_autopsf.psf KE_0_KEMA_0_GC_0_GCMA_1/KE_0_KEMA_0_GC_0_GCMA_1_autopsf.pdb -minmax {{38.386 33.627 -28.378} {68.689 55.266 129.793 }} -o KE_0_KEMA_0_GC_0_GCMA_1/KE_0_KEMA_0_GC_0_GCMA_1_autopsf_solvate
autoionize -psf KE_0_KEMA_0_GC_0_GCMA_1/KE_0_KEMA_0_GC_0_GCMA_1_autopsf_solvate.psf -pdb KE_0_KEMA_0_GC_0_GCMA_1/KE_0_KEMA_0_GC_0_GCMA_1_autopsf_solvate.pdb -o KE_0_KEMA_0_GC_0_GCMA_1/KE_0_KEMA_0_GC_0_GCMA_1_autopsf_solvate_ionzied -sc 0.15
exit                                                     
