# KEMA-GCMA-hydrogel
  
This is a set of code that can:    
* Fast create methacrylated-keratin / methacrylated-glycol chitosan hydrogel model under desire concentration.  
* Output standard LAMMPS input code to perform stable equilibirum.   
* Polymerize methacrylate sidechain based on [Polymatic](https://nanohub.org/resources/17278).

## Quick start
Several softwares are available and should be installed and set as enviormental varibles:  
* [VMD](https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD)
* [LAMMPS](https://www.lammps.org/download.html)
* [Polymatic](https://nanohub.org/resources/17278)

## Environment
### [Model_Create](#Model_Create)  
* Python 3.9.12  
* Numpy 1.21.5  

### [Polymerization](#Polymerization) 
* perl v5.26.2
* Python 3.8.5
* Numpy 1.20.2  

## Introduction
[Demo video](https://www.youtube.com/watch?v=srP5eyy9h00&feature=youtu.be)  
  
__Procedue of this code__:  
![Alt text](https://github.com/nivation/KEMA-GCMA-hydrogel/blob/main/Procedue.PNG)



## Usage
### Model_Create 
```
python model.py [KEMA set num] [GCMA set num] [Num of water molecules] [Concentration of NaCl] [Initial box size] [Conjugate model] [Delete working files] > out.log  
```
  input variables:
```
KEMA set num          :no default  
GCMA set num          :no default  
Num of water molecules:negative integer for VMD auto solvate and ionized based on boxsize  
Concentration of NaCl :under unit g/L  
Initial box size      :no default(anstrom)  
Conjugate model       :model without methacrylated, no default，1 for conjugate, 0 for not  
Delete working files  :1 for delete and 0 for not, default 0  
```

  __Example__:  
```
python model.py 1 1 10 8 100 0 0
```
should look like this:  
```
model_create>python model.py 1 1 10 8 100 0 0
------------Skip Conjugate------------

-------------- Original --------------
> Num of KEMA/KE set   : 1  
> Num of Neutrlize SOD : 22  
> Num of GCMA/GC       : 1  
> Num of water         : 10  
> Add NaCl (g/L)       : 8.0  
> Pair of NaCl         : 0  
> Total SOD            : 22  
> Total CLA            : 0  
>   
> KE/KEMA Weight percentage of this system ((KEMA)/(KEMA+GCMA+water+salt)))      (g/g) is: 0.8630414792456265  
> GC/GCMA Weight percentage of this system ((GCMA)/(KEMA+GCMA+water+salt)))      (g/g) is: 0.12084388603036317  
> Polymer Weight percentage of this system ((KEMA+GCMA)/(KEMA+GCMA+water+salt))) (g/g) is: 0.9838853652759897  
>   
> Total atoms          : 5832  
>   
> PackMol Boxsize(Å)   : 100  
> Delete               : Keep all file and script  
>   
> Press Enter key if the Polymer weight percentage is correct, or please interrupt...  
```


### Polymerization  
```
python control.py
```
should look like this: 
```
/Polymerization$ python control.py
Find polymatic folder:  0_poly_script
Find initial folder:    1_poly
Find polymatic python:  auto_poly.py
Find md script file:    in.md
Find bash file:         lmpsub.sh

Find all input file

Cycle: 1 -------------------------------------

Catch folders:  ['0_poly_script', '1_poly']

Working_directory: 1_poly

Creating folder: 2_poly

Polymatic run successfully
Formed 62 bonds
2_poly created sucessfully
start polymatic

start md
```
 __Note:__  
 Example input data file can be downloaded from [here](https://drive.google.com/file/d/1yrjvKAFK79rm1dO4Moucz77TnQBrwsEV/view?usp=sharing) and put into ./Polymerization/1_poly
 
 This code is used for lab research. The input script for running LAMMPS may be differ.  
 Users should check the input script in control.py such as:  
 ```
 cmd = 'qsub lmpsub.sh'
 ```
 and change into lines like:  
  ```
 cmd = lmp_serial -in in.md'
 ```
 if needed
