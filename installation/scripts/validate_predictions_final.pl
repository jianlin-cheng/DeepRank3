#!/usr/bin/perl -w

# perl /home/jh7x3/DeepRank/installation/scripts/validate_predictions_final.pl T0980s1 /home/jh7x3/DeepRank/test_out/T0980s1_DeepRank /home/jh7x3/DeepRank/installation/benchmark/T0980s1


if (@ARGV != 3) {
  print "Usage: structure1  structure2\n";
  exit;
}
$targetid = $ARGV[0];
$work_dir = $ARGV[1];
$benchmark_dir = $ARGV[2]; #installation/benchmark/T0980s1/

$GLOBAL_PATH="/home/jianliu/DeepRank3/";


$scoredir = "$work_dir/ALL_scores";
if(!(-d $scoredir))
{
	next; 
}

$DeepRank_score = "$work_dir/DeepRank_gdt_prediction.txt";
if(-e "$DeepRank_score")
{
	print "Found $DeepRank_score\n";
	`cp $DeepRank_score $scoredir/DeepRank.$targetid`;
}


$Benchmark_score = "$benchmark_dir/HumanQA_gdt_prediction.txt";
if(-e "$DeepRank_score")
{
	`cp $Benchmark_score $benchmark_dir/ALL_scores/DeepRank.$targetid`;
}

print "\n---------------------------------------------------------------------------------------------------\n";
opendir(FILES,"$scoredir") || die "Failed to open directory $scoredir\n";
@files = readdir(FILES);
closedir(FILES);


$loss_predict = 0;
$loss_benchmark = 0;
$correlation_predict = 0;
$correlation_benchmark = 0;
	
printf "\n%-30s\t", 'Method';
printf "%-20s\t", 'Predicted (Loss)';
printf "%-20s\t", 'Benchmark (Loss)';
printf "%-20s\t", 'Difference (Loss)';
printf "%-20s\t", 'Predicted (Correlation)';
printf "%-20s\t", 'Benchmark (Correlation)';
printf "%-20s\n", 'Difference (Correlation)';

$file_num = 0;
foreach $file (sort @files)
{
	if($file eq '.' or $file eq '..' or index($file,$targetid) < 0) #feature_pairwiseScore.T0980s1
	{
		next;
	}	
	
	@tmp = split(/\./,$file);
	if(@tmp !=2)
	{
		next;
	}
	$feature_name = $tmp[0];
	$predict_file = "$scoredir/$file";
	$benchmark_file = "$benchmark_dir/ALL_scores/$file";
	$LGA_score = "$benchmark_dir/ALL_scores/LGA_score.$targetid";
	
	if(!(-e $benchmark_file) or !(-e $LGA_score))
	{
		print "Failed to find $LGA_score or $benchmark_file\n";
		next;
	}
	
	
	open(TMP,$LGA_score) || die "Failed to open dir $LGA_score\n";
	@content = <TMP>;
	close TMP;
	$LGA_model_num = 0;
	%LGA_score_list=();
	foreach $line (@content)
	{
		chomp $line;
		if($line eq '.' or $line eq '..')
		{
			next;
		}
		$LGA_model_num++;
		@tmp = split(/\t/,$line);
	  $LGA_score_list{$tmp[0]} = $tmp[1]; # this is for prediction
	}		
	
	
	
	@all_features = ();
	
	push @all_features,$predict_file;
	push @all_features,$benchmark_file;

	### 2. check if all methods have generated score for models as LGA
	$incomplete = 0;
	$fea_id=0;
	$title = "LGA 1:predict 2:benchmark";
	foreach $method_score (@all_features)
	{
	  if(!(-e $method_score))
	  {
		 print "$targetid incomplete (missing $method_score)\n";
		 $incomplete=1;
		 last;
	  }
	  
	  ## check if model number match 
	  open(IN,"$method_score") || die "Failed to open file $method_score\n";
	  $model_num = 0;
	  while(<IN>)
	  {
		$line=$_;
		chomp $line;
		$line =~ s/^\s+|\s+$//g;
		
		@tmp = split(/\s++/,$line);
		$model = $tmp[0];
		$score = $tmp[1];
		
		
		if(index($method_score,'feature_SBROD')>=0)
		{
		  @tmp2 = split(/\//,$model);
		  $model = pop @tmp2;
		  chomp $model;
		  
		}
		
		#if(substr($model,length($model)-4) ne '.pdb') ## proq will report no subfix
		#{
		#	$model .= '.pdb';
		#}
		if(!exists($LGA_score_list{$model}))
		{
		  next;
		}
		
		$model_num++;
	  }
	  close IN; 
	  if($model_num!=$LGA_model_num)
	  {
		 print "The model number in $method_score ($model_num) not match model number ($LGA_model_num)\n";
		 $incomplete=1;
		 last;
		
	  }
	  
	  
	  ### output the socre 
	  $fea_id++;
	  #print "\t\topening $method_score\n";
	  open(IN,"$method_score") || die "Failed to open file $method_score\n";
	  while(<IN>)
	  {
		$line=$_;
		chomp $line;
		
		$line =~ s/^\s+|\s+$//g;
		
		@tmp = split(/\s++/,$line);
		$model = $tmp[0];
		$score = $tmp[1];
		
		if(index($method_score,'feature_SBROD')>=0)
		{
		  @tmp2 = split(/\//,$model);
		  $model = pop @tmp2;
		  chomp $model;
		  
		}
		#if(substr($model,length($model)-4) ne '.pdb') ## proq will report no subfix
		#{
		#	$model .= '.pdb';
		#}
		if(!exists($LGA_score_list{$model}))
		{
		  next;
		}
		
		
		if(index($method_score,'feature_SBROD')>=0)
		{
		  @tmp2 = split(/\//,$model);
		  $model = pop @tmp2;
		  chomp $model;
		  
		}
		
		if(!defined($score))
		{
		  $score=0;
		}
		if(exists($LGA_score_list{$model}))
		{
		  $LGA_score_list{$model} .= " $fea_id:".$score;
		}else{
		  die "Couldn't find score for $model in $method_score\n";
		}
	  }
	  close IN;       
	  
	}

	if($incomplete==1)
	{
		print "!!!!!!!! $targetid is incomplete\n";
		next;
	}else
	{
		#print "$targetid is complete\n";
	}
	open(OUT1,">$predict_file.eva");
	print OUT1 "#$title\n";
	foreach $mod (sort keys %LGA_score_list)
	{
			@tmp = split(/\s/,$LGA_score_list{$mod});
			$fea_num = @tmp;
			if(@tmp != 3)
			{
			  print "!!!!!! Warning: Not enough scores ($fea_num) for model $mod, check $LGA_score_list{$mod},\n pass\n";
			}
			print OUT1 $LGA_score_list{$mod}." #$targetid:$mod\n";
	}
	close OUT1;
	
	#print "Evaluating $predict_file.eva\n";
	
	@eva_results = `python $GLOBAL_PATH/src/scripts/python_lib/evaluate_feature_per_target.py  $predict_file.eva $targetid`;
	if(@eva_results != 2)
	{
		print "Failed to run <python $GLOBAL_PATH/src/scripts/python_lib/evaluate_feature_per_target.py  $predict_file.eva $targetid>\n";
		
		next;
	}
	`rm $predict_file.eva`;
	$predict_eva = shift @eva_results;
	$benchmark_eva = shift @eva_results;
	chomp $predict_eva;
	chomp $benchmark_eva;
	@tmp1 = split(/\s+/,$predict_eva);
	@tmp2 = split(/\s+/,$benchmark_eva);
	
	
	printf "%-30s\t", $feature_name;
	printf "%-20f\t", $tmp1[4];
	printf "%-20f\t", $tmp2[4];
	printf "%-20f\t", abs($tmp1[4] - $tmp2[4]);
	printf "%-20f\t", $tmp1[3];
	printf "%-20f\t", $tmp2[3];
	printf "%-20f\n", abs($tmp1[3] - $tmp2[3]);
	$file_num ++;
	
	$loss_predict += $tmp1[4];
	$loss_benchmark += $tmp2[4];
	$correlation_predict += $tmp1[3];
	$correlation_benchmark += $tmp2[3];
	
}
if($file_num == 0)
{
	print "\nNo results are generated in $scoredir\n";
	next;
}
print "\n";
$loss_predict = sprintf("%.5f",$loss_predict/$file_num);
$loss_benchmark = sprintf("%.5f",$loss_benchmark/$file_num);
$correlation_predict = sprintf("%.5f",$correlation_predict/$file_num);
$correlation_benchmark = sprintf("%.5f",$correlation_benchmark/$file_num);

$diff = $loss_benchmark - $loss_predict;
$rmsd_diff = $correlation_benchmark - $correlation_predict;

printf "\n%-30s\t", 'Method';
printf "%-20s\t", 'Predicted (Loss)';
printf "%-20s\t", 'Benchmark (Loss)';
printf "%-20s\t", 'Difference (Loss)';
printf "%-20s\t", 'Predicted (Correlation)';
printf "%-20s\t", 'Benchmark (Correlation)';
printf "%-20s\n", 'Difference (Correlation)';

printf "%-30s\t", 'Average';
printf "%-20f\t", $loss_predict;
printf "%-20f\t", $loss_benchmark;
printf "%-20f\t", $diff;
printf "%-20f\t", $correlation_predict;
printf "%-20f\t", $correlation_benchmark;
printf "%-20f\n\n", $rmsd_diff;


print "done\n";
print "---------------------------------------------------------------------------------------------------\n\n";
sleep(1);



=pod

foreach $subdir (@subdirs)
{
	if($subdir eq '.' or $subdir eq '..' or index($subdir,$targetid) < 0)
	{
		next;
	}
	@tmp = split(/\_/,$subdir);
	if(@tmp <2)
	{
		next;
	}
	$server = $tmp[1];	
	if($server eq 'dncon2')
	{
		$dncon2_rr = "$work_dir/${targetid}.dncon2.rr";
		$dncon2_benchmark_file = "$benchmark_dir/$targetid/dncon2/${targetid}.dncon2.rr";
		
		$freecontact_rr = "$work_dir/freecontact/${targetid}.freecontact.rr";
		$freecontact_benchmark_file = "$benchmark_dir/$targetid/dncon2/freecontact/${targetid}.freecontact.rr";
		
		$psicov_rr = "$test_dir/$subdir/psicov/${targetid}.psicov.rr";
		$psicov_benchmark_file = "$benchmark_dir/$targetid/dncon2/psicov/${targetid}.psicov.rr";
		
		$ccmpred_rr = "$test_dir/$subdir/ccmpred/${targetid}.ccmpred";
		$ccmpred_rr2 = "$test_dir/$subdir/ccmpred/${targetid}.ccmpred.rr";
		$ccmpred_benchmark_file = "$benchmark_dir/$targetid/dncon2/ccmpred/${targetid}.ccmpred.rr";
		
		$native_pdb = "$benchmark_dir/$targetid.pdb";
		$native_seq = "$benchmark_dir/$targetid.fasta";
		
		
		
		if(-e $dncon2_rr)
		{
			print "\n---------------------------------------------------------------------------------------------------\n";
			print "Evaluating contact prediction for dncon2\n";
		
			## dncon2
			print  "\n\tLong-Range Precision\n";	
			($Predicted_TopL5,$Predicted_TopL2,$Predicted_TopL,$Predicted_Top2L) = get_coneva($native_seq,"$dncon2_rr",$native_pdb,"$test_dir/$subdir");
			#print  "\tBenchmark-contact (${targetid}.dncon2.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n";
			($benchmark_TopL5,$benchmark_TopL2,$benchmark_TopL,$benchmark_Top2L) = get_coneva($native_seq,"$dncon2_benchmark_file",$native_pdb,"$test_dir/$subdir");
			#print  "\tPredicted-contact (${targetid}.dncon2.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n\n";
			
			
			$TopL5_diff = $benchmark_TopL5 - $Predicted_TopL5;
			$TopL2_diff = $benchmark_TopL2 - $Predicted_TopL2;
			$TopL_diff = $benchmark_TopL - $Predicted_TopL;
			$Top2L_diff = $benchmark_Top2L - $Predicted_Top2L;

			printf "\n%-20s\t", 'Contact';
			printf "%-20s\t", 'Threshold';
			printf "%-20s\t", 'Predicted (Precision)';
			printf "%-20s\t", 'Benchmark (Precision)';
			printf "%-20s\n", 'Difference (Precision)';

			printf "%-20s\t", "${targetid}.dncon2.rr";
			printf "%-20s\t", 'Top L/5';
			printf "%-20f\t", $Predicted_TopL5;
			printf "%-20f\t", $benchmark_TopL5;
			printf "%-20f\n", $TopL5_diff;

			printf "%-20s\t", "${targetid}.dncon2.rr";
			printf "%-20s\t", 'Top L/2';
			printf "%-20f\t", $Predicted_TopL2;
			printf "%-20f\t", $benchmark_TopL2;
			printf "%-20f\n", $TopL2_diff;

			printf "%-20s\t", "${targetid}.dncon2.rr";
			printf "%-20s\t", 'Top L';
			printf "%-20f\t", $Predicted_TopL;
			printf "%-20f\t", $benchmark_TopL;
			printf "%-20f\n", $TopL_diff;

			printf "%-20s\t", "${targetid}.dncon2.rr";
			printf "%-20s\t", 'Top 2L';
			printf "%-20f\t", $Predicted_Top2L;
			printf "%-20f\t", $benchmark_Top2L;
			printf "%-20f\n", $Top2L_diff;
	
			print "done\n";
			print "---------------------------------------------------------------------------------------------------\n\n";
			sleep(1);
	
		}
		
		
		if(-e $freecontact_rr)
		{
			print "\n---------------------------------------------------------------------------------------------------\n";
			print "Evaluating contact prediction for freecontact\n";
			
			`perl $GLOBAL_PATH/installation/scripts/reformat_freecontact_rr.pl $freecontact_rr ${freecontact_rr}.tmp`;
			`perl $GLOBAL_PATH/installation/scripts/reformat_freecontact_rr.pl $freecontact_benchmark_file ${freecontact_benchmark_file}.tmp`;
			
			## freecontact
			chdir("$test_dir/$subdir");
			print  "\n\tLong-Range Precision\n";		
			($benchmark_TopL5,$benchmark_TopL2,$benchmark_TopL,$benchmark_Top2L) = get_coneva($native_seq,"${freecontact_benchmark_file}.tmp",$native_pdb,"$test_dir/$subdir");
			#print  "\tBenchmark-contact (${targetid}.freecontact.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n";
			
			($Predicted_TopL5,$Predicted_TopL2,$Predicted_TopL,$Predicted_Top2L) = get_coneva($native_seq,"${freecontact_rr}.tmp",$native_pdb,"$test_dir/$subdir");
			#print  "\tPredicted-contact (${targetid}.freecontact.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n\n";
				
			
			$TopL5_diff = $benchmark_TopL5 - $Predicted_TopL5;
			$TopL2_diff = $benchmark_TopL2 - $Predicted_TopL2;
			$TopL_diff = $benchmark_TopL - $Predicted_TopL;
			$Top2L_diff = $benchmark_Top2L - $Predicted_Top2L;

			printf "\n%-20s\t", 'Contact';
			printf "%-20s\t", 'Threshold';
			printf "%-20s\t", 'Predicted (Precision)';
			printf "%-20s\t", 'Benchmark (Precision)';
			printf "%-20s\n", 'Difference (Precision)';

			printf "%-20s\t", "${targetid}.freecontact.rr";
			printf "%-20s\t", 'Top L/5';
			printf "%-20f\t", $Predicted_TopL5;
			printf "%-20f\t", $benchmark_TopL5;
			printf "%-20f\n", $TopL5_diff;

			printf "%-20s\t", "${targetid}.freecontact.rr";
			printf "%-20s\t", 'Top L/2';
			printf "%-20f\t", $Predicted_TopL2;
			printf "%-20f\t", $benchmark_TopL2;
			printf "%-20f\n", $TopL2_diff;

			printf "%-20s\t", "${targetid}.freecontact.rr";
			printf "%-20s\t", 'Top L';
			printf "%-20f\t", $Predicted_TopL;
			printf "%-20f\t", $benchmark_TopL;
			printf "%-20f\n", $TopL_diff;

			printf "%-20s\t", "${targetid}.freecontact.rr";
			printf "%-20s\t", 'Top 2L';
			printf "%-20f\t", $Predicted_Top2L;
			printf "%-20f\t", $benchmark_Top2L;
			printf "%-20f\n", $Top2L_diff;
	
			print "done\n";
			print "---------------------------------------------------------------------------------------------------\n\n";
			sleep(1);
		
		}
		
		if(-e $psicov_rr)
		{
			print "\n---------------------------------------------------------------------------------------------------\n";
			print "Evaluating contact prediction for psicov\n";
		
			## psicov
			print  "\n\tLong-Range Precision\n";	
			($Predicted_TopL5,$Predicted_TopL2,$Predicted_TopL,$Predicted_Top2L) = get_coneva($native_seq,"$psicov_rr",$native_pdb,"$test_dir/$subdir");
			#print  "\tBenchmark-contact (${targetid}.psicov.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n";
			($benchmark_TopL5,$benchmark_TopL2,$benchmark_TopL,$benchmark_Top2L) = get_coneva($native_seq,"$psicov_benchmark_file",$native_pdb,"$test_dir/$subdir");
			#print  "\tPredicted-contact (${targetid}.psicov.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n\n";
			
			$TopL5_diff = $benchmark_TopL5 - $Predicted_TopL5;
			$TopL2_diff = $benchmark_TopL2 - $Predicted_TopL2;
			$TopL_diff = $benchmark_TopL - $Predicted_TopL;
			$Top2L_diff = $benchmark_Top2L - $Predicted_Top2L;

			printf "\n%-20s\t", 'Contact';
			printf "%-20s\t", 'Threshold';
			printf "%-20s\t", 'Predicted (Precision)';
			printf "%-20s\t", 'Benchmark (Precision)';
			printf "%-20s\n", 'Difference (Precision)';

			printf "%-20s\t", "${targetid}.psicov.rr";
			printf "%-20s\t", 'Top L/5';
			printf "%-20f\t", $Predicted_TopL5;
			printf "%-20f\t", $benchmark_TopL5;
			printf "%-20f\n", $TopL5_diff;

			printf "%-20s\t", "${targetid}.psicov.rr";
			printf "%-20s\t", 'Top L/2';
			printf "%-20f\t", $Predicted_TopL2;
			printf "%-20f\t", $benchmark_TopL2;
			printf "%-20f\n", $TopL2_diff;

			printf "%-20s\t", "${targetid}.psicov.rr";
			printf "%-20s\t", 'Top L';
			printf "%-20f\t", $Predicted_TopL;
			printf "%-20f\t", $benchmark_TopL;
			printf "%-20f\n", $TopL_diff;

			printf "%-20s\t", "${targetid}.psicov.rr";
			printf "%-20s\t", 'Top 2L';
			printf "%-20f\t", $Predicted_Top2L;
			printf "%-20f\t", $benchmark_Top2L;
			printf "%-20f\n", $Top2L_diff;
	
			print "done\n";
			print "---------------------------------------------------------------------------------------------------\n\n";
			sleep(1);
	
		}
		
		if(-e $ccmpred_rr)
		{
			print "\n---------------------------------------------------------------------------------------------------\n";
			print "Evaluating contact prediction for ccmpred\n";

			`python $GLOBAL_PATH/installation/scripts/cmap2rr.py $ccmpred_rr $ccmpred_rr.rr`;
			## ccmpred
			print  "\n\tLong-Range Precision\n";	
			($Predicted_TopL5,$Predicted_TopL2,$Predicted_TopL,$Predicted_Top2L) = get_coneva($native_seq,"$ccmpred_rr.rr",$native_pdb,"$test_dir/$subdir");
			#print  "\tBenchmark-contact (${targetid}.ccmpred.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n";
			($benchmark_TopL5,$benchmark_TopL2,$benchmark_TopL,$benchmark_Top2L) = get_coneva($native_seq,"$ccmpred_benchmark_file.rr",$native_pdb,"$test_dir/$subdir");
			#print  "\tPredicted-contact (${targetid}.ccmpred.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n\n";
			
			$TopL5_diff = $benchmark_TopL5 - $Predicted_TopL5;
			$TopL2_diff = $benchmark_TopL2 - $Predicted_TopL2;
			$TopL_diff = $benchmark_TopL - $Predicted_TopL;
			$Top2L_diff = $benchmark_Top2L - $Predicted_Top2L;

			printf "\n%-20s\t", 'Contact';
			printf "%-20s\t", 'Threshold';
			printf "%-20s\t", 'Predicted (Precision)';
			printf "%-20s\t", 'Benchmark (Precision)';
			printf "%-20s\n", 'Difference (Precision)';

			printf "%-20s\t", "${targetid}.ccmpred.rr";
			printf "%-20s\t", 'Top L/5';
			printf "%-20f\t", $Predicted_TopL5;
			printf "%-20f\t", $benchmark_TopL5;
			printf "%-20f\n", $TopL5_diff;

			printf "%-20s\t", "${targetid}.ccmpred.rr";
			printf "%-20s\t", 'Top L/2';
			printf "%-20f\t", $Predicted_TopL2;
			printf "%-20f\t", $benchmark_TopL2;
			printf "%-20f\n", $TopL2_diff;

			printf "%-20s\t", "${targetid}.ccmpred.rr";
			printf "%-20s\t", 'Top L';
			printf "%-20f\t", $Predicted_TopL;
			printf "%-20f\t", $benchmark_TopL;
			printf "%-20f\n", $TopL_diff;

			printf "%-20s\t", "${targetid}.ccmpred.rr";
			printf "%-20s\t", 'Top 2L';
			printf "%-20f\t", $Predicted_Top2L;
			printf "%-20f\t", $benchmark_Top2L;
			printf "%-20f\n", $Top2L_diff;
	
			print "done\n";
			print "---------------------------------------------------------------------------------------------------\n\n";
			sleep(1);
	
		}elsif(-e $ccmpred_rr2)
		{
			print "\n---------------------------------------------------------------------------------------------------\n";
			print "Evaluating contact prediction for ccmpred\n";
			## ccmpred
			print  "\n\tLong-Range Precision\n";	
			($Predicted_TopL5,$Predicted_TopL2,$Predicted_TopL,$Predicted_Top2L) = get_coneva($native_seq,"$ccmpred_rr.rr",$native_pdb,"$test_dir/$subdir");
			#print  "\tBenchmark-contact (${targetid}.ccmpred.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n";
			($benchmark_TopL5,$benchmark_TopL2,$benchmark_TopL,$benchmark_Top2L) = get_coneva($native_seq,"$ccmpred_benchmark_file.rr",$native_pdb,"$test_dir/$subdir");
			#print  "\tPredicted-contact (${targetid}.ccmpred.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n\n";
			
			$TopL5_diff = $benchmark_TopL5 - $Predicted_TopL5;
			$TopL2_diff = $benchmark_TopL2 - $Predicted_TopL2;
			$TopL_diff = $benchmark_TopL - $Predicted_TopL;
			$Top2L_diff = $benchmark_Top2L - $Predicted_Top2L;

			printf "\n%-20s\t", 'Contact';
			printf "%-20s\t", 'Threshold';
			printf "%-20s\t", 'Predicted (Precision)';
			printf "%-20s\t", 'Benchmark (Precision)';
			printf "%-20s\n", 'Difference (Precision)';

			printf "%-20s\t", "${targetid}.ccmpred.rr";
			printf "%-20s\t", 'Top L/5';
			printf "%-20f\t", $Predicted_TopL5;
			printf "%-20f\t", $benchmark_TopL5;
			printf "%-20f\n", $TopL5_diff;

			printf "%-20s\t", "${targetid}.ccmpred.rr";
			printf "%-20s\t", 'Top L/2';
			printf "%-20f\t", $Predicted_TopL2;
			printf "%-20f\t", $benchmark_TopL2;
			printf "%-20f\n", $TopL2_diff;

			printf "%-20s\t", "${targetid}.ccmpred.rr";
			printf "%-20s\t", 'Top L';
			printf "%-20f\t", $Predicted_TopL;
			printf "%-20f\t", $benchmark_TopL;
			printf "%-20f\n", $TopL_diff;

			printf "%-20s\t", "${targetid}.ccmpred.rr";
			printf "%-20s\t", 'Top 2L';
			printf "%-20f\t", $Predicted_Top2L;
			printf "%-20f\t", $benchmark_Top2L;
			printf "%-20f\n", $Top2L_diff;
	
			print "done\n";
			print "---------------------------------------------------------------------------------------------------\n\n";
			sleep(1);
	
		}
		
		
	}
}

printf "\n%-20s\t", 'Method';
printf "%-20s\t", 'Difference';
printf "%-20s\n", 'Status';
foreach $server (sort keys %check_list)
{
	$diff= sprintf("%05f",$check_list{$server});
	if($diff > 0.1)
	{
		printf "%-20s\t", $server;
		printf "%-20f\t", $diff;
		printf "%-20s\n", 'Failed';
	}else{
		printf "%-20s\t", $server;
		printf "%-20f\t", $diff;
		printf "%-20s\n", 'Success';
	}
}
print "done\n";
print "---------------------------------------------------------------------------------------------------\n\n";
sleep(1);

=cut

sub cal_sim
{
	my ($file,$native) = (@_);
	$command1="$GLOBAL_PATH/tools/tm_score/TMscore_32 $file $native";
	my @result1=`$command1`;
	my $tmscore=0;
	my $maxscore=0;
	my $gdttsscore=0;
	my $rmsd=0;
	foreach $ln2 (@result1){
		chomp($ln2);
		if ("RMSD of  the common residues" eq substr($ln2,0,28)){
			$s1=substr($ln2,index($ln2,"=")+1);
			while (substr($s1,0,1) eq " ") {
				$s1=substr($s1,1);
			}
			$rmsd=1*$s1;
		}
		if ("TM-score" eq substr($ln2,0,8)){
			$s1=substr($ln2,index($ln2,"=")+2);
			$s1=substr($s1,0,index($s1," "));
			$tmscore=1*$s1;
		}
		if ("MaxSub-score" eq substr($ln2,0,12)){
			$s1=substr($ln2,index($ln2,"=")+2);
			$s1=substr($s1,0,index($s1," "));
			$maxscore=1*$s1;
		}
		if ("GDT-score" eq substr($ln2,0,9)){
			$s1=substr($ln2,index($ln2,"=")+2);
			$s1=substr($s1,0,index($s1," "));
			$gdttsscore=1*$s1;
		}
	}
	return ($gdttsscore,$rmsd);

	
}

sub get_coneva {
	my ($fasta,$rrfile,$native,$workdir) = (@_);
	`perl $GLOBAL_PATH/installation/scripts/cmap/coneva-camp.pl  -fasta $fasta  -rr $rrfile -pdb $native  -smin 24 -o $workdir/ &> /dev/null `;
	
	open(IN,"$workdir/long_Acc.txt") || die "Failed to open file $workdir/long_Acc.txt\n";
	@content = <IN>;
	close IN;
	shift @content;
	$line = shift @content;
	chomp $line;
	$results = substr($line,index($line,'(precision)')+length('(precision)'));
	$results =~ s/^\s+|\s+$//g;
	@tmp = split (/\s+/,$results);
	#$Top5=$tmp[0];    
	my $TopL10 =$tmp[1];
	my $TopL5=$tmp[2];
	my $TopL2=$tmp[3];
	my $TopL=$tmp[4];     
	my $Top2L=$tmp[5];
	`rm $workdir/long_Acc.txt`;
	return ($TopL5,$TopL2,$TopL,$Top2L);

}
