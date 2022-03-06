
import argparse
import os, subprocess, shutil
import time

parser = argparse.ArgumentParser()
parser.add_argument("KE"  ,   type=int,help="KE   set number")
parser.add_argument("KEMA",   type=int,help="KEMA set number")
parser.add_argument("GC",     type=int,help="GC   set number")
parser.add_argument("GCMA",   type=int,help="GCMA set number")
parser.add_argument("Boxsize",type=int,help="initial box size")
parser.add_argument("Delete", type=int,help="Delete working files or not (1 delete, 0 keep)", default = 0)
args = parser.parse_args()


def main(KE,KEMA,GC,GCMA,boxsize,delete):
    name = 'KE_'+str(KE)+'_KEMA_'+str(KEMA)+'_GC_'+str(GC)+'_GCMA_'+str(GCMA)
    print('Num of KE   set:',KE)
    print('Num of KEMA set:',KEMA)
    print('Num of GC      :',GC)
    print('Num of GCMA    :',GCMA)
    print('Boxsize(Å)     :',boxsize)
    if delete == 1:
        print("Delete         : Delete working file and script")
    elif delete == 0:
        print("Delete         : Keep all file and script")
    else:
        delete = 0
        print("Delete         : Keep all file and script")
        
    if KE!=0 and KEMA!=0:
        print('Error: Do not support KE and KEMA in same system')
        exit()
    if not os.path.exists(name):
        os.mkdir(name)
    packmol(KE,KEMA,GC,GCMA,boxsize,name,delete)
    autopsf(KE,KEMA,GC,GCMA,boxsize,name,delete)
    charmm2lmp(KE,KEMA,GC,GCMA,boxsize,name,delete)
    createTWCC(KE,KEMA,GC,GCMA,name)

def createTWCC(KE,KEMA,GC,GCMA,name):
    twcc_dir = name + '/' +name
    if not os.path.exists(twcc_dir):
        os.mkdir(twcc_dir)
    in_file = twcc_dir + '/300K_equilibrium.in'
    in2_file = twcc_dir + '/300K_production.in'
    sh_file = twcc_dir + '/lmpsub_eq.sh'
    sh2_file = twcc_dir + '/lmpsub_pro.sh'
    charmm2lmp_in = name+'/'+name+'_autopsf_solvate_ionzied.in'
    pair_coeff = ""
    shake = ""
    with open(charmm2lmp_in,'r') as f:
        for line in f.readlines():
            if 'pair_coeff' in line:
                pair_coeff = line
            elif 'all shake' in line:
                shake = line

    with open(in_file,'w') as f :
        f.writelines("# Variable                                                                                                                              \n")
        f.writelines("variable		npt_step	equal	50000000           # 50 ns                                                                            \n")
        f.writelines("variable		npt_thermo	equal	${npt_step}/100    # output 100 frame                                                                 \n")
        f.writelines("units           real                                                                                                                    \n")
        f.writelines("variable        filename    string  "+name+"_autopsf_solvate_ionzied.data\n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("# Potential define                                                                                                                      \n")
        f.writelines("atom_style      full                                                                                                                    \n")
        f.writelines("bond_style      harmonic                                                                                                                \n")
        f.writelines("angle_style     charmm                                                                                                                  \n")
        f.writelines("dihedral_style  charmmfsw                                                                                                               \n")
        f.writelines("improper_style  harmonic                                                                                                                \n")
        f.writelines("pair_style      lj/charmmfsw/coul/charmmfsh 10 12                                                                                     \n")
        f.writelines("# pair_style      lj/charmmfsw/coul/long 10 12                                                                                            \n")
        f.writelines("# kspace_style    pppm 1e-6                                                                                                               \n")
        f.writelines("pair_modify     mix arithmetic                                                                                                          \n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("# Modify following line to point to the desired CMAP file                                                                               \n")
        f.writelines("fix             cmap all cmap charmm36.cmap                                                                          \n")
        f.writelines("fix_modify      cmap energy yes                                                                                                         \n")
        f.writelines("read_data       ${filename} fix cmap crossterm CMAP                                                                                        \n")
        f.writelines(pair_coeff)
        f.writelines("\nspecial_bonds   charmm                                                                                                                  \n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("# Minimized                                                                                                                             \n")
        f.writelines("neigh_modify    every 1 delay 0 check yes                                                                                               \n")
        f.writelines("min_style       cg                                                                                                                      \n")
        f.writelines("minimize        0.0 1.0e-9 100000 1000000                                                                                                  \n")
        f.writelines("write_data      minimized.data pair ij                                                                                                  \n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("# Setup                                                                                                                                 \n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("neigh_modify    delay 5 every 1                                                                                                         \n")
        f.writelines("restart 		${npt_thermo} ./restart/300K_equilibrium.restart                                                                                       \n")
        f.writelines("dump            1 all dcd ${npt_thermo} 300K_equilibrium.dcd                                                                                         \n")
        f.writelines("dump_modify     1 unwrap yes                                                                                                            \n")
        f.writelines("thermo          ${npt_thermo}                                                                                                           \n")
        f.writelines("thermo_style    custom step time xlo xhi ylo yhi zlo zhi etotal pe ke ebond temp press eangle edihed eimp evdwl ecoul elong vol density \n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("# NPT 300K                                                                                                                              \n")
        f.writelines("reset_timestep  0                                                                                                                       \n")
        f.writelines(shake)
        f.writelines("fix 			1 all npt temp 300.0 300.0 100.0 iso 1 1 1000.0                                                                           \n")
        f.writelines("\ntimestep        1                                                                                                                     \n")
        f.writelines("run             ${npt_step}                                                                                                             \n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("write_data      300K_equilibrium.data pair ij                                                                                                    \n")

    with open(in2_file,'w') as f :
        f.writelines("# Variable                                                                                                                              \n")
        f.writelines("variable		npt_step	equal	10000000           # 10 ns                                                                            \n")
        f.writelines("variable		npt_thermo	equal	${npt_step}/100    # output 100 frame                                                                 \n")
        f.writelines("units           real                                                                                                                    \n")
        f.writelines("variable        filename    string  300K_equilibrium.data\n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("# Potential define                                                                                                                      \n")
        f.writelines("atom_style      full                                                                                                                    \n")
        f.writelines("bond_style      harmonic                                                                                                                \n")
        f.writelines("angle_style     charmm                                                                                                                  \n")
        f.writelines("dihedral_style  charmmfsw                                                                                                               \n")
        f.writelines("improper_style  harmonic                                                                                                                \n")
        f.writelines("#pair_style      lj/charmmfsw/coul/charmmfsh 10 12                                                                                     \n")
        f.writelines("pair_style      lj/charmmfsw/coul/long 10 12                                                                                            \n")
        f.writelines("kspace_style    pppm 1e-6                                                                                                               \n")
        f.writelines("pair_modify     mix arithmetic                                                                                                          \n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("# Modify following line to point to the desired CMAP file                                                                               \n")
        f.writelines("fix             cmap all cmap charmm36.cmap                                                                          \n")
        f.writelines("fix_modify      cmap energy yes                                                                                                         \n")
        f.writelines("read_data       ${filename} fix cmap crossterm CMAP                                                                                        \n")
        f.writelines(pair_coeff)
        f.writelines("\nspecial_bonds   charmm                                                                                                                  \n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("# Minimized                                                                                                                             \n")
        f.writelines("#neigh_modify    every 1 delay 0 check yes                                                                                               \n")
        f.writelines("#min_style       cg                                                                                                                      \n")
        f.writelines("#minimize        0.0 1.0e-9 100000 1000000                                                                                                  \n")
        f.writelines("#write_data      minimized.data pair ij                                                                                                  \n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("# Setup                                                                                                                                 \n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("neigh_modify    delay 5 every 1                                                                                                         \n")
        f.writelines("restart 		${npt_thermo} ./restart/300K_production.restart                                                                                       \n")
        f.writelines("dump            1 all dcd ${npt_thermo} 300K_production.dcd                                                                                         \n")
        f.writelines("dump_modify     1 unwrap yes                                                                                                            \n")
        f.writelines("thermo          ${npt_thermo}                                                                                                           \n")
        f.writelines("thermo_style    custom step time xlo xhi ylo yhi zlo zhi etotal pe ke ebond temp press eangle edihed eimp evdwl ecoul elong vol density \n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("# NPT 300K                                                                                                                              \n")
        f.writelines("fix 			1 all npt temp 300.0 300.0 100.0 iso 1 1 1000.0                                                                           \n")
        f.writelines("\ntimestep        1                                                                                                                     \n")
        f.writelines("run             ${npt_step}                                                                                                             \n")
        f.writelines("                                                                                                                                        \n")
        f.writelines("write_data      300K_production.data pair ij                                                                                                    \n")

    with open(sh_file,'w',encoding="utf-8") as f:
        f.writelines("#!/bin/bash\n")             
        f.writelines("#PBS -l select=4:ncpus=40:mpiprocs=40:ompthreads=1\n")
        out = "#PBS -N "+str(KE)+str(KEMA)+str(GC)+str(GCMA)+"_eq \n"
        f.writelines(out)
        f.writelines("#PBS -q ct160\n")
        f.writelines("#PBS -P MST110475\n")
        f.writelines("#PBS -j oe\n")
        f.writelines("\n")
        f.writelines("cd $PBS_O_WORKDIR\n")
        f.writelines("\n")
        f.writelines("module purge\n")
        f.writelines("module load intel/2018_u1\n")
        f.writelines("module load cuda/8.0.61\n")
        f.writelines("OMP_NUM_THREADS=1\n")
        f.writelines("\n")
        f.writelines('echo "Your LAMMPS job starts at `date`"\n')
        f.writelines("\n")
        f.writelines('echo "Start time:" `date` 2>&1 > time.log\n')
        f.writelines("t1=`date +%s`\n")
        f.writelines("\n")
        f.writelines("mkdir restart\n")
        f.writelines("mpiexec.hydra -PSM2 /pkg/CMS/LAMMPS/lammps-16Mar18/bin/lmp_run_cpu -in ./300K_equilibrium.in > eq.log\n")
        f.writelines("\n")
        f.writelines("t2=`date +%s`\n")
        f.writelines('echo "Finish time:" `date` 2>&1 >> time.log\n')
        f.writelines('echo "Total runtime:" $[$t2-$t1] "seconds" 2>&1 >> time.log\n')
        f.writelines("\n")
        f.writelines("qstat -x -f ${PBS_JOBID} 2>&1 > job.log\n")
        f.writelines("\n")
        f.writelines('echo "Your LAMMPS job completed at  `date` "\n')

    with open(sh2_file,'w',encoding="utf-8") as f:
        f.writelines("#!/bin/bash\n")             
        f.writelines("#PBS -l select=4:ncpus=40:mpiprocs=40:ompthreads=1\n")
        out = "#PBS -N "+str(KE)+str(KEMA)+str(GC)+str(GCMA)+"_pro \n"
        f.writelines(out)
        f.writelines("#PBS -q ct160\n")
        f.writelines("#PBS -P MST110475\n")
        f.writelines("#PBS -j oe\n")
        f.writelines("\n")
        f.writelines("cd $PBS_O_WORKDIR\n")
        f.writelines("\n")
        f.writelines("module purge\n")
        f.writelines("module load intel/2018_u1\n")
        f.writelines("module load cuda/8.0.61\n")
        f.writelines("OMP_NUM_THREADS=1\n")
        f.writelines("\n")
        f.writelines('echo "Your LAMMPS job starts at `date`"\n')
        f.writelines("\n")
        f.writelines('echo "Start time:" `date` 2>&1 > time.log\n')
        f.writelines("t1=`date +%s`\n")
        f.writelines("\n")
        f.writelines("mkdir restart\n")
        f.writelines("mpiexec.hydra -PSM2 /pkg/CMS/LAMMPS/lammps-16Mar18/bin/lmp_run_cpu -in ./300K_production.in > pro.log\n")
        f.writelines("\n")
        f.writelines("t2=`date +%s`\n")
        f.writelines('echo "Finish time:" `date` 2>&1 >> time.log\n')
        f.writelines('echo "Total runtime:" $[$t2-$t1] "seconds" 2>&1 >> time.log\n')
        f.writelines("\n")
        f.writelines("qstat -x -f ${PBS_JOBID} 2>&1 > job.log\n")
        f.writelines("\n")
        f.writelines('echo "Your LAMMPS job completed at  `date` "\n')
        
    src = name+"/"+name+"_autopsf_solvate_ionzied.data"
    dst = name+"/"+name+"/"+name+"_autopsf_solvate_ionzied.data"
    shutil.move(src,dst)

    src = "charmm36.cmap"
    dst = name+"/"+name+"/"+"charmm36.cmap"
    shutil.copy(src,dst)
    
    return

def packmol(KE,KEMA,GC,GCMA,boxsize,name,delete):
    packmol_inp = './'+name+'/'+name+'.inp'
    goal = name+'.pdb'
    with open(packmol_inp,'w') as f:
        f.writelines('\ntolerance 2.0\n')
        f.writelines('\nfiletype pdb\n')
        out = '\noutput ./'+name+'/'+name+'.pdb\n'
        f.writelines(out)
        out = '\nadd_box_sides 2.0\n\n'
        f.writelines(out)
        if KE!= 0:
            f.writelines('structure ./input_pdb/98_132_1A.pdb    \n')
            f.writelines('  number '+str(KE)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/144_177_1B_1.pdb \n')
            f.writelines('  number '+str(KE)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/178_210_1B_2.pdb \n')
            f.writelines('  number '+str(KE)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/211_244_1B_3.pdb \n')
            f.writelines('  number '+str(KE)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/261_279_2A.pdb   \n')
            f.writelines('  number '+str(KE)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/288_327_2B_1.pdb \n')
            f.writelines('  number '+str(KE)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/328_369_2B_2.pdb \n')
            f.writelines('  number '+str(KE)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/370_408_2B_3.pdb \n')
            f.writelines('  number '+str(KE)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')    
        if KEMA!= 0:
            f.writelines('structure ./input_pdb/98_132_1A.pdb    \n')
            f.writelines('  number '+str(KEMA)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/144_177_1B_1.pdb \n')
            f.writelines('  number '+str(KEMA)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/178_210_1B_2.pdb \n')
            f.writelines('  number '+str(KEMA)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/211_244_1B_3.pdb \n')
            f.writelines('  number '+str(KEMA)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/261_279_2A.pdb   \n')
            f.writelines('  number '+str(KEMA)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/288_327_2B_1.pdb \n')
            f.writelines('  number '+str(KEMA)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/328_369_2B_2.pdb \n')
            f.writelines('  number '+str(KEMA)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')
            f.writelines('									     \n')
            f.writelines('structure ./input_pdb/370_408_2B_3.pdb \n')
            f.writelines('  number '+str(KEMA)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')   
        if GC != 0:
            f.writelines('structure ./input_pdb/20mer_GC.pdb \n')
            f.writelines('  number '+str(GC)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')   
        if GCMA != 0:
            f.writelines('structure ./input_pdb/20mer_7GCMA_3GC.pdb \n')
            f.writelines('  number '+str(GCMA)                   +'\n')
            f.writelines('  inside box 0. 0. 0. '+str(boxsize)+'. '+str(boxsize)+'. '+str(boxsize) +'.\n')
            f.writelines('end structure                          \n')   
    cmd = 'packmol < '+ packmol_inp +' > ./'+name+'/log.packmol'
    os.system(cmd)
    if delete == 1:
        os.remove(packmol_inp)
    return

def autopsf(KE,KEMA,GC,GCMA,boxsize,name,delete):
    pdb             = name+'/'+name+'.pdb'
    out_pdb         = name+'/'+name +'_autopsf.pdb'
    out_psf         = name+'/'+name +'_autopsf.psf'

    out_solvate     = name+'/'+name +'_autopsf_solvate'
    out_solvate_pdb = name+'/'+name +'_autopsf_solvate.pdb'
    out_solvate_psf = name+'/'+name +'_autopsf_solvate.psf'

    out_ion         = name+'/'+name +'_autopsf_solvate_ionzied'
    out_ion_pdb     = name+'/'+name +'_autopsf_solvate_ionzied.pdb'
    out_ion_psf     = name+'/'+name +'_autopsf_solvate_ionzied.pdb'

    out_tcl         = name+'/'+name+'.tcl'
    align_tcl       = name+'/'+'align.tcl'

    GC_total = GC+GCMA
    set_total = KE+KEMA+GC+GCMA

    if GC_total == 1 and set_total == 1:
        with open(align_tcl,'w') as f:
            f.writelines("package require Orient                                         \n")
            f.writelines("namespace import Orient::orient                                \n")
            f.writelines('mol new '+          pdb           +'\n')  
            f.writelines('set sel [atomselect top "all"]                                 \n')
            f.writelines("set fragment_num [llength [lsort -unique [$sel get fragment]]] \n")
            f.writelines("puts $fragment_num                                             \n")
            f.writelines("if { $fragment_num == 1} {                                     \n")
            f.writelines("	set I [draw principalaxes $sel]                              \n")
            f.writelines("	set A [orient $sel [lindex $I 2] {0 0 1}]                    \n")
            f.writelines("	$sel move $A                                                 \n")
            f.writelines("	set I [draw principalaxes $sel]                              \n")
            f.writelines("	set A [orient $sel [lindex $I 1] {0 1 0}]                    \n")
            f.writelines("	$sel move $A                                                 \n")
            f.writelines("	set I [draw principalaxes $sel]                              \n")
            f.writelines("	set A [orient $sel [lindex $I 1] {1 0 0}]                    \n")
            f.writelines("	$sel move $A                                                 \n")
            f.writelines("	set test [measure minmax $sel]                               \n")
            f.writelines("	$sel writepdb "+ pdb + "                   \n")
            f.writelines("}                                                              \n")
            f.writelines("exit                                                           \n")
        cmd = 'vmd -dispdev text -e '+align_tcl
        log = './'+name+'/log.align'
        ode = subprocess.call(cmd.split(), stdout=open(log, 'w'))   

    xmin,xmax,ymin,ymax,zmin,zmax = find_min_max(pdb,10)

    with open(out_tcl,'w') as f:
        f.writelines('package require psfgen                                   \n')
        f.writelines('package require solvate                                  \n')
        f.writelines('package require autoionize                               \n')
        f.writelines('resetpsf                                                 \n')
        if KEMA != 0:
            f.writelines('topology top_1_25.rtf                       \n')
        else:
            f.writelines('topology top_all36m_prot.rtf                \n')
        f.writelines('mol new '+          pdb           +'\n')
        f.writelines('set all_atom [atomselect top "all"]                      \n')
        f.writelines('set chain_list [lsort -unique [$all_atom get fragment]]     \n')
        f.writelines('foreach chain_id $chain_list {                           \n')
        f.writelines('    puts $chain_id                                       \n')
        f.writelines('    set select_atoms [atomselect top "fragment ${chain_id}"]\n')
        f.writelines('    $select_atoms set segname $chain_id                  \n')
        f.writelines('    $select_atoms writepdb ${chain_id}.pdb               \n')
        f.writelines('    segment ${chain_id} {pdb ${chain_id}.pdb}            \n')
        f.writelines('    coordpdb ${chain_id}.pdb ${chain_id}                 \n')
        f.writelines('    guesscoord                                           \n')
        f.writelines('    regenerate angles dihedrals                          \n')
        f.writelines('    $select_atoms delete                                 \n')
        f.writelines('    file delete ${chain_id}.pdb                          \n')
        f.writelines('}                                                        \n')
        f.writelines('writepdb '+out_pdb +   '                                 \n')
        f.writelines('writepsf '+out_psf +   '                                 \n')
        f.writelines('resetpsf                                                 \n')

        out = "solvate " + out_psf +" "+ out_pdb+" -minmax {{"+str(xmin)+' '+str(ymin)+' '+str(zmin)+"} {"+str(xmax)+' '+str(ymax)+' '+str(zmax)+' }} -o '+out_solvate+'\n'
        f.writelines(out)
        out = "autoionize -psf " + out_solvate_psf +" -pdb "+ out_solvate_pdb+' -o '+out_ion+' -sc 0.15\n'
        f.writelines(out)
        f.writelines('exit                                                     \n')
    cmd = 'vmd -dispdev text -e '+out_tcl
    log = './'+name+'/log.vmd'
    ode = subprocess.call(cmd.split(), stdout=open(log, 'w'))
    if delete == 1:
        os.remove(pdb)
        os.remove(out_psf)
        os.remove(out_pdb)
        os.remove(out_solvate_pdb)
        os.remove(out_solvate_psf)
        os.remove(out_tcl)
        solvate_log = './'+name+'/'+name+'_autopsf_solvate.log'
        dst = './'+name+'/log.solvate'
        shutil.move(solvate_log,dst)
    return

def charmm2lmp(KE,KEMA,GC,GCMA,boxsize,name,delete):
    filename          = './'+name+'/'+name+'_autopsf_solvate_ionzied'
    filename_pdb      = './'+name+'/'+name+'_autopsf_solvate_ionzied.pdb'
    filename_psf      = './'+name+'/'+name+'_autopsf_solvate_ionzied.psf'
    filename_pdb_temp = './'+name+'/'+name+'_autopsf_solvate_ionzied_temp.pdb'
    last = ''
    with open(filename_pdb,'r') as f:
        with open(filename_pdb_temp,'w') as h:
            for line in f.readlines():
                if 'END' in line:
                    h.writelines('TER\n')
                h.writelines(line)
    os.remove(filename_pdb)
    shutil.move(filename_pdb_temp,filename_pdb)
    if KE != 0:
        cmd = 'wsl perl charmm2lammps.pl all36m_prot '+filename+' -cmap charmm36'
    else:
        cmd = 'wsl perl charmm2lammps.pl 1_25 '+filename+' -cmap charmm36'
    log = './'+name+'/'+'log.charmm2lammps'
    ode = subprocess.call(cmd.split(), stdout=open(log, 'w'))

    if delete == 1:
        os.remove(filename_pdb)
        os.remove(filename_psf)
    return

def find_min_max(pdb_file,extra_range = 10):
    with open(pdb_file,'r') as f:
        xmin = 1000000
        xmax = -1000000
        ymin = 1000000
        ymax = -1000000
        zmin = 1000000
        zmax = -1000000
        for line in f.readlines():
            if 'ATOM' in line:
                line_split = line.split()[6:9]
                for i in range(len(line_split)):
                    line_split[i] = float(line_split[i])
                if line_split[0] < xmin:
                    xmin = line_split[0]
                if line_split[0] > xmax:
                    xmax = line_split[0]
                if line_split[1] < ymin:
                    ymin = line_split[1]
                if line_split[1] > ymax:
                    ymax = line_split[1]
                if line_split[2] < zmin:
                    zmin = line_split[2]
                if line_split[2] > zmax:
                    zmax = line_split[2]
    #print(xmin,xmax,ymin,ymax,zmin,zmax)
    xmin -= extra_range
    xmax += extra_range
    ymin -= extra_range
    ymax += extra_range
    zmin -= extra_range
    zmax += extra_range
    return xmin,xmax,ymin,ymax,zmin,zmax

if __name__ == '__main__':
    main(args.KE,args.KEMA,args.GC,args.GCMA,args.Boxsize,args.Delete)  