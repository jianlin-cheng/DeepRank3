$num = @ARGV;
if($num != 4)
{
  die "The number of parameter is not correct!\n";
}

$val_datafile = $ARGV[0];
$label = $ARGV[1]; 
$results_prediction_val_dir = $ARGV[2];
$results_prediction_val_withpred = $ARGV[3];


print "## read val  prediction\n";


`cp $val_datafile $results_prediction_val_withpred`;
for($i=1;$i<=10;$i++)
{
  print "Adding fold$i prediction for $label data\n\n";
  $results_prediction_val="$results_prediction_val_dir/fold${i}model_for_$label.txt";
  open(IN,$results_prediction_val) || die "Failed to find $results_prediction_val\n";
  @content = <IN>;
  close IN;
  %val_predict_hash = ();
  $c=0;
  foreach (@content)
  {
    $line=$_;
    chomp $line;
    $c++;
    $val_predict_hash{$c} = $line;
  }
  close IN;
  
  open(IN,$results_prediction_val_withpred) || die "Failed to find $results_prediction_val_withpred\n";
  @content = <IN>;
  close IN;
  
  open(OUT,">$results_prediction_val_withpred") || die "Failed to find file $results_prediction_val_withpred\n";
  $title = shift @content;
  chomp $title;
  $newid = 23 + $i;
  $titlenew =$title." $newid:DeepRank_fold".${i};
  print OUT "$titlenew\n";
  $c2=0;
  foreach $line (@content)
  {
    chomp $line;
    if(index($line,"#LGA") >=0)
    {
      next;
    }
    $c2++;
    @tmp = split(' ',$line);
    $native_lga = shift @tmp;
    $model_name = pop @tmp;
    chomp $model_name;
    $predict_val = $val_predict_hash{$c2};
    @tmp2 = split(/\t/,$predict_val);
    if($tmp2[0] != $native_lga)
    {
      die "Wrong native lga information\n";
    }
    
    $linenew = $native_lga.' '.join(' ',@tmp)." $newid:".$tmp2[1]." $model_name";
    print OUT "$linenew\n";
  }
  close IN;
  close OUT;
}





