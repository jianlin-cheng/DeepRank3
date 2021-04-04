#!/bin/bash -e

echo " Start compile R-3.2.0 (will take ~3 min)"

cd /home/jianliu/DeepRank3/DeepRank_db_tools//tools/R-3.2.0

make clean

./configure --prefix=/home/jianliu/DeepRank3/DeepRank_db_tools//tools/R-3.2.0  --with-readline=no --with-x=no

make

make install

echo "installed" > /home/jianliu/DeepRank3/DeepRank_db_tools//tools/R-3.2.0/install.done

