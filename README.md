# DeepRank3
The deep learning method for ranking protein structural models


**(1) Download DeepRank3 package (short path is recommended)**

```
git clone https://github.com/jianlin-cheng/DeepRank3.git

(If fail, try username) git clone https://huge200890@github.com/jianlin-cheng/DeepRank3.git

cd DeepRank3
```

**(2) Activate your python2.7 environment, setup the tools and download the database (required)**

```
a. edit setup_database.pl
    (i) Manually create folder for database (i.e., /data/commons/DeepRank_db_tools/)
    (ii) Set the path of variable '$DeepRank_db_tools_dir' for multicom databases and tools (i.e., /data/commons/DeepRank_db_tools/).

b. perl setup_database.pl
```

Please refer to 'cite_methods_for_publication.txt' to cite the methods that you use in DeepRank3 system for publication. The tools can be also downloaded from their official websites.


**(3) Configure DeepRank3 system (required)**

```
a. edit configure.pl

b. set the path of variable '$DeepRank_db_tools_dir' for multicom databases and tools (i.e., /data/commons/DeepRank_db_tools/).

c. save configure.pl

perl configure.pl
```

**(4) Check whether your python environment is installed successfully (required)**

```
source DeepRank_db_tools/tools/python_virtualenv/bin/activate
```

**(4a) If not, use following command to manually install**
```
sh installation/DeepRank_manually_install_files/P4_python_virtual.sh
```

**(5) Set theano as backend for keras (required)**

Change the contents in '~/.keras/keras.json'.
```
$ mkdir ~/.keras
$ vi ~/.keras/keras.json


{
    "epsilon": 1e-07,
    "floatx": "float32",
    "image_data_format": "channels_last",
    "backend": "theano"
}
```

**(6) Activate your python3.6 environment and manually install deepdist tool**

```
cd tools/deepdist

a. python setup.py

b. python configure.py

c. sh installation/set_env.sh
```

**(7) Manually install DistRank tool**

```
cd ../DistRank

mkdir env

python configure.py

sh installation/set_env.sh

```

**(8) Run DeepRank3 for quality assessment**

```
   Usage:
   $ sh bin/DeepRank3_Cluster.sh <target id> <file name>.fasta <model directory> <output folder>

   Example:
   $ sh bin/DeepRank3_Cluster.sh T0953s1 examples/T0953s1.fasta examples/T0953s1 examples/test_out
   
   $ sh bin/DeepRank3_SingleQA.sh T0953s1 examples/T0953s1.fasta examples/T0953s1 examples/test_out

   $ sh bin/DeepRank3_SingleQA_lite.sh T0953s1 examples/T0953s1.fasta examples/T0953s1 examples/test_out

```