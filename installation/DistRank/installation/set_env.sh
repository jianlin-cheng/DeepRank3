#!/bin/bash -e
# module load python/python-3.5.2
temp_dir=$(pwd)
gloable_name=`pwd | awk -F "/" '{print $NF}'`
gloable_dir=${temp_dir%%$gloable_name*}$gloable_name
env_dir=$gloable_dir/env/
echo install virtual environment to $env_dir
cd $env_dir
rm -rf distrank_virenv
pyvenv-3.6 distrank_virenv
source $env_dir/distrank_virenv/bin/activate
pip3 install --upgrade pip
pip3 install wheel
pip3 install numpy==1.15.2
pip3 install matplotlib
pip3 install scipy
pip3 install scikit-learn==0.20.3
pip3 install opencv-python==4.5.5.64
pip3 install --upgrade h5py

echo "installed" > $env_dir/env_vir.done
echo virtual environment installed succesful!
