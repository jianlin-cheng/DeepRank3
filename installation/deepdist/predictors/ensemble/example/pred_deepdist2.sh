#!/bin/bash -l
export GPUARRAY_FORCE_CUDA_DRIVER_LOAD=""
export HDF5_USE_FILE_LOCKING=FALSE
temp_dir=$(pwd)
##GLOBAL_FLAG
global_dir=/home/jianliu/github/DeepRank3/DeepRank_db_tools/tools/deepdist
## ENV_FLAG
source $global_dir/env/deepdist_virenv/bin/activate
models_dir[0]=$global_dir/models/pretrain/MULTICOM-CONSTRUCT/1.dres152_deepcov_cov_ccmpred_pearson_pssm/
models_dir[1]=$global_dir/models/pretrain/MULTICOM-CONSTRUCT/2.dres152_deepcov_plm_pearson_pssm/
models_dir[2]=$global_dir/models/pretrain/MULTICOM-CONSTRUCT/3.res152_deepcov_pre_freecontact/
models_dir[3]=$global_dir/models/pretrain/MULTICOM-CONSTRUCT/4.res152_deepcov_other/
output_dir=$global_dir/predictors/results/T1019s1/
fasta=$global_dir/example/T1019s1.fasta
aln_file=$global_dir/example/T1019s1.aln
## DBTOOL_FLAG
db_tool_dir=/home/jianliu/github/DeepRank3/DeepRank_db_tools/tools/deepdist
printf "$global_dir\n"

#################database_path fasta MSA_file model outputdir method 
python $global_dir/lib/Model_predict_v2.py $db_tool_dir $fasta $aln_file ${models_dir[@]} $output_dir 'mul_class_C' 
