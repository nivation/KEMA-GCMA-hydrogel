mol load psf KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100/KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100_autopsf_solvate.psf pdb KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100/KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100_autopsf_solvate.pdb
set a [atomselect top " fragment 0 to 8 or fragment 32147 21373 48544 22888 52984 4888 21090 21593 48734 51078 18584 50116 29270 7649 11726 27124 8395 24559 39366 5845 40736 11000 3481 25541 3473 43768 48267 1689 3640 42812 20666 44465 "]
$a writepdb KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100/KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100_autopsf_solvate_delete.pdb
$a writepsf KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100/KEMA_1_GCMA_1_water_10_NaCl_con_8.0_SOD_22_CLA_0_boxsize_100_autopsf_solvate_delete.psf
exit                                                     
