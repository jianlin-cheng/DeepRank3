#!/bin/bash -e

echo " Start install python virtual environment (will take ~1 min)"

cd /home/jianliu/DeepRank3/DeepRank_db_tools//tools

mkdir -p ~/.keras

cp ~/.keras/keras.json ~/.keras/keras.json.$NOW.$RANDOM

cp /home/jianliu/DeepRank3//installation/DeepRank_configure_files/keras_DeepRank.json ~/.keras/keras.json

rm -rf python_virtualenv

virtualenv python_virtualenv

source /home/jianliu/DeepRank3/DeepRank_db_tools//tools/python_virtualenv/bin/activate

curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py

python get-pip.py

#pip install --upgrade pip

pip install --upgrade numpy==1.12.1

pip install --upgrade keras==1.2.2

pip install --upgrade theano==0.9.0

pip install --upgrade h5py

pip install --upgrade matplotlib

pip install --upgrade pandas

pip install --upgrade sklearn

pip install --upgrade plotly

pip install --upgrade np_utils

pip install --upgrade pillow

NOW=$(date +"%m-%d-%Y")

echo "installed" > /home/jianliu/DeepRank3/DeepRank_db_tools//tools/python_virtualenv/install.done

