import os 
from os.path import isfile, join
import subprocess
import numpy as np
import time

def main():
    count           = 1
    iteration       = 0
    tolerance       = 3
    total_bond_num  = 0
    setup()
    while iteration < tolerance:
        print("\nCycle:",count,"-------------------------------------")
        count += 1
        form_num = poly()
        if form_num == 0:
            iteration += 1
            #print("\n No bond form, iteraction:",iteration)
        else:
            iteration = 0
            #print("\n Form",form_num,"bonds")
        total_bond_num += form_num
        md()
    return

def setup():
    # Find initial data
    j = 0
    for i in os.listdir('./'):
        if '1_poly' in i.split('.'):
            print('Find initial folder:   ',i)
            j+=1
        elif 'sh' in i.split('.'):
            print('Find bash file:        ',i)
            j+=1
        elif 'md' in i.split('.'):
            print('Find md script file:   ',i)
            j+=1
        elif 'auto_poly' in i.split('.'):
            print('Find polymatic python: ',i)
            j+=1
        elif '0_poly_script' in i.split('.'):
            if len(os.listdir(i)) == 4:
                print('Find polymatic folder: ',i)
                j+=1
    if j != 5:
        print('\nMissing some input file')
    else:
        print('\nFind all input file')
    
def md():
    get_current_working = gcw()
    os.chdir(get_current_working)
    cmd = 'qsub lmpsub.sh'
    ode = subprocess.call(cmd.split())
    print('start md')
    while not os.path.exists("NPT_out.data"):
        time.sleep(1)    
    if os.path.exists("NPT_out.data"):
        time.sleep(15)    
    os.chdir("../")
    print(os.getcwd())
    return

def poly():
    poly_bond           = 0
    get_current_working = gcw()
    cmd = 'python auto_poly.py'
    ode = subprocess.call(cmd.split())
    polymatic_log = os.path.join(get_current_working,'NPT_out_unwrap_polymatic.log')
    print('start polymatic')
    while not os.path.exists(polymatic_log):
        time.sleep(1)    
    if os.path.exists(polymatic_log):
        time.sleep(15)    
    with open(polymatic_log) as f:
        for line in f.readlines():
            pass
    for i in line.split():
        if i == 'No':
            break
        else:
            poly_bond += int(i)
    file_1 = os.path.join(get_current_working,'NPT_out_unwrap.data')
    file_2 = os.path.join(get_current_working,'NPT_out_unwrap_polymatic.data')
    file_3 = os.path.join(get_current_working,'NPT_out_unwrap_polymatic_crossterm.data')
    if isfile(file_1):
        os.remove(file_1)
    if isfile(file_2):
        os.remove(file_2)
    if isfile(file_3):
        os.remove(file_3)
    return poly_bond

def gcw():
    max_num = -1
    index   = 0
    onlyfolder = [f for f in os.listdir("./") if not isfile(join('./', f))]
    for i in range(len(onlyfolder)):
        if int(onlyfolder[i].split('_')[0]) > max_num :
            max_num  =  int(onlyfolder[i].split('_')[0])
            index = i
    return onlyfolder[index ]

if __name__ == '__main__':
    main()  