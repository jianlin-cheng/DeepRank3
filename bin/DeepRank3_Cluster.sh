#!/bin/sh
# HumanQA prediction file for protein quality assessment #
if [ $# -lt 4 ]
then
	echo "need four parameters : target id, path of fasta sequence, directory of input pdbs, directory of output"
	exit 1
fi

DeepRank_path=/home/jianliu/DeepRank3/

targetid=$1 #T0898
fasta=$2 #/home/casp13/Human_QA_package/Jie_dev_casp13/data/casp12_original_seq/T0898.fasta
model_dir=$3 #/home/casp13/Human_QA_package/HQA_cp12new//T0898/T0898
outputfolder=$4 #/home/casp13/Human_QA_package/HQA_cp12new//T0898
contact_file=$5
distmap_file=$6
nativefile=$7

source $DeepRank_path/tools/python_virtualenv/bin/activate
export PATH=$DeepRank_path/tools/EMBOSS-6.6.0/bin/:$PATH
export LD_LIBRARY_PATH=$DeepRank_path/tools/EMBOSS-6.6.0/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$DeepRank_path/tools/rosetta_2014.16.56682_bundle/main/source/build/external/release/linux/2.6/64/x86/gcc/4.4/default//:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$DeepRank_path/tools/rosetta_2014.16.56682_bundle/main/source/build/src/release/linux/2.6/64/x86/gcc/4.4/default/:$LD_LIBRARY_PATH



perl $DeepRank_path/src/scripts/DeepRank3_Cluster.pl  $targetid   $fasta  $model_dir  $outputfolder $contact_file $distmap_file $nativefile


