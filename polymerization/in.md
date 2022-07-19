# Created by charmm2lammps v1.9.2 on Mon Jan 31 15:22:27 CST 2022
# Command: charmm2lammps.pl -cmap=36 1_25 ionized

# Variable
variable		npt_step	equal	300000             # 1ns # about 4hr
variable		npt_thermo	equal	${npt_step}/100    # output 100 frame

units           real
neigh_modify    delay 2 every 1

# Potential define
atom_style      full
bond_style      harmonic
angle_style     charmm
dihedral_style  charmmfsw
improper_style  harmonic
#pair_style      lj/charmmfsw/coul/charmmfsh 10 12
pair_style      lj/charmmfsw/coul/long 10 12
kspace_style    pppm 1e-6
pair_modify     mix arithmetic

# Modify following line to point to the desired CMAP file
fix             cmap all cmap ../../0_minimized_npt/charmm36.cmap
fix_modify      cmap energy yes
read_data       NPT_out_unwrap_polymatic_crossterm.data fix cmap crossterm CMAP
pair_coeff      49 52 0.154919 3.24019863787641 0.154919 3.24019863787641
special_bonds   charmm

# Minimized
min_style       cg
#minimize        0.0 1.0e-8 10000 20000
#write_data      minimized.data pair ij

# NPT
timestep        0.5
fix 			1 all npt temp 300.0 300.0 100.0 iso 0.0 0.0 1000.0
velocity        all create 300.0 12345678 dist uniform
dump            1 all dcd ${npt_thermo} npt.dcd
dump_modify		1 unwrap yes
thermo          ${npt_thermo}
restart			${npt_thermo} ./restart/poly.restart
thermo_style    custom step time xlo xhi ylo yhi zlo zhi etotal pe ke temp press ebond eangle edihed eimp evdwl ecoul elong vol density
run             ${npt_step}
write_data      NPT_out.data pair ij
