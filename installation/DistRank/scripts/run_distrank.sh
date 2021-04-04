export GPUARRAY_FORCE_CUDA_DRIVER_LOAD=""
export HDF5_USE_FILE_LOCKING=FALSE
temp_dir=$(pwd)
##GLOBAL_FLAG
global_dir=/home/jianliu/DeepRank3/DeepRank_db_tools/tools/DistRank
## ENV_FLAG
source $global_dir/env/distrank_virenv/bin/activate 
#target_lst=$global_dir/example/target.lst
#dist_map=$global_dir/example/T0949.txt
#fasta=$global_dir/example/T0949.fasta
#output_dir=$global_dir/output/T0949/

if [ $# -ne 4 ]
then
	echo "need three parameters : path of fasta sequence, directory of input pdbs, directory of output"
	exit 1
fi

fasta=$1
target_lst=$2
dist_map=$3
output_dir=$4
python $global_dir/lib/dfold_rank.py -f $target_lst -d $dist_map -fa $fasta -o $output_dir -r True







