import os 
from os import listdir
from os.path import isfile, join
import subprocess
import shutil

def setup():
    onlyfiles = [f for f in listdir("./") if not isfile(join('./', f))]
    print('\nCatch folders: ',onlyfiles)
    return onlyfiles

def getbondtype():
    with open('NPT_out_unwrap_polymatic.log','r') as f:
        for line in f.readlines():
            pass
        output = line.strip().split(' ')
    return int(output[0]),int(output[1]),int(output[2]),int(output[3]),int(output[4])

def add_crossterm(lj_pair,cmap_crossterm,cmap_crossterm_list):
    with open('NPT_out_unwrap_polymatic_crossterm.data','w') as h:
        with open('NPT_out_unwrap_polymatic.data','r') as f:
            for line in f.readlines():
                h.writelines(line)
                if 'improper types' in line:
                    h.writelines(cmap_crossterm)
                if '56 14.007' in line:
                    for i in range(len(lj_pair)):
                        if i == 0:
                            h.writelines('\n')
                            h.writelines(lj_pair[i])
                        elif i == len(lj_pair)-1:
                            pass
                        else:
                            h.writelines(lj_pair[i])
            for crossterm in cmap_crossterm_list:
                h.writelines(crossterm)


def unwrap():
    target = 'NPT_out.data'
    out = target.split('.')[0]+'_unwrap.data'
    switch = False
    cmap_crossterm = ''
    cmap_crossterm_list = []
    CMAP = False
    LJ_pair = []
    LJ = False
    with open(out,'w') as h:
        with open(target,'r') as f:
            for line in f.readlines():
                # Get pair coefficient 
                if 'Bond Coeffs' in line:
                    LJ = False
                if 'PairIJ Coeffs' in line:
                    LJ = True
                if LJ:
                    LJ_pair.append(line)
                    
                # Get cmap crossterm
                if 'crossterms' in line:
                    cmap_crossterm = line
                # Get CMAP
                if "CMAP" in line:
                    CMAP =True
                if CMAP:
                    cmap_crossterm_list.append(line)
                # Get x y z length
                if 'xlo' in line:
                    lx = float(line.split(' ')[1])-float(line.split(' ')[0])
                if 'ylo' in line:
                    ly = float(line.split(' ')[1])-float(line.split(' ')[0])
                if 'zlo' in line:
                    lz = float(line.split(' ')[1])-float(line.split(' ')[0])

                # Create unwrap coordinate
                if switch == True:
                    split_list = line.strip().split(' ')
                    if len(split_list) > 2:
                        x_unwrap = int(split_list[-3])*lx +float(split_list[-6])
                        y_unwrap = int(split_list[-2])*ly +float(split_list[-5])
                        z_unwrap = int(split_list[-1])*lz +float(split_list[-4])
                        unwrap_line = str(split_list[0])+' '+str(split_list[1])+' '+str(split_list[2])+' '+str(split_list[3])+' '+str(x_unwrap)+' '+str(y_unwrap)+' '+str(z_unwrap)+'\n'
                        h.writelines(unwrap_line)
                    else:
                        h.writelines(line)
                else:
                    h.writelines(line)
                if 'Atoms # full' in line:
                    switch = True
                if 'Velocities' in line:
                    switch = False
    return LJ_pair,cmap_crossterm,cmap_crossterm_list

def get_new_folder(file_list):
    new_num = -1
    for folder in file_list:
        num = int(folder.split('_')[0])
        if num > new_num:
            new_num = num
    new_folder_name = str(new_num)+"_poly"
    print("\nWorking_directory:",new_folder_name)
    return new_folder_name

#main
iteration = -1
onlyfiles = setup()
working_dir = get_new_folder(onlyfiles)
for folder in onlyfiles:
    num = int(folder.split('_')[0])
    if num > iteration:
        iteration = num
iteration += 1
new_name = str(iteration)+'_'+'poly'
print('\nCreating folder:',new_name)
os.mkdir(new_name)
os.chdir(working_dir)

lj_pair, cmap_crossterm,cmap_crossterm_list = unwrap()
ubuntu_cmd = 'perl ../0_poly_script/polym.pl -i ./NPT_out_unwrap.data -t ../0_poly_script/types.txt -s ../0_poly_script/polym.in -o ./NPT_out_unwrap_polymatic.data'
ode = subprocess.call(ubuntu_cmd.split(), stdout=open('NPT_out_unwrap_polymatic.log', 'w')) 
if ode == 0:
    print('\nPolymatic run successfully')
    add_crossterm(lj_pair,cmap_crossterm,cmap_crossterm_list)
    self_KEMA, KEMA_KEMA, self_GCMA, GCMA_GCMA, KEMA_GCMA = getbondtype()
    # print(self_KEMA,KEMA_KEMA,self_GCMA,GCMA_GCMA,KEMA_GCMA)
    total = self_KEMA+KEMA_KEMA+self_GCMA+GCMA_GCMA+KEMA_GCMA
    print("Formed",total,"bonds")
    os.chdir('../')
elif ode == 3:
    os.chdir('../')
    print('\nNo bonding found')
elif ode == 2:
    print('\nSomething wrong with polym.pl')
else:
    print('\nError')

src = 'in.md'
dst = os.path.join(new_name,src)
shutil.copyfile(src, dst)

dst_2 = os.path.join(new_name,'lmpsub.sh')
with open('lmpsub.sh','r') as f:
    with open(dst_2,'w') as h:
        for line in f.readlines():
            if '#PBS -N' in line:
                line = '#PBS -N '+str(iteration)+'_poly\n'
                h.writelines(line)
            else:
                h.writelines(line)


src = os.path.join(working_dir,'NPT_out_unwrap_polymatic_crossterm.data')
dst = os.path.join(new_name,'NPT_out_unwrap_polymatic_crossterm.data')
shutil.copyfile(src, dst)

print(new_name,'created sucessfully')