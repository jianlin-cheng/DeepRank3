$num = @ARGV;



if($num != 4)
{
  die "The number of parameter is not correct!\n";
}

$val_datafile = $ARGV[0];
$label = $ARGV[1]; 
$results_prediction_val_dir = $ARGV[2]; #/storage/htc/bdm/jh7x3/DeepCov_human_QA/Model_training_keras_para_tunning/train_data_feature29_20180301/10_fold_data/10_fold_retrain_2nd_stage/results
$results_prediction_val_withpred = $ARGV[3];

#nb_filters = 10
#$val_datafile = $datadir.'/Validation_data.txt' ;       # here we use validation dataset, since the train and test data has been used in training already

#print "check file $train_datafile\n";


#$results_prediction_val = $resultdir."/DCNN_results_val.txt";


#$results_prediction_val_withpred = $resultdir."/DCNN_results_withFeature_val.txt";

#1:feature_DeepQA 2:feature_pairwiseScore 3:feature_RF_SRS 4:feature_dfire 5:feature_pcons 6:feature_RWplus 7:feature_voronot
#a 8:feature_dope 9:feature_proq2 10:feature_proq3_lowres 11:feature_proq3_highres 12:feature_proq3 13:feature_proq2D_global 14:fe
#ature_proq3D_global 15:feature_proq3D_ProQRosCenD_global 16:feature_proq3D_ProQRosFAD_global 17:modfoldclust2 18:feature_modeleva
# 19:feature_OPUS 20:feature_QApro 21:NOVEL_final_prediction 22:feature_total_surf 23:feature_ss_sim 24:feature_solvent 25:feature
#_surface 26:feature_weighted 27:feature_euclidean 28:feature_ss_penalty




print "## read val  prediction\n";


`cp $val_datafile $results_prediction_val_withpred`;

%val_predict_hash = ();
for($i=1;$i<=10;$i++)
{
  print "Adding fold$i prediction for $label data\n\n";
  $results_prediction_val="$results_prediction_val_dir/fold${i}model_for_$label.txt";
  open(IN,$results_prediction_val) || die "Failed to find $results_prediction_val\n";
  @content = <IN>;
  close IN;
  #%val_predict_hash = ();
  $c=0;
  foreach (@content)
  {
    $line=$_;
    chomp $line;
    $c++;
    if(!exists($val_predict_hash{$c}))
    {
    	@tmp2 = split(/\t/,$line);
	$val_predict_hash{$c} = $tmp2[0]." ".$tmp2[1];
    }else{
	@tmp2 = split(/\t/,$line);
	$val_predict_hash{$c} .= " ".$tmp2[1];	
    }
  }
  close IN;
  
}  
  open(IN,$results_prediction_val_withpred) || die "Failed to find $results_prediction_val_withpred\n";
  @content = <IN>;
  close IN;
  
  open(OUT,">$results_prediction_val_withpred") || die "Failed to find file $results_prediction_val_withpred\n";
  $title = shift @content;
  chomp $title;
  $newid = 18;
  $titlenew =$title." $newid:DeepCov_humanQA_fold_avg";
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
    @tmp2 = split(/\s/,$predict_val);
    if($tmp2[0] != $native_lga)
    {
      die "Wrong native lga information\n";
    }
    $avg_score = 0;
    $avg_num = 0;
    for($n=1;$n<@tmp2;$n++)
    {
	$avg_score = $avg_score + $tmp2[$n];
  	$avg_num ++;
    }
    if($avg_num != 10)
    {
	die "The fold num ($avg_num) is not correct!\n$predict_val\n";
   
    }

    $avg_score /= $avg_num;
    $linenew = $native_lga.' '.join(' ',@tmp)." $newid:".$avg_score." $model_name";
    print OUT "$linenew\n";
  }
  close IN;
  close OUT;





