#! /usr/bin/perl -w
=pod
You may freely copy and distribute this document so long as the copyright is left intact. You may freely copy and post unaltered versions of this document in HTML and Postscript formats on a web site or ftp site. Lastly, if you do something injurious or stupid
because of this document, I don't want to know about it. Unless it's amusing.
=cut
 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 use strict; # force disciplined use of variables
 sub merge_distribution($$);

 if (@ARGV < 13)
    { # @ARGV used in scalar context = number of args
	  print "For CASP11, this will make prediction for one target!\n";
	  print"This script apply the EM algorithm found best weight, and generate a prediction score from several features by distribution.!\n";

	  print "\n************** Renzhi Cao *******************\n";
	  print "Input:\n";
	  print "0. addr_RF_CB_SRS_OD score!\n";
	  print "1. addr_ss_simi score!\n";
	  print "2. addr_ss_penalty score!\n";
	  print "3. addr_euclidean pairwise score!\n";
	  print "4. addr_surface score!\n";
	  print "5. addr_weighted surface score!\n";
	  print "6. addr_total_surface score!\n";
	  print "7. addr_solvent_acc score!\n";
	  print "8. addr_RWplus score!\n";
	  print "9. addr_modeleva score!\n";
	  print "10. addr_dope score!\n";

	  print "11. address of merge_distribution \n";
	  
	  print "12. addr of output\n";
	  
	  print "\nThe weight for each feature is coded inside the script!\n";
      print "For example:\n";
	  print "perl $0 ../data/Features_for_CASP11/features_for_prediction/Single_features_casp10_stage2/0_normed_RF_CB_SRS_OD_casp10_stage2/T0724.norm_energy_score ../data/Features_for_CASP11/features_for_prediction/Single_features_casp10_stage2/1_feature_2_ss_simi_casp10_stage2_spineX/T0724.ss_similarity ../data/Features_for_CASP11/features_for_prediction/Single_features_casp10_stage2/2_feature_2_ss_penalty_casp10_stage2_spineX/T0724.ss_similarity ../data/Features_for_CASP11/features_for_prediction/Single_features_casp10_stage2/3_feature_3_eucl_casp10_stage2/T0724.pairwise_distance ../data/Features_for_CASP11/features_for_prediction/Single_features_casp10_stage2/4_feature_4_surface_casp10_stage2/T0724.fraction_of_exposed_nonpolar_residues ../data/Features_for_CASP11/features_for_prediction/Single_features_casp10_stage2/5_feature_4_weighted_casp10_stage2/T0724.fraction_of_weighted_exposed_area ../data/Features_for_CASP11/features_for_prediction/Single_features_casp10_stage2/6_feature_4_total_surf_casp10_stage2/T0724.fraction_of_surface_exposed ../data/Features_for_CASP11/features_for_prediction/Single_features_casp10_stage2/7_feature_6_solvent_acc_casp10_stage2/T0724.sol_similarity ../data/Features_for_CASP11/features_for_prediction/Single_features_casp10_stage2/8_RW_casp10_stage2/T0724.norm_RWplus_score ../data/Features_for_CASP11/features_for_prediction/Single_features_casp10_stage2/9_modeleva_casp10_stage2/T0724.modeleva_scores ../data/Features_for_CASP11/features_for_prediction/Single_features_casp10_stage2/10_dope_casp10_stage2/T0724.norm_dope_score ../bin/merge_dis ../test/test_weight_dis_T0724\n";
      exit(0);

	}

    my($merge_dis)=$ARGV[11];
	my($addr_output)=$ARGV[12];

	my($i);
    my($path,$line,$IN,$OUT);
	my(@tem);
	my(%hash)=();                          # key is model name , and the value is the 11 different scores
	
	my(@weights)=();
	$weights[0]=0.03;
	$weights[1]=0.09;
	$weights[2]=0.04;
	$weights[3]=0.08;
	$weights[4]=0.08;
	$weights[5]=0.01;
	$weights[6]=0.03;
	$weights[7]=0.10;
	$weights[8]=0.00;
	$weights[9]=0.09;
	$weights[10]=-0.02;
    


    for($i = 0; $i<11; $i++)
    {

            $path = $ARGV[$i];
            $IN = new FileHandle "$path";
            while(defined($line=<$IN>))
            {
                    chomp($line);
                    @tem = split(/\s+/,$line);
                    if(@tem<2)
                    {
                            next;
                    }
                    if($tem[0] eq "PFRMAT" || $tem[0] eq "TARGET" || $tem[0] eq "END" || $tem[0] eq "MODEL" || $tem[0] eq "QMODE")
                    {  # the head infor
                            next;
                    }
                    if(not exists $hash{$tem[0]})
                    {
                            $hash{$tem[0]} = $tem[1];
                    }
                    else
                    {
                            $hash{$tem[0]}.="|".$tem[1];
                    }

           }
           $IN->close();
	}

    my($key,$value,$new_prediction);
    my($TMP_file_in)=$addr_output."_"."TMP_IN";
    my($TMP_file_out)=$addr_output."_"."TMP_OUT";
	
    my(%dis_scores)=();

	foreach $key (keys %hash)
    {
		@tem=split(/\|/,$hash{$key});
		if(@tem != 11)
		{
			print "Not enough features for $key, check the value is $hash{$key}\n";
			next;
		}
        $new_prediction = merge_distribution(\@weights,\@tem);       #use the tool and get the prediction, the number of features is 12
		#print $OUT $key."\t".$new_prediction."\n";
		$dis_scores{$key}=$new_prediction;             # instead of output directly, we first keep the distribution score
	}
    
    my(@model_names)=();
    my(@model_scores)=();
    my($index)=0;
    foreach $key (sort{$dis_scores{$b} <=> $dis_scores{$a}} keys %dis_scores)
    {
        $model_names[$index]=$key;
        $model_scores[$index]=$dis_scores{$key};
        $index++;
    }

	############## now use the dope,RWplus,RF energy score to re-rank the distribution score ##########
	# 
	#
	#  Method: Select top 1/30 of total models, use energy re-rank them, and then go to the next (total/30)-2 starting models, re-rank them, for example, total=150, so we get the fragment size 5, first re-rank [0,5], then re-rank [3,8], ...., until we finish top 25% models, in this case, is around 38 models, stop re-ranking!
	#
	#
	###################################################################################################
    
	###### first get consensus score #######
	my($path_file);
	my(%con_score)=();

	$path_file = $ARGV[0];      # the score file 
	$IN = new FileHandle "$path_file";
	while(defined($line=<$IN>))
	{
		chomp($line);
		@tem = split(/\s+/,$line);
		if(@tem<2)
		{
			print "Warning, check $path_file, and $line\n";
			next;
		}
        if($tem[0] eq "PFRMAT" || $tem[0] eq "TARGET" || $tem[0] eq "END" || $tem[0] eq "MODEL" || $tem[0] eq "QMODE")
        {  # the head infor
                next;
        }
		$key = $tem[0];
		if(not exists $con_score{$key})
		{
			$con_score{$key} = $tem[1];
		}
		else
		{
			#print "Should not happen for the first one!\n";
			$con_score{$key}.="|".$tem[1];
		}
	}
	$IN->close();

	$path_file = $ARGV[8];      # the score file 
	$IN = new FileHandle "$path_file";
	while(defined($line=<$IN>))
	{
		chomp($line);
		@tem = split(/\s+/,$line);
		if(@tem<2)
		{
			print "Warning, check $path_file, and $line\n";
			next;
		}
        if($tem[0] eq "PFRMAT" || $tem[0] eq "TARGET" || $tem[0] eq "END" || $tem[0] eq "MODEL" || $tem[0] eq "QMODE")
        {  # the head infor
                next;
        }
		$key = $tem[0];
		if(not exists $con_score{$key})
		{
			$con_score{$key} = $tem[1];
		}
		else
		{
			#print "Should not happen for the first one!\n";
			$con_score{$key}.="|".$tem[1];
		}
	}
	$IN->close();

	$path_file = $ARGV[10];      # the score file 
	$IN = new FileHandle "$path_file";
	while(defined($line=<$IN>))
	{
		chomp($line);
		@tem = split(/\s+/,$line);
		if(@tem<2)
		{
			print "Warning, check $path_file, and $line\n";
			next;
		}
        if($tem[0] eq "PFRMAT" || $tem[0] eq "TARGET" || $tem[0] eq "END" || $tem[0] eq "MODEL" || $tem[0] eq "QMODE")
        {  # the head infor
                next;
        }
		$key = $tem[0];
		if(not exists $con_score{$key})
		{
			$con_score{$key} = $tem[1];
		}
		else
		{
			#print "Should not happen for the first one!\n";
			$con_score{$key}.="|".$tem[1];
		}
	}
	$IN->close();
    
	my($real_score);
	### get the average consensus score ####
	foreach $key (keys %con_score) 
	{
		@tem = split(/\|/,$con_score{$key});
		$real_score = 0;
		if(@tem==0)
		{
			print "Should not happen, just in case, set 0!\n";
			$real_score=0;
		}
		else
		{
			for($i=0;$i<@tem;$i++)
			{
				$real_score+=$tem[$i];
			}
			$real_score/=$i;
		}
		$con_score{$key}=$real_score;        # update the consensus score for the hash table, not it's the real score
	}

    my($NUM_frag)=int($index/30)-1;                 # the total number divide by 30 and minus 1 is the fragment size to re-rank
	my($top_quantile)=$index/4;              # this is the stop place for re-rank
	my($start,$end);
	my(%ranking)=();
	if($NUM_frag>2)
	{# if this is less than 2, then no need to re-rank
        for($start=0;$start<$index;$start+=$NUM_frag-2)
		{# for the fragment from start to end
			if($start > $top_quantile)
			{# no need to continue re-ranking
				last;
			}
			$end = $start+$NUM_frag;
			if($end>=$index)
			{
			    $end=$index-1;
			}
			%ranking=();
			for($i=$start;$i<=$end;$i++)
			{
				if(not exists $con_score{$model_names[$i]})
				{
					  print "Not find consensus score for this model $model_names[$i]!\n";
					  $ranking{$model_names[$i]} = 0;
				}
				else
			    {	 
			          $ranking{$model_names[$i]} = $con_score{$model_names[$i]};
				}
			}
			$i=$start;
			foreach $key (sort{$ranking{$b} <=> $ranking{$a}} keys %ranking)
			{
			    $model_names[$i] = $key;
				$i++;
		    } 
		}
	}
    
    ######## output the result #########

	$OUT = new FileHandle ">$addr_output";
    for($i=0;$i<$index;$i++)
	{
		print $OUT $model_names[$i]."\t".$model_scores[$i]."\n";
	}
    $OUT->close();





  sub merge_distribution($$)
  {# use merge_dis tool, and save in $TMP_file_in and $TMP_file_out
	  my($w,$score)=@_;          #two array, the weight and the scores
      my($IN,$line,$OUT);
	  my($i);
########## revise here #################
      my(@mean)=();
	  my(@std)=();

	  $mean[0]=-0.178707124909157;
	  $std[0]=0.20769364730811;
	  $mean[1]=-0.254131217569043;
	  $std[1]=0.185570981200672;
	  $mean[2]=-0.384116107013082;
	  $std[2]=0.200371798210845;
	  $mean[3]=-0.411864297329215;
	  $std[3]=0.227615576966251;
	  $mean[4]=-0.127359663562863;
	  $std[4]=0.222831888334913;
	  $mean[5]=-0.301439708166789;
	  $std[5]=0.219394061498718;
	  $mean[6]=-0.291457396938588;
	  $std[6]=0.217509933519533;
	  $mean[7]=-0.197580799645712;
	  $std[7]=0.182065562856944;
	  $mean[8]=-0.229766542287429;
	  $std[8]=0.191170904468352;
	  $mean[9]=-0.0219359185138082;
	  $std[9]=0.140017528467262;
	  $mean[10]=-0.185555192678053;
	  $std[10]=0.178752845686316;

########################################
      my($num_features)=scalar(@mean);
	  if(scalar(@$w) != $num_features)
	  {
		  print "The number of features is not consistant, why??? \n";
		  exit(0);
	  }
	  $OUT = new FileHandle ">$TMP_file_in";
	  print $OUT "$num_features\n";
	  for($i=0;$i<$num_features;$i++)
	  {
		  print $OUT $mean[$i]."\t".$std[$i]."\t".@$score[$i]."\t".@$w[$i]."\n";
	  }
	  $OUT->close();

	  system("$merge_dis $TMP_file_in $TMP_file_out");
	  $IN = new FileHandle "$TMP_file_out";
	  defined($IN) || die "cannot open the file $TMP_file_out, check the tool ./$merge_dis $TMP_file_in $TMP_file_out !\n";
	  if(defined($line=<$IN>))
	  {
		  chomp($line);          # this is the best score
	  }
	  $IN->close();
	  return $line;
  }
