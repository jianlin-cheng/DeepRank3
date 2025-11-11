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
```

---

<details>
<summary>🧰 <b>2. Setup Database and Tools (Required)</b></summary>

Activate your **Python 2.7** environment first.

### a. Edit `setup_database.pl`
1. Create a directory for databases:
   ```bash
   mkdir -p /data/commons/DeepRank_db_tools/
   ```
2. Set the variable `$DeepRank_db_tools_dir` in `setup_database.pl`:
   ```perl
   $DeepRank_db_tools_dir = "/data/commons/DeepRank_db_tools/";
   ```

### b. Run setup
```bash
perl setup_database.pl
```

> 📘 Please refer to **`cite_methods_for_publication.txt`** for citation guidelines.  
> All external tools can also be downloaded from their respective official websites.
</details>

---

<details>
<summary>⚙️ <b>3. Configure DeepRank3 (Required)</b></summary>

### a. Edit `configure.pl`
Set the same database path used above:
```perl
$DeepRank_db_tools_dir = "/data/commons/DeepRank_db_tools/";
```

### b. Save and run:
```bash
perl configure.pl
```
</details>

---

<details>
<summary>🐍 <b>4. Verify Python Environment (Required)</b></summary>

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

<details>
<summary>🔧 <b>5. Configure Keras Backend (Required)</b></summary>

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

<details>
<summary>🧠 <b>6. Install DeepDist Tool (Python 3.6)</b></summary>

Activate your **Python 3.6** environment:
```bash
cd tools/deepdist
python setup.py
python configure.py
sh installation/set_env.sh
```
</details>

---

<details>
<summary>📊 <b>7. Install DistRank Tool</b></summary>

```bash
cd ../DistRank
mkdir env
python configure.py
sh installation/set_env.sh
```
</details>

---

## 🧩 8. Run DeepRank3 for Quality Assessment

### 🔹 **Usage**
```bash
sh bin/DeepRank3_Cluster.sh <target_id> <fasta_file> <model_dir> <output_dir>
```

### 🔹 **Examples**
```bash
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
cite_methods_for_publication.txt
```

---

## 🧑‍💻 Authors
**Developed by:**  
[**Jianlin Cheng Lab**](http://sysbio.rnet.missouri.edu)  
University of Missouri, Columbia

---

## 📜 License
This project is released under the [MIT License](LICENSE).
