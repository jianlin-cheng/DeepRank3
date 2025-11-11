# 🧬 **DeepRank3**
**A Deep Learning Method for Ranking Protein Structural Models**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python 2.7](https://img.shields.io/badge/python-2.7-blue.svg)](https://www.python.org/)
[![Python 3.6](https://img.shields.io/badge/python-3.6-blue.svg)](https://www.python.org/)
[![Backend: Theano](https://img.shields.io/badge/backend-Theano-green.svg)](https://github.com/Theano/Theano)

---

## 🚀 Overview
**DeepRank3** is a deep learning-based system designed for **ranking and quality assessment** of protein structural models.  
It integrates multiple deep learning modules, tools, and databases to estimate the accuracy of protein tertiary and quaternary structures.

---

## 📦 1. Download and Install DeepRank3
> ⚠️ Use a **short installation path** to avoid file path length issues.

```bash
git clone https://github.com/jianlin-cheng/DeepRank3.git
# If cloning fails, try with your GitHub username:
git clone https://huge200890@github.com/jianlin-cheng/DeepRank3.git

cd DeepRank3

wget "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
bash Mambaforge-$(uname)-$(uname -m).sh  # accept all terms and install to the default location
rm Mambaforge-$(uname)-$(uname -m).sh  # (optionally) remove installer after using it
source ~/.bashrc  # alternatively, one can restart their shell session to achieve the same result
```

---

## 🧰 2. Setup Database and Tools

### a. Install python2.7 environment

```
mamba create python27 python=2.7
mamba activate python27
```

### b. Edit `setup_database.pl`
1. Create a directory for databases:
   ```bash
   mkdir -p /data/commons/DeepRank_db_tools/
   ```
2. Set the variable `$DeepRank_db_tools_dir` in `setup_database.pl`:
   ```perl
   $DeepRank_db_tools_dir = "/data/commons/DeepRank_db_tools/";
   ```

### c. Run setup
```bash
perl setup_database.pl
```

> 📘 Please refer to **`cite_methods_for_publication.txt`** for citation guidelines.  
> All external tools can also be downloaded from their respective official websites.

---

## ⚙️ 3. Configure DeepRank3

### a. Edit `configure.pl`
Set the same database path used above:
```perl
$DeepRank_db_tools_dir = "/data/commons/DeepRank_db_tools/";
```

### b. Save and run:
```bash
perl configure.pl
```

---

## 🐍 4. Verify Python Environment

Activate the virtual environment:
```bash
source DeepRank_db_tools/tools/python_virtualenv/bin/activate
```

If it fails, manually install the environment:
```bash
sh installation/DeepRank_manually_install_files/P4_python_virtual.sh
```
</details>

---

## 🔧 5. Configure Keras Backend

Set **Theano** as the backend:
```bash
mkdir -p ~/.keras
vi ~/.keras/keras.json
```

Paste:
```json
{
    "epsilon": 1e-07,
    "floatx": "float32",
    "image_data_format": "channels_last",
    "backend": "theano"
}
```
</details>

---

## 🧠 6. Install DeepDist Tool (Python 3.6)

```bash

#Install Python 3.6 environment:
mamba create python36 python=3.6
mamba activate python36

cd tools/deepdist
python setup.py
python configure.py
sh installation/set_env.sh
```

---

## 📊 7. Install DistRank Tool

```bash
mamba activate python36
cd ../DistRank
mkdir env
python configure.py
sh installation/set_env.sh
```

---

## 🧩 8. Run DeepRank3 for Quality Assessment

### 🔹 **Usage**
```bash
sh bin/DeepRank3_Cluster.sh <target_id> <fasta_file> <model_dir> <output_dir>
```

### 🔹 **Examples**
```bash
mamba activate python27

# Cluster-based ranking
sh bin/DeepRank3_Cluster.sh T0953s1 examples/T0953s1.fasta examples/T0953s1 examples/test_out

# Single-model QA
sh bin/DeepRank3_SingleQA.sh T0953s1 examples/T0953s1.fasta examples/T0953s1 examples/test_out

# Lightweight QA
sh bin/DeepRank3_SingleQA_lite.sh T0953s1 examples/T0953s1.fasta examples/T0953s1 examples/test_out
```

---

## 🧾 Citation
If you use **DeepRank3** or its components in your research, please cite the corresponding methods listed in:
```

@article{liu2022improving,
  title={Improving protein tertiary structure prediction by deep learning and distance prediction in CASP14},
  author={Liu, Jian and Wu, Tianqi and Guo, Zhiye and Hou, Jie and Cheng, Jianlin},
  journal={Proteins: Structure, Function, and Bioinformatics},
  volume={90},
  number={1},
  pages={58--72},
  year={2022},
  publisher={Wiley Online Library}
}

cite_methods_for_publication.txt
```

---

## 📜 License
This project is released under the [MIT License](LICENSE).
