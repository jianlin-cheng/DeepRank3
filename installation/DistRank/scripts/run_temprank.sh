export GPUARRAY_FORCE_CUDA_DRIVER_LOAD=""
export HDF5_USE_FILE_LOCKING=FALSE
temp_dir=$(pwd)
##GLOBAL_FLAG
global_dir=/home/jianliu/DeepRank3/DeepRank_db_tools/tools/DistRank
## ENV_FLAG
source $global_dir/env/distrank_virenv/bin/activate 
model_dir=$global_dir/output/T0949
dist_map=$global_dir/example/T0949.txt
fasta=$global_dir/example/T0949.fasta
hhsuite_dir=/exports/store2/casp14/test/hhsuite_local2model/test/T0949/full_length/hhsuite
## DB_FLAG
databases=/exports/store2/casp14/databases/RCSB_PDB/atom/
output_dir=$global_dir/output/T0949

python $global_dir/libhhsuite_local2model.py -f $fasta -hs $hhsuite_dir -db  $databases -out $model_dir
python $global_dir/lib/template_rank.py -m $model_dir -d $dist_map -f $fasta -o $output_dir







