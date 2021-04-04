$num = @ARGV;

if($num != 3)
{
  die "The number of parameter is not correct!\n";
}

$test_datafile = $ARGV[0];
$results_prediction_test = $ARGV[1];
$results_prediction_out = $ARGV[2];#DCNN_results_withFeature_test.txt




print "## read test  prediction\n";
open(OUT,">$results_prediction_out") || die "Failed to find file $results_prediction_out\n";;
open(IN,$results_prediction_test) || die "Failed to find $results_prediction_test\n";
%test_predict_hash = ();
$c=0;
while(<IN>)
{
  $line=$_;
  chomp $line;
  $c++;
  $test_predict_hash{$c} = $line;
}
close IN;

open(IN,$test_datafile) || die "Failed to find $test_datafile\n";
@content = <IN>;
close IN;

$title = shift @content;
chomp $title;
$titlenew =$title.' 35:DeepRank';
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
  $predict_val = $test_predict_hash{$c2};
  @tmp2 = split(/\t/,$predict_val);
  if($tmp2[0] != $native_lga)
  {
    die "Wrong native lga information\n";
  }
  
  $linenew = $native_lga.' '.join(' ',@tmp).' 35:'.$tmp2[1]." $model_name";
  print OUT "$linenew\n";
}
close IN;
close OUT;
if($c !=$c2)
{
  die "Inmatch lines ($c !=$c2)\n";
}





