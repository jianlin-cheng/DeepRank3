#!/bin/bash -e

echo " Start compile freecontact (will take ~3 min)"

cd /home/jianliu/DeepRank3/DeepRank_db_tools//tools/EMBOSS-6.6.0

make clean

./configure --prefix=/home/jianliu/DeepRank3/DeepRank_db_tools//tools/EMBOSS-6.6.0

make

make install

echo "installed" > /home/jianliu/DeepRank3/DeepRank_db_tools//tools/EMBOSS-6.6.0/install.done

