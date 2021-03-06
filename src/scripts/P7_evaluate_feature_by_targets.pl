$num = @ARGV;

if($num != 3)
{
  die "The number of parameter is not correct!\n";
}

$feature_summary = $ARGV[0];
$workdir = $ARGV[1];
$resultfile = $ARGV[2];

if(-e $resultfile)
{
  `rm $resultfile`;
}


#### get target list
open(IN,$feature_summary) || die "Failed to find $feature_summary\n";  # #T0838:eThread_TS2
%train_target_list = ();
$c=0;
while(<IN>)
{
  $line=$_;
  chomp $line;
  if(index($line,'#LGA')>=0)
  {
    next;
  }
  @tmp = split(/\s/,$line);
  $target_info = pop @tmp;
  @tmp2 = split(':',$target_info);
  $targetid = $tmp2[0];###T0838
  if(substr($targetid,0,1) eq '#')
  {
      $targetid = substr($targetid,1);
  }
  $train_target_list{$targetid} = 1;
}
close IN;


foreach $target (sort keys %train_target_list)
{
  chomp $target;
  print "grep $target  $feature_summary > $workdir/$target.txt\n";
  `grep $target  $feature_summary > $workdir/$target.txt`;
  
  print "python /home/jianliu/DeepRank3/src/scripts/python_lib/evaluate_feature_per_target.py $workdir/$target.txt $target >> $resultfile\n";
	`python /home/jianliu/DeepRank3/src/scripts/python_lib/evaluate_feature_per_target.py $workdir/$target.txt $target >> $resultfile`;
	
}
