#!/bin/bash -e

echo " Start install python virtual environment for keras2 (will take ~1 min)"

cd /home/jianliu/DeepRank3/DeepRank_db_tools//tools

rm -rf python_virtualenv_keras2

virtualenv python_virtualenv_keras2

source /home/jianliu/DeepRank3/DeepRank_db_tools//tools/python_virtualenv_keras2/bin/activate

pip install --upgrade pip

pip install --upgrade numpy

pip install --upgrade keras

pip install --upgrade Theano

pip install --upgrade h5py

echo "installed" > /home/jianliu/DeepRank3/DeepRank_db_tools//tools/python_virtualenv_keras2/install.done

