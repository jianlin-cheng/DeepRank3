#!/bin/sh
# DeepRank prediction file for protein quality assessment #
if [ $# -lt 4 ]
then
	echo "need four parameters : target id, path of fasta sequence, directory of input pdbs, directory of output"
	exit 1
fi

targetid=$1 
fasta=$2 
model_dir=$3 
outputfolder=$4 

contact_file='None'
nativefile='None'

if [ $# -eq 5 ]
then
	contact_file=$5
	nativefile='None'
fi

if [ $# -eq 6 ]
then
	contact_file=$5
	nativefile=$6
fi


if [[ "$fasta" != /* ]]
then
   echo "Please provide absolute path for $fasta"
   exit
fi

if [[ "$outputfolder" != /* ]]
then
   echo "Please provide absolute path for $outputfolder"
   exit
fi


mkdir -p $outputfolder
cd $outputfolder

source /home/jianliu/DeepRank3/tools/python_virtualenv/bin/activate
export PATH=/home/jianliu/DeepRank3/tools/EMBOSS-6.6.0/bin/:$PATH
export LD_LIBRARY_PATH=/home/jianliu/DeepRank3/tools/EMBOSS-6.6.0/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/jianliu/DeepRank3/tools/rosetta_2014.16.56682_bundle/main/source/build/external/release/linux/2.6/64/x86/gcc/4.4/default/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/jianliu/DeepRank3/tools/rosetta_2014.16.56682_bundle/main/source/build/src/release/linux/2.6/64/x86/gcc/4.4/default/:$LD_LIBRARY_PATH

echo "perl /home/jianliu/DeepRank3/src/scripts/run_DeepRank_proq3.pl $targetid   $fasta  $model_dir  $outputfolder $contact_file $nativefile\n\n";								
perl /home/jianliu/DeepRank3/src/scripts/run_DeepRank_proq3.pl $targetid   $fasta  $model_dir  $outputfolder $contact_file $nativefile  2>&1 | tee  proq3.log


printf "\nFinished.."
printf "\nCheck log file <$outputfolder/proq3.log>\n\n"


if [[ ! -f "$outputfolder/ALL_scores/feature_proq3.$targetid" ]];then 
	printf "!!!!! Failed to run proq3, check the installation </home/jianliu/DeepRank3/src/scripts/run_DeepRank_proq3.pl>\n\n"
else
	printf "\nJob successfully completed!"
	cp $outputfolder/ALL_scores/feature_proq3.$targetid $outputfolder/proq3_prediction.$targetid
	cp $outputfolder/ALL_scores/feature_proq2.$targetid $outputfolder/proq2_prediction.$targetid
	printf "\nResults: $outputfolder/proq3_prediction.$targetid\n\n"
fi

