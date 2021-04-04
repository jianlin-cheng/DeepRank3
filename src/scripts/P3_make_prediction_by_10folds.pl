#!/usr/bin/perl -w
use POSIX;

if (@ARGV != 4 ) {
  print "Usage: <input> <output>\n";
  exit;
}


$traindata = $ARGV[0];  
$label = $ARGV[1]; 
$fold_models_dir = $ARGV[2];
$outputdir = $ARGV[3]; 


if(!(-d $outputdir))
{
  `mkdir $outputdir`;
}

### get loss summary for each fold
for($i=1;$i<=10;$i++)
{

  $folddir = "$fold_models_dir/fold${i}";
  if(!(-d $folddir))
  {
    die "Failed to find directory $folddir\n\n";
  }
  print "\n\n\nProcessing $folddir\n\n";
  
  
  `python /home/jianliu/DeepRank3/src/scripts/python_lib/predict_main_auto_NN_single.py nadam $traindata  $folddir $outputdir/fold${i}model_for_$label.txt`;




}


	
