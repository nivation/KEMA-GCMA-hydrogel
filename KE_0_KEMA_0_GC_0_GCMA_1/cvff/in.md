################################################
# Input file setup
################################################
units			real
boundary		p p p
atom_style		full
neigh_modify 	every 1 delay 0 check yes
variable		time_step 			 equal 1
variable		equilibrium_run_step equal 50000000 					# 10ns
variable		thermo_step 		 equal ${equilibrium_run_step}/100  # 100 frame

variable		filename string 20merGC_out_3.data

################################################
# Non bonded and bonded interactions setup
################################################
#pair_style 		lj/cut/coul/long 10
#kspace_style 	pppm 1.0e-4
pair_style 		lj/cut/coul/cut 10
bond_style 		harmonic
angle_style 	harmonic
dihedral_style 	harmonic
improper_style 	cvff

read_data		${filename}

################################################
# Minimization
################################################
min_style      	cg 
minimize       	0.0 1.0e-8 10000 100000
write_data		minimized.data

################################################
# NPT equilibrium
################################################
neigh_modify 	every 1 delay 10
velocity        all create 300 12345
fix				1 all npt temp 300 300 $(100.0*dt) iso 1 1 $(1000.0*dt)

################################################
# Dump setup
################################################
#丟進VMD用
dump            10 all dcd ${thermo_step} PHEMA100_pure_NPT.dcd #每0.1ns output
dump_modify     10 unwrap yes

thermo_style    custom step time temp pe ke etotal enthalpy press vol density epair evdwl ecoul elong etail emol ebond eangle edihed eimp

################################################
# Run
################################################
timestep        ${time_step}
thermo			${thermo_step}
run				${equilibrium_run_step}
write_data		${filename}_npt_300K.data
