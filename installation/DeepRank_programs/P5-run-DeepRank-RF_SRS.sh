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


echo "perl /home/jianliu/DeepRank3/src/scripts/run_DeepRank_RF_SRS.pl $targetid   $fasta  $model_dir  $outputfolder $contact_file $nativefile\n\n";								
perl /home/jianliu/DeepRank3/src/scripts/run_DeepRank_RF_SRS.pl $targetid   $fasta  $model_dir  $outputfolder $contact_file $nativefile  2>&1 | tee  RF_SRS.log


printf "\nFinished.."
printf "\nCheck log file <$outputfolder/RF_SRS.log>\n\n"


if [[ ! -f "$outputfolder/ALL_scores/feature_RF_SRS.$targetid" ]];then 
	printf "!!!!! Failed to run RF_SRS, check the installation </home/jianliu/DeepRank3/src/scripts/run_DeepRank_RF_SRS.pl>\n\n"
else
	printf "\nJob successfully completed!"
	cp $outputfolder/ALL_scores/feature_RF_SRS.$targetid $outputfolder/RF_SRS_prediction.$targetid
	printf "\nResults: $outputfolder/RF_SRS_prediction.$targetid\n\n"
fi

