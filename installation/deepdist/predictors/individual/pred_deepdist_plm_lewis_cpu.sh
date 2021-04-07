#!/bin/bash -l
#SBATCH -J  PRED
#SBATCH -o PRED-%j.out
#SBATCH -p Lewis,hpc4,hpc5
#SBATCH -N 1
#SBATCH -n 8
#SBATCH -t 2-00:00
#SBATCH --mem 20G

module load cuda/cuda-9.0.176
module load cudnn/cudnn-7.1.4-cuda-9.0.176
export GPUARRAY_FORCE_CUDA_DRIVER_LOAD=""
export HDF5_USE_FILE_LOCKING=FALSE
temp_dir=$(pwd)
##GLOBAL_FLAG
global_dir=/home/jianliu/github/DeepRank3/DeepRank_db_tools/tools/deepdist
## ENV_FLAG
source $global_dir/env/deepdist_virenv/bin/activate
models_dir[0]=$global_dir/models/pretrain/deepdist_v3rc_GR/2.dres152_deepcov_plm_pearson_pssm/
output_dir=$global_dir/predictors/results/T1019s1/
fasta=$global_dir/example/T1019s1.fasta
## DBTOOL_FLAG
db_tool_dir=/home/jianliu/github/DeepRank3/DeepRank_db_tools/tools/deepdist
printf "$global_dir\n"

#################database_path fasta model outputdir method option
python $global_dir/lib/Model_predict.py $db_tool_dir $fasta ${models_dir[@]} $output_dir 'mul_lable_R' 'ALN'
