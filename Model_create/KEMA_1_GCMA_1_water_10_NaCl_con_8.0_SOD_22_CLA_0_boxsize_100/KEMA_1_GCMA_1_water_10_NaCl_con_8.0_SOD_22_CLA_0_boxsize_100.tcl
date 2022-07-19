package require psfgen                                   
resetpsf                                                 
topology top_1_25.rtf                       
mol new ./KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100/KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100.pdb
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
writepdb KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100/KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100_autopsf.pdb                                 
writepsf KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100/KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100_autopsf.psf                                 
resetpsf                                                 
exit                                                     
