#! /usr/bin/perl -w
#
 use Cwd;
 #use lib "/scratch/jh7x3/DeepCov_human_QA/tools/MIME-Lite-2.117/lib/";

# use email;
# use MIME::Lite;
 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 #use strict; # force disciplined use of variables
 use Cwd 'abs_path';
 use Scalar::Util qw(looks_like_number);
 sub filter_score($$);



 ############## Revise the path ########################
$DeepRank_install = "/home/jianliu/DeepRank3/";
$H_script = "$DeepRank_install/src/scripts";
$H_tool = "$DeepRank_install/tools";

 ########################################################


 if(@ARGV != 4)
 {
   die "The number of parameter is not correct!\n";
 }
 
 $targetname = $ARGV[0];
 $seqfile = $ARGV[1];
 $dir_models = $ARGV[2];
 $dir_output = $ARGV[3];
 
 ###### get sequence 
 open(IN,"$seqfile") || die "Fail to open file $seqfile\n";
 @content = <IN>;
 close IN;
 
 if(@content <2)
 {
   die "The seqfile should have two rows!\n";
 }
 
 shift @content;
 $sequence = shift @content;
 chomp $targetname;
 chomp $sequence;
 
 
$DeepRank_starttime = time();


##### create folder
-s $dir_output || system("mkdir $dir_output");
$dir_output = abs_path($dir_output);
my($TMP_output) = $dir_output."/"."TMP";
-s $TMP_output || system("mkdir $TMP_output");

#`rm -rf $TMP_output/*`;
my($LOG_output) = $dir_output."/"."LOG";
-s $LOG_output || system("mkdir $LOG_output");


 system("chmod 777 $TMP_output");
 my($tmp_tarball,$CASPTAR);
 $TMP_output = abs_path($TMP_output);
 
 
### mention here, we change the working directory to $TMP_output !
chdir($TMP_output);

## write out the fasta file
$|=1;
my($fasta_seq) = $TMP_output."/".$targetname.".fasta";
$OUT = new FileHandle ">$fasta_seq";
defined($OUT) || die "Cannot write to $fasta_seq!\n";
print $OUT ">$targetname\n";
print $OUT "$sequence";
$OUT->close();


my($fasta_seq2) = $TMP_output."/".$targetname;
$OUT = new FileHandle ">$fasta_seq2";
defined($OUT) || die "Cannot write to $fasta_seq2!\n";
print $OUT ">$targetname\n";
print $OUT "$sequence";
$OUT->close();


## write the new model
my($models_folder) = $TMP_output."/".$targetname."_2";
if(-d $models_folder)
{
	`rm -rf $models_folder/*`;
}else{
	mkdir($models_folder);
}
system("cp -R $dir_models/* $models_folder");


my($models_proq3) = $TMP_output."/mod_proq3";
=pod
if(-d $models_proq3)
{
	`rm -rf $models_proq3/*`;
}else{
	mkdir($models_proq3);
}
system("cp -R $dir_models/* $models_proq3");
=cut

my($models_local_global) = $TMP_output."/mod_locglo";
=pod
if(-d $models_local_global)
{
	`rm -rf $models_local_global/*`;
}else{
	mkdir($models_local_global);
}
system("cp -R $dir_models/* $models_local_global");
=cut

my($models_DeepQA) = $TMP_output."/mod_DeepQA";

if(-d $models_DeepQA)
{
	`rm -rf $models_DeepQA/*`;
}else{
	mkdir($models_DeepQA);
}
system("cp -R $dir_models/* $models_DeepQA");


my($models_dncon2) = $TMP_output."/mod_dncon2";
=pod
if(-d $models_dncon2)
{
	`rm -rf $models_dncon2/*`;
}else{
	mkdir($models_dncon2);
}
system("cp -R $dir_models/* $models_dncon2");
=cut


### now we get every thing I need #####
# we are at $TMP_output folder #
my($OUTLOG,$logfile);
$logfile = $TMP_output."/"."log.txt";
$OUTLOG = new FileHandle ">$logfile";
 
 
$task_dir = $TMP_output;
$name= $targetname;

############## running all jobs #####################
$ren_features=$TMP_output."/"."local_global_features";
$ren_RF_SRS=$TMP_output."/"."feature_RF_SRS.".$targetname;
$ren_RWplus=$TMP_output."/"."feature_RWplus.".$targetname;
$ren_dope=$TMP_output."/"."feature_dope.".$targetname;
$ren_OPUS = $TMP_output."/"."feature_OPUS.".$targetname;


$ALL_scores = $dir_output."/"."ALL_scores/";
-s $ALL_scores || system("mkdir -p  $ALL_scores");

$ALL_14_scores = $dir_output."/"."ALL_14_scores/";
-s $ALL_14_scores || system("mkdir -p $ALL_14_scores");
 
$score_modfold = $TMP_output."/"."modfoldclust2.".$targetname;
$score_pcons = $TMP_output."/"."feature_pcons.".$targetname;
$pairwise_out = $TMP_output."/"."pairwise";
system("mkdir -p $pairwise_out");

$score_pairwise = $pairwise_out."/".$name.".gdt";

$ren_voronota=$TMP_output."/"."feature_voronota.".$targetname;

$ren_Proq2_global=$TMP_output."/"."feature_proq2.".$targetname;
$ren_Proq3_global=$TMP_output."/"."feature_proq3.".$targetname;
$ren_Proq3_lowres=$TMP_output."/"."feature_proq3_lowres.".$targetname;
$ren_Proq3_highres=$TMP_output."/"."feature_proq3_highres.".$targetname;

$ren_DeepQA=$TMP_output."/"."feature_DeepQA.".$targetname;

$ren_SBROD = $TMP_output."/"."feature_SBROD.".$targetname;
$ren_dncon2_short=$TMP_output."/"."feature_dncon2_short-range.".$targetname;
$ren_dncon2_medium=$TMP_output."/"."feature_dncon2_medium-range.".$targetname;
$ren_dncon2_long=$TMP_output."/"."feature_dncon2_long-range.".$targetname;


#$tools2		="OPUS,local_global,RF_SRS,RWplus,dope,modfoldclust2,pcons,pairwise,voronota,DeepQA,Proq3,SBROD,dncon2";
$tools2		="DeepQA";
@tools		=split(/,/,$tools2);

$post_process = 0; 
$thread_num = @tools;
%thread_ids = ();
$EXEC_LIMIT_HRS = 60*60*24*2;#48 hrs
 
#$EXEC_LIMIT_HRS = 60*3;#10 hrs
for ($i = 0; $i < @tools; $i++)
{
	$tool = $tools[$i];
	if ( !defined( $kidpid = fork() ) )
	{
		die "can't create process $i to run <$tool>\n";
	}
	elsif ($kidpid == 0)
	{
		print "start thread $i\n";
		if ($tool eq "OPUS") ### 2. generating OPUS score
		{
			#run OPUS:
			$OPUS_starttime = time();
			if(-e "$dir_output/ALL_scores/feature_OPUS.$targetname")
			{
			  print "2. $dir_output/ALL_scores/feature_OPUS.$targetname already generated! Pass\n\n";
			  `cp $dir_output/ALL_scores/feature_OPUS.$targetname  $ren_OPUS`;
			}else{
			
			   $res = "$LOG_output/OPUS.is_running";
			   $cmd = "perl $H_script/OPUS_PSP.pl $H_script/CASP11_cal_not_norm_OPUS_score.pl $H_script/CASP11_norm_OPUS_score.pl $H_tool/OPUS/OPUS_PSP $models_folder $fasta_seq $ren_OPUS $res";
			   
			   $OUT = new FileHandle ">$res";
			   print $OUT "2. generating OPUS score\n   $cmd \n\n";
			   print  "2. generating OPUS score\n   $cmd \n\n";
			   $OUT->close();
			   $ren_return_val=system("$cmd &>> $res");
				if ($ren_return_val)
				{
					$OPUS_finishtime = time();
					$OPUS_diff_hrs = ($OPUS_finishtime - $OPUS_starttime)/3600;
					print "2. OPUS modeling finished within $OPUS_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/OPUS.is_running $LOG_output/OPUS.is_finished");
					open(TMP,">>$LOG_output/OPUS.is_finished");
					print TMP "ERROR! OPUS execution <$cmd> failed!\n";
					print TMP "OPUS modeling finished within $OPUS_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! OPUS execution failed!";
					exit 0;
				}
			   if(-e $ren_OPUS)
			   {
					print "!!Successfully generated $ren_OPUS\n\n";
					system("cp $ren_OPUS $ALL_14_scores");
					system("cp $ren_OPUS $ALL_scores");
			   }else{
					print "!!Failed to generate $ren_OPUS\n\n";
			   }
			}

			
			#ToDo: Check if OPUS ran successfully			
			$OPUS_finishtime = time();
			$OPUS_diff_hrs = ($OPUS_finishtime - $OPUS_starttime)/3600;
			print "2. OPUS modeling finished within $OPUS_diff_hrs hrs!\n\n";
			
			if(-e "$LOG_output/OPUS.is_running")
			{
				system("mv $LOG_output/OPUS.is_running $LOG_output/OPUS.is_finished");
			}
			
			open(TMP,">>$LOG_output/OPUS.is_finished");
			print TMP "OPUS modeling finished within $OPUS_diff_hrs hrs!\n\n";
			close TMP;		
			exit 0;
		}elsif ($tool eq "local_global")### 3. generating local and global score
		{
			#run local_global:
			$local_global_starttime = time();

			my($f_ss_sim)=$TMP_output."/"."local_global_features/Global_features/1_feature_ss_sim.".$targetname;                   # secondary structure similarity
			my($f_ss_pen)=$TMP_output."/"."local_global_features/Global_features/2_feature_ss_penalty.".$targetname;               # secondary structure penalty
			my($f_eucli)=$TMP_output."/"."local_global_features/Global_features/3_feature_euclidean.".$targetname;                 # euclidean pairwise distance
			my($f_surf)=$TMP_output."/"."local_global_features/Global_features/4_feature_surface.".$targetname;                    # surface
			my($f_w_surf)=$TMP_output."/"."local_global_features/Global_features/5_feature_weighted.".$targetname;                 # weighted surface
			my($f_t_surf)=$TMP_output."/"."local_global_features/Global_features/6_feature_total_surf.".$targetname;               # total surface
			my($f_solv)=$TMP_output."/"."local_global_features/Global_features/7_feature_solvent.".$targetname;                    # solvent accessibility score


			if(-e "$dir_output/ALL_scores/feature_ss_sim.$targetname" and -e "$dir_output/ALL_scores/feature_ss_penalty.$targetname" and -e "$dir_output/ALL_scores/feature_euclidean.$targetname" and -e "$dir_output/ALL_scores/feature_surface.$targetname" and -e "$dir_output/ALL_scores/feature_weighted.$targetname" and -e "$dir_output/ALL_scores/feature_total_surf.$targetname" and -e "$dir_output/ALL_scores/feature_solvent.$targetname")
			{
			  print "3. Local quality scores already generated! Pass\n\n";
			  `mkdir -p $TMP_output/local_global_features/Global_features`;
			  `cp $dir_output/ALL_scores/feature_ss_sim.$targetname  $f_ss_sim`;
			  `cp $dir_output/ALL_scores/feature_ss_penalty.$targetname  $f_ss_pen`;
			  `cp $dir_output/ALL_scores/feature_euclidean.$targetname  $f_eucli`;
			  `cp $dir_output/ALL_scores/feature_surface.$targetname  $f_surf`;
			  `cp $dir_output/ALL_scores/feature_weighted.$targetname  $f_w_surf`;
			  `cp $dir_output/ALL_scores/feature_total_surf.$targetname  $f_t_surf`;
			  `cp $dir_output/ALL_scores/feature_solvent.$targetname  $f_solv`;

			}else{
			   $res = "$LOG_output/local_global_feature_generation.is_running";
			   $cmd = "perl ".$H_script."/CASP11_generating_local_and_global_features.pl $models_local_global $fasta_seq $H_script/LCS $H_script/dsspcmbi $H_script/dssp2dataset.pl $H_tool/spine_X/spX.pl $H_tool/sspro4/bin/predict_acc.sh $ren_features $res $targetname";
			   
			   $OUT = new FileHandle ">$res";
			   print $OUT "3. generating local and global score\n   $cmd \n\n";
			   print  "3. generating local and global score\n   $cmd \n\n";
			   $OUT->close();
			   $ren_return_val=system("$cmd &>> $res");
				if ($ren_return_val)
				{
					$local_global_finishtime = time();
					$local_global_diff_hrs = ($local_global_finishtime - $local_global_starttime)/3600;
					print "3. local_global modeling finished within $local_global_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/local_global_feature_generation.is_running $LOG_output/local_global_feature_generation.is_finished");
					open(TMP,">>$LOG_output/local_global_feature_generation.is_finished");
					print TMP "ERROR! local_global execution <$cmd> failed!\n";
					print TMP "local_global modeling finished within $local_global_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! local_global execution failed!";
					exit 0;
				}
			   if(-e $f_ss_sim)
			   {
					print "!!Successfully generated $f_ss_sim\n\n";
					 system("cp $f_ss_sim $ALL_scores/feature_ss_sim.$targetname");
					 system("cp $f_ss_pen $ALL_scores/feature_ss_penalty.$targetname");
					 system("cp $f_eucli $ALL_scores/feature_euclidean.$targetname");
					 system("cp $f_surf $ALL_scores/feature_surface.$targetname");
					 system("cp $f_w_surf $ALL_scores/feature_weighted.$targetname");
					 system("cp $f_t_surf $ALL_scores/feature_total_surf.$targetname");
					 system("cp $f_solv $ALL_scores/feature_solvent.$targetname");
			   }else{
					print "!!Failed to generate $f_ss_sim\n\n";
			   }
			}

			
			#ToDo: Check if local_global ran successfully			
			$local_global_finishtime = time();
			$local_global_diff_hrs = ($local_global_finishtime - $local_global_starttime)/3600;
			print "3. local_global modeling finished within $local_global_diff_hrs hrs!\n\n";
			if(-e "$LOG_output/local_global_feature_generation.is_running")
			{
				system("mv $LOG_output/local_global_feature_generation.is_running $LOG_output/local_global_feature_generation.is_finished");
			}
			
			open(TMP,">>$LOG_output/local_global_feature_generation.is_finished");
			print TMP "local_global modeling finished within $local_global_diff_hrs hrs!\n\n";
			close TMP;		
			exit 0;
		}elsif ($tool eq "RF_SRS") ### 4. generating RF_SRS score
		{
			#run RF_SRS:
			$RF_SRS_starttime = time();
			if(-e "$dir_output/ALL_scores/feature_RF_SRS.$targetname")
			{
			  print "4. $dir_output/ALL_scores/feature_RF_SRS.$targetname already generated! Pass\n\n";
			  `cp $dir_output/ALL_scores/feature_RF_SRS.$targetname  $ren_RF_SRS`;
			}else{
			
			   $res = "$LOG_output/RF_CB_SRS_OD.is_running";
			   #(original is incorrect)$cmd = "perl $H_script/RF_SRS.pl $H_script/CASP11_cal_not_norm_RF_SRS_score.pl $H_script/CASP11_norm_RF_SRS_score.pl $H_tool/Energy_function_RF_SRS/calc_energy $H_tool/Energy_function_RF_SRS/RF_CB_SRS_OD $dir_models $targetname $ren_RF_SRS $res1> /dev/null 2>&1 ";
			   $cmd = "perl $H_script/RF_SRS.pl $H_script/CASP11_cal_not_norm_RF_SRS_score.pl $H_script/CASP11_norm_RF_SRS_score.pl $H_tool/Energy_function_RF_SRS/calc_energy $H_tool/Energy_function_RF_SRS/RF_CB_SRS_OD $dir_models $fasta_seq $ren_RF_SRS $res ";
			   
			   $OUT = new FileHandle ">$res";
			   print $OUT "4. generating RF_SRS score\n   $cmd \n\n";
			   print  "4. generating RF_SRS score\n   $cmd \n\n";
			   $OUT->close();
			   $ren_return_val=system("$cmd &>> $res");
				if ($ren_return_val)
				{
					$RF_SRS_finishtime = time();
					$RF_SRS_diff_hrs = ($RF_SRS_finishtime - $RF_SRS_starttime)/3600;
					print "4. RF_SRS modeling finished within $RF_SRS_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/RF_CB_SRS_OD.is_running $LOG_output/RF_CB_SRS_OD.is_finished");
					open(TMP,">>$LOG_output/RF_CB_SRS_OD.is_finished");
					print TMP "ERROR! RF_SRS execution <$cmd> failed!\n";
					print TMP "RF_SRS modeling finished within $RF_SRS_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! RF_SRS execution failed!";
					exit 0;
				}
			   if(-e $ren_RF_SRS)
			   {
					print "!!Successfully generated $ren_RF_SRS\n\n";
					system("cp $ren_RF_SRS $ALL_14_scores");
					system("cp $ren_RF_SRS $ALL_scores");
			   }else{
					print "!!Failed to generate $ren_RF_SRS\n\n";
			   }
			}

			
			#ToDo: Check if RF_SRS ran successfully			
			$RF_SRS_finishtime = time();
			$RF_SRS_diff_hrs = ($RF_SRS_finishtime - $RF_SRS_starttime)/3600;
			print "4. RF_SRS modeling finished within $RF_SRS_diff_hrs hrs!\n\n";
			if(-e "$LOG_output/RF_CB_SRS_OD.is_running")
			{
				system("mv $LOG_output/RF_CB_SRS_OD.is_running $LOG_output/RF_CB_SRS_OD.is_finished");
			}
			
			open(TMP,">>$LOG_output/RF_CB_SRS_OD.is_finished");
			print TMP "RF_SRS modeling finished within $RF_SRS_diff_hrs hrs!\n\n";
			close TMP;		
			exit 0;
		}elsif ($tool eq "RWplus") ### 5. generating RWplus score
		{
			#run RWplus:
			$RWplus_starttime = time();
			if(-e "$dir_output/ALL_scores/feature_RWplus.$targetname")
			{
			  print "5. $dir_output/ALL_scores/feature_RWplus.$targetname already generated! Pass\n\n";
			  `cp $dir_output/ALL_scores/feature_RWplus.$targetname  $ren_RWplus`;
			}else{
			   $res = "$LOG_output/RWplus.is_running";
			   $cmd = "perl $H_script/RWplus.pl $H_script/CASP11_cal_not_norm_RWplus_score.pl $H_script/CASP11_norm_RWplus_score.pl $H_tool/RWplus $dir_models $fasta_seq $ren_RWplus $res";
			   
			   $OUT = new FileHandle ">$res";
			   print $OUT "5. generating RWplus score\n   $cmd \n\n";
			   print  "5. generating RWplus score\n   $cmd \n\n";
			   $OUT->close();
			   $ren_return_val=system("$cmd &>> $res");
				if ($ren_return_val)
				{
					$RWplus_finishtime = time();
					$RWplus_diff_hrs = ($RWplus_finishtime - $RWplus_starttime)/3600;
					print "5. RWplus modeling finished within $RWplus_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/RWplus.is_running $LOG_output/RWplus.is_finished");
					open(TMP,">>$LOG_output/RWplus.is_finished");
					print TMP "ERROR! RWplus execution <$cmd> failed!\n";
					print TMP "RWplus modeling finished within $RWplus_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! RWplus execution failed!";
					exit 0;
				}
			   if(-e $ren_RWplus)
			   {
					print "!!Successfully generated $ren_RWplus\n\n";
					system("cp $ren_RWplus $ALL_14_scores");
					system("cp $ren_RWplus $ALL_scores");
			   }else{
					print "!!Failed to generate $ren_RWplus\n\n";
			   }
			}

			
			#ToDo: Check if RWplus ran successfully			
			$RWplus_finishtime = time();
			$RWplus_diff_hrs = ($RWplus_finishtime - $RWplus_starttime)/3600;
			print "5. RWplus modeling finished within $RWplus_diff_hrs hrs!\n\n";
			if(-e "$LOG_output/RWplus.is_running")
			{
				system("mv $LOG_output/RWplus.is_running $LOG_output/RWplus.is_finished");
			}
			
			open(TMP,">>$LOG_output/RWplus.is_finished");
			print TMP "RWplus modeling finished within $RWplus_diff_hrs hrs!\n\n";
			close TMP;		
			exit 0;
		}elsif ($tool eq "dope") ### 6. generating dope score
		{
			#run dope:
			$dope_starttime = time();
			if(-e "$dir_output/ALL_scores/feature_dope.$targetname")
			{
			  print "6. $dir_output/ALL_scores/feature_dope.$targetname already generated! Pass\n\n";
			  `cp $dir_output/ALL_scores/feature_dope.$targetname  $ren_dope`;
			}else{
			   $res = "$LOG_output/dope.is_running";
			   $cmd = "perl $H_script/dope.pl $H_script/CASP11_cal_not_norm_dope_score.pl $H_script/CASP11_norm_dope_score.pl $dir_models $fasta_seq $ren_dope $res";
			   
			   $OUT = new FileHandle ">$res";
			   print $OUT "6. generating dope score\n   $cmd \n\n";
			   print  "6. generating dope score\n   $cmd \n\n";
			   $OUT->close();
			   $ren_return_val=system("$cmd &>> $res");
				if ($ren_return_val)
				{
					$dope_finishtime = time();
					$dope_diff_hrs = ($dope_finishtime - $dope_starttime)/3600;
					print "6. dope modeling finished within $dope_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/dope.is_running $LOG_output/dope.is_finished");
					open(TMP,">>$LOG_output/dope.is_finished");
					print TMP "ERROR! dope execution <$cmd> failed!\n";
					print TMP "dope modeling finished within $dope_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! dope execution failed!";
					exit 0;
				}
			   if(-e $ren_dope)
			   {
					print "!!Successfully generated $ren_dope\n\n";
					system("cp $ren_dope $ALL_14_scores");
					system("cp $ren_dope $ALL_scores");
			   }else{
					print "!!Failed to generate $ren_dope\n\n";
			   }
			}

			
			#ToDo: Check if dope ran successfully			
			$dope_finishtime = time();
			$dope_diff_hrs = ($dope_finishtime - $dope_starttime)/3600;
			print "6. dope modeling finished within $dope_diff_hrs hrs!\n\n";
			if(-e "$LOG_output/dope.is_running")
			{
				system("mv $LOG_output/dope.is_running $LOG_output/dope.is_finished");
			}
			
			open(TMP,">>$LOG_output/dope.is_finished");
			print TMP "dope modeling finished within $dope_diff_hrs hrs!\n\n";
			close TMP;		
			exit 0;
		}elsif ($tool eq "modfoldclust2") ### 7. generating modfoldclust2 score
		{
			#run modfoldclust2:
			$modfoldclust2_starttime = time();
			
			if(-e "$dir_output/ALL_scores/modfoldclust2.$targetname")
			{
			  print "7. $dir_output/ALL_scores/modfoldclust2.$targetname already generated! Pass\n\n";
			  `cp $dir_output/ALL_scores/modfoldclust2.$targetname  $score_modfold`;
			}else{
			   $res = "$LOG_output/modfoldclust2.is_running";
			   $cmd = "perl $H_script/cal_modfoldclust2.pl $H_tool/ModFOLDclust2.jar $targetname $dir_models $fasta_seq $score_modfold";
			   $OUT = new FileHandle ">$res";
			   print $OUT "7. generating modfoldclust2 score\n   $cmd \n\n";
			   print  "7. generating modfoldclust2 score\n   $cmd \n\n";
			   $OUT->close();
			   $ren_return_val=system("$cmd &>> $res");
				if ($ren_return_val)
				{
					$modfoldclust2_finishtime = time();
					$modfoldclust2_diff_hrs = ($modfoldclust2_finishtime - $modfoldclust2_starttime)/3600;
					print "7. modfoldclust2 modeling finished within $modfoldclust2_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/modfoldclust2.is_running $LOG_output/modfoldclust2.is_finished");
					open(TMP,">>$LOG_output/modfoldclust2.is_finished");
					print TMP "ERROR! modfoldclust2 execution <$cmd> failed!\n";
					print TMP "modfoldclust2 modeling finished within $modfoldclust2_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! modfoldclust2 execution failed!";
					exit 0;
				}
			   if(-e $score_modfold)
			   {
					print "!!Successfully generated $score_modfold\n\n";
					system("cp $score_modfold $ALL_14_scores");
					system("cp $score_modfold $ALL_scores");
					
			   }else{
					print "!!Failed to generate $score_modfold\n\n";
			   }
			}

			
			#ToDo: Check if modfoldclust2 ran successfully			
			$modfoldclust2_finishtime = time();
			$modfoldclust2_diff_hrs = ($modfoldclust2_finishtime - $modfoldclust2_starttime)/3600;
			print "7. modfoldclust2 modeling finished within $modfoldclust2_diff_hrs hrs!\n\n";
			if(-e "$LOG_output/modfoldclust2.is_running")
			{
				system("mv $LOG_output/modfoldclust2.is_running $LOG_output/modfoldclust2.is_finished");
			}
			
			open(TMP,">>$LOG_output/modfoldclust2.is_finished");
			print TMP "modfoldclust2 modeling finished within $modfoldclust2_diff_hrs hrs!\n\n";
			close TMP;		
			exit 0;
		}elsif ($tool eq "pcons") ### 8. generating pcons score
		{
			#run pcons:
			$pcons_starttime = time();
			
			if(-e "$dir_output/ALL_scores/feature_pcons.$targetname")
			{
			  print "8. $dir_output/ALL_scores/feature_pcons.$targetname already generated! Pass\n\n";
			  `cp $dir_output/ALL_scores/feature_pcons.$targetname  $score_pcons`;
			}else{
			   $res = "$LOG_output/pcons.is_running";
			   $cmd = "perl $H_script/cal_pcons.pl $H_tool/Pcons/bin/pcons $dir_models $score_pcons";
			   $OUT = new FileHandle ">$res";
			   print $OUT "8. generating pcons score\n   $cmd \n\n";
			   print  "8. generating pcons score\n   $cmd \n\n";
			   $OUT->close();
			   $ren_return_val=system("$cmd &>> $res");
				if ($ren_return_val)
				{
					$pcons_finishtime = time();
					$pcons_diff_hrs = ($pcons_finishtime - $pcons_starttime)/3600;
					print "8. pcons modeling finished within $pcons_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/pcons.is_running $LOG_output/pcons.is_finished");
					open(TMP,">>$LOG_output/pcons.is_finished");
					print TMP "ERROR! pcons execution <$cmd> failed!\n";
					print TMP "pcons modeling finished within $pcons_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! pcons execution failed!";
					exit 0;
				}
			   if(-e $score_pcons)
			   {
					print "!!Successfully generated $score_pcons\n\n";
					system("cp $score_pcons $ALL_14_scores");
					system("cp $score_pcons $ALL_scores");
					
			   }else{
					print "!!Failed to generate $score_pcons\n\n";
			   }
			}

			
			#ToDo: Check if pcons ran successfully			
			$pcons_finishtime = time();
			$pcons_diff_hrs = ($pcons_finishtime - $pcons_starttime)/3600;
			print "8. pcons modeling finished within $pcons_diff_hrs hrs!\n\n";
			if(-e "$LOG_output/modfoldclust2.is_running")
			{
				system("mv $LOG_output/pcons.is_running $LOG_output/pcons.is_finished");
			}
			
			open(TMP,">>$LOG_output/pcons.is_finished");
			print TMP "pcons modeling finished within $pcons_diff_hrs hrs!\n\n";
			close TMP;		
			exit 0;
		}elsif ($tool eq "pairwise") ### 9. generating pairwise score
		{
			$filtered_model_dir = "$task_dir/filtered-$name";
			system("mkdir $filtered_model_dir");
			$pairwise_starttime = time();
			if(-e "$dir_output/ALL_scores/feature_pairwiseScore.$targetname")
			{
			  print "9. $dir_output/ALL_scores/feature_pairwiseScore.$targetname already generated! Pass\n\n";
			  `cp $dir_output/ALL_scores/feature_pairwiseScore.$targetname  $score_pairwise`;
			}else{
			
				#run pairwise:
				$task_dir = $TMP_output;             # just use the current tmp folder as the task folder, should have no conflict

				
				open(MLIST, ">$task_dir/$name.mlist");
				opendir(MDIR, $dir_models); 
				my @models = readdir(MDIR);
				closedir(MDIR);
				foreach my $model (@models){
				 if($model eq '.' || $model eq '..'){
							next;
				 }
				 print MLIST "$dir_models/$model\n";
				}
				close(MLIST);


				###########FILTER MODELS#########
				#print "\n###########FILTER MODELS#########\n\n";
				#print("$H_script/filter_model.pl $name.mlist $filtered_model_dir\n\n");
				system("$H_script/filter_model.pl $name.mlist $filtered_model_dir > /dev/null 2>&1");

				
			   $res = "$LOG_output/pairwise.is_running";
			   $cmd = "$H_script/filter_model_same_group_v2.pl $name.mlist $name.nlist $H_tool/TMscore_32";
			   $OUT = new FileHandle ">$res";
			   print $OUT "9. generating pairwise score\n   $cmd \n\n";
			   print  "9. generating pairwise score\n   $cmd \n\n";
			   $OUT->close();
			   $ren_return_val=system("$cmd &>> $res");
				if ($ren_return_val)
				{
					$pairwise_finishtime = time();
					$pairwise_diff_hrs = ($pairwise_finishtime - $pairwise_starttime)/3600;
					print "9. pairwise modeling finished within $pairwise_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/pairwise.is_running $LOG_output/pairwise.is_finished");
					open(TMP,">>$LOG_output/pairwise.is_finished");
					print TMP "ERROR! pairwise execution <$cmd> failed!\n";
					print TMP "pairwise modeling finished within $pairwise_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! pairwise execution failed!";
					exit 0;
				}
			   my($ren_filter) = $task_dir."/"."ren_filtered_model/";     # save the filtered model 
			   mkdir $ren_filter;
			   open(REN,"$name.nlist");
			   my(@ren_models) = <REN>;
			   close(REN);
			   foreach my $ren_each (@ren_models)
			   {
				  chomp($ren_each);
				  system("cp $ren_each $ren_filter");
			   }
			   
			   $cmd = "$H_script/q_score $name.nlist $fasta_seq $H_tool/TMscore_32 $pairwise_out $name";
				$ren_return_val=system("$cmd &>> $res");
				if ($ren_return_val)
				{
					$pairwise_finishtime = time();
					$pairwise_diff_hrs = ($pairwise_finishtime - $pairwise_starttime)/3600;
					print "pairwise modeling finished within $pairwise_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/pairwise.is_running $LOG_output/pairwise.is_finished");
					open(TMP,">>$LOG_output/pairwise.is_finished");
					print TMP "ERROR! pairwise execution <$cmd> failed!\n";
					print TMP "pairwise modeling finished within $pairwise_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! pairwise execution failed!";
					exit 0;
				}
			   if(-e $score_pairwise)
			   {
					print "!!Successfully generated $score_pairwise\n\n";
					system("cp $score_pairwise $ALL_14_scores/feature_pairwiseScore.$targetname");
					system("cp $score_pairwise $ALL_scores/feature_pairwiseScore.$targetname");
					
			   }else{
					print "!!Failed to generate $score_pairwise\n\n";
			   }
			}

			`rm -rf $filtered_model_dir`;
			
			#ToDo: Check if pairwise ran successfully			
			$pairwise_finishtime = time();
			$pairwise_diff_hrs = ($pairwise_finishtime - $pairwise_starttime)/3600;
			print "9. pairwise modeling finished within $pairwise_diff_hrs hrs!\n\n";
			if(-e "$LOG_output/pairwise.is_running")
			{
				system("mv $LOG_output/pairwise.is_running $LOG_output/pairwise.is_finished");
			}
			
			open(TMP,">>$LOG_output/pairwise.is_finished");
			print TMP "pairwise modeling finished within $pairwise_diff_hrs hrs!\n\n";
			close TMP;	
			exit 0;
		}elsif ($tool eq "voronota") ### 14. generating voronota score
		{
			#run voronota:
			$voronota_starttime = time();
			
			if(-e "$dir_output/ALL_scores/feature_voronota.$targetname")
			{
			  print "14. $dir_output/ALL_scores/feature_voronota.$targetname already generated! Pass\n\n";
			  `cp $dir_output/ALL_scores/feature_voronota.$targetname  $ren_voronota`;
			}else{
			   $res = "$LOG_output/voronota.is_running";
			   $cmd = "perl $H_tool/voronota_1_18_1877/run_voronota_batch.pl $models_folder $ren_voronota";
			   $OUT = new FileHandle ">$res";
			   print $OUT "14. generating voronota score\n   $cmd \n\n";
			   print  "14. generating voronota score\n   $cmd \n\n";
			   $OUT->close();
			   $ren_return_val=system("$cmd &>> $res");
				if ($ren_return_val)
				{
					$voronota_finishtime = time();
					$voronota_diff_hrs = ($voronota_finishtime - $voronota_starttime)/3600;
					print "14. voronota modeling finished within $voronota_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/voronota.is_running $LOG_output/voronota.is_finished");
					open(TMP,">>$LOG_output/voronota.is_finished");
					print TMP "ERROR! voronota execution <$cmd> failed!\n";
					print TMP "voronota modeling finished within $voronota_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! voronota execution failed!";
					exit 0;
				}
			   if(-e $ren_voronota)
			   {
					print "!!Successfully generated $ren_voronota\n\n";
					system("cp $ren_voronota $ALL_14_scores");
					system("cp $ren_voronota $ALL_scores");
					
			   }else{
					print "!!Failed to generate $ren_voronota\n\n";
			   }
			}

			
			#ToDo: Check if voronota ran successfully			
			$voronota_finishtime = time();
			$voronota_diff_hrs = ($voronota_finishtime - $voronota_starttime)/3600;
			print "14. voronota modeling finished within $voronota_diff_hrs hrs!\n\n";
			if(-e "$LOG_output/voronota.is_running")
			{
				system("mv $LOG_output/voronota.is_running $LOG_output/voronota.is_finished");
			}
			
			open(TMP,">>$LOG_output/voronota.is_finished");
			print TMP "voronota modeling finished within $voronota_diff_hrs hrs!\n\n";
			close TMP;		
			exit 0;
		}elsif ($tool eq "DeepQA") ### 15. generating DeepQA score
		{
			#run DeepQA:
			$DeepQA_starttime = time();
			$ren_DeepQA_features=$TMP_output."/DeepQA";
			if(!(-d $ren_DeepQA_features))
			{
				`mkdir $ren_DeepQA_features`;
			}
			
			if(-e "$dir_output/ALL_scores/feature_DeepQA.$targetname")
			{
			  print "15. $dir_output/ALL_scores/feature_DeepQA.$targetname already generated! Pass\n\n";
			  `cp $dir_output/ALL_scores/feature_DeepQA.$targetname  $ren_DeepQA`;
			}else{
			   $res = "$LOG_output/DeepQA.is_running";
			   $cmd = "$H_tool/DeepQA/bin/DeepQA.sh  $fasta_seq    $models_DeepQA $ren_DeepQA_features";
			   $OUT = new FileHandle ">$res";
			   print $OUT "15. generating DeepQA score\n   $cmd \n\n";
			   print  "15. generating DeepQA score\n   $cmd \n\n";
			   $OUT->close();
			   $ren_return_val=system("$cmd &>> $res");
				if ($ren_return_val)
				{
					$DeepQA_finishtime = time();
					$DeepQA_diff_hrs = ($DeepQA_finishtime - $DeepQA_starttime)/3600;
					print "15. DeepQA modeling finished within $DeepQA_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/DeepQA.is_running $LOG_output/DeepQA.is_finished");
					open(TMP,">>$LOG_output/DeepQA.is_finished");
					print TMP "ERROR! DeepQA execution <$cmd> failed!\n";
					print TMP "DeepQA modeling finished within $DeepQA_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! DeepQA execution failed!";
					exit 0;
				}
				
				my($score_deepqa) = $ren_DeepQA_features."/"."DeepQA_predictions.txt";
			   if(-e $score_deepqa)
			   {
				`cp $score_deepqa $ren_DeepQA`;
			   }
   
			   if(-e $ren_DeepQA)
			   {
					print "!!Successfully generated $ren_DeepQA\n\n";
					system("cp $ren_DeepQA $ALL_14_scores");
					system("cp $ren_DeepQA $ALL_scores");
					
			   }else{
					print "!!Failed to generate $ren_DeepQA\n\n";
			   }
			}

			
			#ToDo: Check if DeepQA ran successfully			
			$DeepQA_finishtime = time();
			$DeepQA_diff_hrs = ($DeepQA_finishtime - $DeepQA_starttime)/3600;
			print "15. DeepQA modeling finished within $DeepQA_diff_hrs hrs!\n\n";
			if(-e "$LOG_output/DeepQA.is_running")
			{
				system("mv $LOG_output/DeepQA.is_running $LOG_output/DeepQA.is_finished");
			}
			
			open(TMP,">>$LOG_output/DeepQA.is_finished");
			print TMP "DeepQA modeling finished within $DeepQA_diff_hrs hrs!\n\n";
			close TMP;		
			exit 0;
		}elsif ($tool eq "Proq3") ### 16. generating Proq3 score
		{
			#run Proq3:
			$Proq3_starttime = time();
			$ren_Proq3_features=$TMP_output."/Proq3";
			if(!(-d $ren_Proq3_features))
			{
				`mkdir $ren_Proq3_features`;
			}
			

			if(-e "$dir_output/ALL_scores/feature_proq2.$targetname" and -e "$dir_output/ALL_scores/feature_proq3.$targetname" and -e "$dir_output/ALL_scores/feature_proq3_lowres.$targetname" and -e "$dir_output/ALL_scores/feature_proq3_highres.$targetname")
			{
			  print "16. $dir_output/ALL_scores/feature_proq2.$targetname already generated! Pass\n";
			  print "16. $dir_output/ALL_scores/feature_proq3.$targetname already generated! Pass\n";
			  print "16. $dir_output/ALL_scores/feature_proq3_lowres.$targetname already generated! Pass\n";
			  print "16. $dir_output/ALL_scores/feature_proq3_highres.$targetname already generated! Pass\n\n";
			  `cp $dir_output/ALL_scores/feature_proq2.$targetname  $ren_Proq2_global`;
			  `cp $dir_output/ALL_scores/feature_proq3.$targetname  $ren_Proq3_global`;
			  `cp $dir_output/ALL_scores/feature_proq3_lowres.$targetname  $ren_Proq3_lowres`;
			  `cp $dir_output/ALL_scores/feature_proq3_highres.$targetname  $ren_Proq3_highres`;
			}else{
			   $res = "$LOG_output/Proq3.is_running";
			   my($proq3_seq)=$ren_Proq3_features."/".$name.".fasta";
				system("cp $fasta_seq $proq3_seq");
				#print "cp $fasta_seq $proq3_seq\n\n";
			   $cmd = "perl $H_script/CASP13_run_proq3_for_rosetta_energy_parallel.pl $models_proq3   $H_tool/proq3/run_proq3.sh  $proq3_seq $ren_Proq3_features"; 
			   $OUT = new FileHandle ">$res";
			   print $OUT "16. generating Proq3 score\n   $cmd \n\n";
			   print  "16. generating Proq3 score\n   $cmd \n\n";
			   $OUT->close();
			   $ren_return_val=system("$cmd &>> $res");
				if ($ren_return_val)
				{
					$Proq3_finishtime = time();
					$Proq3_diff_hrs = ($Proq3_finishtime - $Proq3_starttime)/3600;
					print "16. Proq3 modeling finished within $Proq3_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/Proq3.is_running $LOG_output/Proq3.is_finished");
					open(TMP,">>$LOG_output/Proq3.is_finished");
					print TMP "ERROR! Proq3 execution <$cmd> failed!\n";
					print TMP "Proq3 modeling finished within $Proq3_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! Proq3 execution failed!";
					exit 0;
				}
				
				my($score_Proq2_global) = $ren_Proq3_features."/feature_proq2_global.txt";
			   if(-e $score_Proq2_global)
			   {
				`cp $score_Proq2_global $ren_Proq2_global`;
			   }
				my($score_Proq3_global) = $ren_Proq3_features."/feature_proq3_global.txt";
			   if(-e $score_Proq3_global)
			   {
				`cp $score_Proq3_global $ren_Proq3_global`;
			   }
				my($score_Proq3_lowres) = $ren_Proq3_features."/feature_proq3_ProQRosCenD_global.txt";
			   if(-e $score_Proq3_lowres)
			   {
				`cp $score_Proq3_lowres $ren_Proq3_lowres`;
			   }
				my($score_Proq3_highres) = $ren_Proq3_features."/feature_proq3_ProQRosFAD_global.txt";
			   if(-e $score_Proq3_highres)
			   {
				`cp $score_Proq3_highres $ren_Proq3_highres`;
			   }
			   
			   
			   if(-e $ren_Proq2_global)
			   {
					print "!!Successfully generated $ren_Proq2_global\n\n";
					 system("cp $ren_Proq2_global $ALL_scores");
					 system("cp $ren_Proq3_global $ALL_scores");
					 system("cp $ren_Proq3_lowres $ALL_scores");
					 system("cp $ren_Proq3_highres $ALL_scores");
					 
					 system("cp $ren_Proq2_global $ALL_14_scores");
					 system("cp $ren_Proq3_global $ALL_14_scores");
					 system("cp $ren_Proq3_lowres $ALL_14_scores");
					 system("cp $ren_Proq3_highres $ALL_14_scores");
					
			   }else{
					print "!!Failed to generate $ren_Proq2_global\n\n";
			   }
			}

			
			#ToDo: Check if Proq3 ran successfully			
			$Proq3_finishtime = time();
			$Proq3_diff_hrs = ($Proq3_finishtime - $Proq3_starttime)/3600;
			print "16. Proq3 modeling finished within $Proq3_diff_hrs hrs!\n\n";
			if(-e "$LOG_output/Proq3.is_running")
			{
				system("mv $LOG_output/Proq3.is_running $LOG_output/Proq3.is_finished");
			}
			
			open(TMP,">>$LOG_output/Proq3.is_finished");
			print TMP "Proq3 modeling finished within $Proq3_diff_hrs hrs!\n\n";
			close TMP;		
			exit 0;
		}elsif ($tool eq "dncon2") ### 17. generating dncon2 score
		{
			#run dncon2:
			$dncon2_starttime = time();
			my($ren_dncon2_features)=$TMP_output."/dncon2";
			if(!(-d $ren_dncon2_features))
			{
				`mkdir $ren_dncon2_features`;
			}


			if(-e "$dir_output/ALL_scores/feature_dncon2_short-range.$targetname" and -e "$dir_output/ALL_scores/feature_dncon2_medium-range.$targetname" and -e "$dir_output/ALL_scores/feature_dncon2_long-range.$targetname")
			{
				print "19. $dir_output/ALL_scores/feature_dncon2_short-range.$targetname already generated! Pass\n";
				print "19. $dir_output/ALL_scores/feature_dncon2_medium-range.$targetname already generated! Pass\n";
				print "19. $dir_output/ALL_scores/feature_dncon2_long-range.$targetname already generated! Pass\n";
				`cp $dir_output/ALL_scores/feature_dncon2_short-range.$targetname  $ren_dncon2_short`;
				`cp $dir_output/ALL_scores/feature_dncon2_medium-range.$targetname  $ren_dncon2_medium`;
				`cp $dir_output/ALL_scores/feature_dncon2_long-range.$targetname  $ren_dncon2_long`;
			}else{
			   $res = "$LOG_output/dncon2.is_running";
				#print "cp $fasta_seq $dncon2_seq\n\n";
				
				print "####### 1. Predicting contact\n\n";

				if(-e "$ren_dncon2_features/$targetname.dncon2.rr")
				{
					print "$ren_dncon2_features/$targetname.dncon2.rr generated!\n\n";
				}else{
				   
				   $cmd = "$H_tool/DNCON2/dncon2-v1.0.sh  $fasta_seq  $ren_dncon2_features";
				   $OUT = new FileHandle ">$res";
				   print $OUT "19. generating dncon2 score\n   $cmd \n\n";
				   print  "19. generating dncon2 score\n   $cmd \n\n";
				   $OUT->close();
				   $ren_return_val=system("$cmd &>> $res");
					if ($ren_return_val)
					{
						$dncon2_finishtime = time();
						$dncon2_diff_hrs = ($dncon2_finishtime - $dncon2_starttime)/3600;
						print "19. dncon2 modeling finished within $dncon2_diff_hrs hrs!\n\n";
						
						system("mv $LOG_output/dncon2.is_running $LOG_output/dncon2.is_finished");
						open(TMP,">>$LOG_output/dncon2.is_finished");
						print TMP "ERROR! dncon2 execution <$cmd> failed!\n";
						print TMP "dncon2 modeling finished within $dncon2_diff_hrs hrs!\n\n";
						close TMP;				
						print "ERROR! dncon2 execution failed!";
						exit 0;
					}
					print "$ren_dncon2_features/$targetname.dncon2.rr generated!\n\n"; 
				}
				
				my($score_dncon2_short) = $ren_dncon2_features."/${targetname}_contact_energy/".$targetname.'.short-range';
				my($score_dncon2_medium) = $ren_dncon2_features."/${targetname}_contact_energy/".$targetname.'.medium-range';
				my($score_dncon2_long) = $ren_dncon2_features."/${targetname}_contact_energy/".$targetname.'.long-range';
				
				if(-e $score_dncon2_short and -e $score_dncon2_medium and -e $score_dncon2_long)
				{
					print "$score_dncon2_short generated!\n\n";
					print "$score_dncon2_medium generated!\n\n";
					print "$score_dncon2_long generated!\n\n";
				}else{
					$cmd = "perl $H_script/CASP13_run_contact_energy.pl $ren_dncon2_features/$targetname.dncon2.rr  $models_dncon2  $targetname $ren_dncon2_features";
					$OUT = new FileHandle ">$res";
					print $OUT "19. generating contact energy score\n   $cmd \n\n";
					print  "19. generating contact energy score\n   $cmd \n\n";
					$OUT->close();
					$ren_return_val=system("$cmd &>> $res");
					if ($ren_return_val)
					{
							$dncon2_finishtime = time();
							$dncon2_diff_hrs = ($dncon2_finishtime - $dncon2_starttime)/3600;
						system("mv $LOG_output/dncon2.is_running $LOG_output/dncon2.is_finished");
						open(TMP,">>$LOG_output/dncon2.is_finished");
						print TMP "ERROR! dncon2 execution <$cmd> failed!\n";
						print TMP "dncon2 modeling finished within $dncon2_diff_hrs hrs!\n\n";
						close TMP;				
						print "ERROR! dncon2 execution failed!";
						exit 0;
					}
				}
				
				
			   if(-e $score_dncon2_short)
			   {
				  `cp $score_dncon2_short $ren_dncon2_short`;
				  system("cp $ren_dncon2_short $ALL_scores");
				  system("cp $ren_dncon2_short $ALL_14_scores");
			   }
			   
				
			   if(-e $score_dncon2_medium)
			   {
				  `cp $score_dncon2_medium $ren_dncon2_medium`;
				  system("cp $ren_dncon2_medium $ALL_scores");
				  system("cp $ren_dncon2_medium $ALL_14_scores");
			   }
			   
				
			   if(-e $score_dncon2_long)
			   {
				  `cp $score_dncon2_long $ren_dncon2_long`;
				  system("cp $ren_dncon2_long $ALL_scores");
				  system("cp $ren_dncon2_long $ALL_14_scores");
			   }
			     
			   
			   if(-e $ren_dncon2_long and -e $ren_dncon2_medium and -e $ren_dncon2_short)
			   {
					print "!!Successfully generated $ren_dncon2_short, $ren_dncon2_medium, $ren_dncon2_short\n\n";
					
			   }else{
					print "!!Failed to generate $ren_Proq2D_global\n\n";
			   }
			}

			
			#ToDo: Check if dncon2 ran successfully			
			$dncon2_finishtime = time();
			$dncon2_diff_hrs = ($dncon2_finishtime - $dncon2_starttime)/3600;
			print "19. dncon2 modeling finished within $dncon2_diff_hrs hrs!\n\n";
			if(-e "$LOG_output/dncon2.is_running")
			{
				system("mv $LOG_output/dncon2.is_running $LOG_output/dncon2.is_finished");
			}
			
			open(TMP,">>$LOG_output/dncon2.is_finished");
			print TMP "dncon2 modeling finished within $dncon2_diff_hrs hrs!\n\n";
			close TMP;		
			exit 0;
		}elsif ($tool eq "SBROD") ### 17. generating Proq3D score
		{
			#run Proq3D:
			$SBROD_starttime = time();

			if(-e "$dir_output/ALL_scores/feature_SBROD.$targetname")
			{
				print "18. $dir_output/ALL_scores/feature_SBROD.$targetname already generated! Pass\n";
				`cp $dir_output/ALL_scores/feature_SBROD.$targetname  $ren_SBROD`;
				
			}else{
			   $res = "$LOG_output/SBROD.is_running";
			   chdir("$H_tool/SBROD");
			   $cmd = "./assess_protein $models_folder/* &> $ren_SBROD";
			   $OUT = new FileHandle ">$res";
			   print $OUT "18. generating SBROD score\n   $cmd \n\n";
			   print  "18. generating SBROD score\n   $cmd \n\n";
			   $OUT->close();
			   $ren_return_val=system("$cmd");
				if ($ren_return_val)
				{
					$SBROD_finishtime = time();
					$SBROD_diff_hrs = ($SBROD_finishtime - $SBROD_starttime)/3600;
					print "17. SBROD modeling finished within $SBROD_diff_hrs hrs!\n\n";
					
					system("mv $LOG_output/SBROD.is_running $LOG_output/SBROD.is_finished");
					open(TMP,">>$LOG_output/SBROD.is_finished");
					print TMP "ERROR! SBROD execution <$cmd> failed!\n";
					print TMP "SBROD modeling finished within $SBROD_diff_hrs hrs!\n\n";
					close TMP;				
					print "ERROR! SBROD execution failed!";
					exit 0;
				}
				
			   if(-e $ren_SBROD)
			   {
				`cp $ren_SBROD $dir_output/ALL_scores/feature_SBROD.$targetname`;
				`cp $ren_SBROD $dir_output/ALL_14_scores/feature_SBROD.$targetname`;
			   }else{
					print "!!Failed to generate $ren_SBROD\n\n";
			   }
			   
			   chdir($dir_output);
			}

			
			#ToDo: Check if SBROD ran successfully			
			$SBROD_finishtime = time();
			$SBROD_diff_hrs = ($SBROD_finishtime - $SBROD_starttime)/3600;
			print "18. SBROD modeling finished within $SBROD_diff_hrs hrs!\n\n";
			if(-e "$LOG_output/SBROD.is_running")
			{
				system("mv $LOG_output/SBROD.is_running $LOG_output/SBROD.is_finished");
			}
			
			open(TMP,">>$LOG_output/SBROD.is_finished");
			print TMP "SBROD modeling finished within $SBROD_diff_hrs hrs!\n\n";
			close TMP;		
			exit 0;
		}
	}else{
		$thread_ids[$i] = $kidpid;
		print "The process id of the thread $i is $thread_ids[$i].\n\n";
	}


}
###############################################################################
$OPUS_finish=0;
$local_global_finish=0;
$RF_SRS_finish=0;
$RWplus_finish=0;
$dope_finish=0;
$modfoldclust2_finish=0;
$pcons_finish=0;
$pairwise_finish=0;
$voronota_finish=0;
$DeepQA_finish=0;
$Proq3_finish=0;
$SBROD_finish=0;
$dncon2_finish=0;

$OPUS_manuallystop=0;
$local_global_manuallystop=0;
$RF_SRS_manuallystop=0;
$RWplus_manuallystop=0;
$dope_manuallystop=0;
$modfoldclust2_manuallystop=0;
$pcons_manuallystop=0;
$pairwise_manuallystop=0;
$voronota_manuallystop=0;
$DeepQA_manuallystop=0;
$Proq3_manuallystop=0;
$SBROD_manuallystop=0;
$dncon2_manuallystop=0;

#if ($i == @servers && $post_process == 0)
if ($i == $thread_num && $post_process == 0)
{
	print "The main process starts to wait for the base predictors to finish...\n";
	$post_process = 1;
	
	for ($k = 0; $k < @tools; $k++)
	{
		$tool = $tools[$k];
		if($tool eq 'OPUS')
		{
			$OPUS_finish=1;
		}
		if($tool eq 'local_global')
		{
			$local_global_finish = 1;
		}
		if($tool eq 'RF_SRS')
		{
			$RF_SRS_finish = 1;
		}
		if($tool eq 'RWplus')
		{
			$RWplus_finish = 1;
		}
		if($tool eq 'dope')
		{
			$dope_finish = 1;
		}
		if($tool eq 'modfoldclust2')
		{
			$modfoldclust2_finish = 1;
		}
		if($tool eq 'pcons')
		{
			$pcons_finish = 1;
		}
		if($tool eq 'pairwise')
		{
			$pairwise_finish = 1;
		}
		if($tool eq 'voronota')
		{
			$voronota_finish = 1;
		}
		if($tool eq 'DeepQA')
		{
			$DeepQA_finish = 1;
		}
		if($tool eq 'Proq3')
		{
			$Proq3_finish = 1;
		}
		if($tool eq 'SBROD')
		{
			$SBROD_finish = 1;
		}
		if($tool eq 'dncon2')
		{
			$dncon2_finish = 1;
		}
	}
	$checktime = time();
	
	while(1)
	{
		if($OPUS_finish)
		{
			$checkfile = "$dir_output/ALL_scores/feature_OPUS.$targetname";
			if(-e $checkfile or $OPUS_manuallystop == 1)
			{
				if(-e $checkfile)
				{
					$OPUS_finish = 0;
					next;
				}
				if($OPUS_manuallystop == 0)
				{
					print "OPUS modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "OPUS modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$OPUS_finish = 0;
					next;
				}else{
					print "OPUS modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "OPUS modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;
					$OPUS_finish = 0;
					next;				
				}
			}
				
		}

		if($local_global_finish)
		{
			$checkfile1 = "$dir_output/ALL_scores/feature_ss_sim.$targetname";
			$checkfile2 = "$dir_output/ALL_scores/feature_ss_penalty.$targetname";
			$checkfile3 = "$dir_output/ALL_scores/feature_euclidean.$targetname";
			$checkfile4 = "$dir_output/ALL_scores/feature_surface.$targetname";
			$checkfile5 = "$dir_output/ALL_scores/feature_weighted.$targetname";
			$checkfile6 = "$dir_output/ALL_scores/feature_total_surf.$targetname";
			$checkfile7 = "$dir_output/ALL_scores/feature_solvent.$targetname";
			
					 
					 
			if((-e $checkfile1 and -e $checkfile2 and -e $checkfile3 and -e $checkfile4 and -e $checkfile5 and -e $checkfile6 and -e $checkfile7 ) or $local_global_manuallystop == 1)
			{
				if(-e $checkfile1 and -e $checkfile2 and -e $checkfile3 and -e $checkfile4 and -e $checkfile5 and -e $checkfile6 and -e $checkfile7 )
				{
					$local_global_finish = 0;
					next;
				}
				if($local_global_manuallystop == 0)
				{
					print "local_global modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "local_global modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$local_global_finish = 0;
					next;
				}else{
					print "local_global modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "local_global modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;
					$local_global_finish = 0;
					next;				
				}
			}
				
		}

		if($RF_SRS_finish)
		{
			$checkfile = "$dir_output/ALL_scores/feature_RF_SRS.$targetname";
			if(-e $checkfile or $RF_SRS_manuallystop == 1)
			{
				if(-e $checkfile)
				{
					$RF_SRS_finish = 0;
					next;
				}
				if($RF_SRS_manuallystop == 0)
				{
					print "RF_SRS modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "RF_SRS modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$RF_SRS_finish = 0;
					next;
				}else{
					print "RF_SRS modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "RF_SRS modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;	
					$RF_SRS_finish = 0;
					next;			
				}
			}
				
		}
		
		if($RWplus_finish)
		{
			$checkfile = "$dir_output/ALL_scores/feature_RWplus.$targetname";
			if(-e $checkfile or $RWplus_manuallystop == 1)
			{
				if(-e $checkfile)
				{
					$RWplus_finish = 0;
					next;
				}
				if($RWplus_manuallystop == 0)
				{
					print "RWplus modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "RWplus modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$RWplus_finish = 0;
					next;
				}else{
					print "RWplus modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "RWplus modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;	
					$RWplus_finish = 0;
					next;			
				}
			}
				
		}
		
		if($dope_finish)
		{
			$checkfile = "$dir_output/ALL_scores/feature_dope.$targetname";
			if(-e $checkfile or $dope_manuallystop == 1)
			{
				if(-e $checkfile)
				{
					$dope_finish = 0;
					next;
				}
				if($dope_manuallystop == 0)
				{
					print "dope modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "dope modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$dope_finish = 0;
					next;
				}else{
					print "dope modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "dope modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;	
					$dope_finish = 0;
					next;			
				}
			}
				
		}
		
		if($modfoldclust2_finish)
		{
			$checkfile = "$dir_output/ALL_scores/modfoldclust2.$targetname";
			if(-e $checkfile or $modfoldclust2_manuallystop == 1)
			{
				if(-e $checkfile)
				{
					$modfoldclust2_finish = 0;
					next;
				}
				if($modfoldclust2_manuallystop == 0)
				{
					print "modfoldclust2 modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "modfoldclust2 modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$modfoldclust2_finish = 0;
					next;
				}else{
					print "modfoldclust2 modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "modfoldclust2 modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;	
					$modfoldclust2_finish = 0;
					next;			
				}
			}
				
		}	
		
		if($pcons_finish)
		{
			$checkfile = "$dir_output/ALL_scores/feature_pcons.$targetname";
			if(-e $checkfile or $pcons_manuallystop == 1)
			{
				if(-e $checkfile)
				{
					$pcons_finish = 0;
					next;
				}
				if($pcons_manuallystop == 0)
				{
					print "pcons modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "pcons modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$pcons_finish = 0;
					next;
				}else{
					print "pcons modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "pcons modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;	
					$pcons_finish = 0;
					next;			
				}
				
			}
		}
		
		if($pairwise_finish)
		{
			$checkfile = "$dir_output/ALL_scores/feature_pairwiseScore.$targetname";
			if(-e $checkfile or $pairwise_manuallystop == 1)
			{
				if(-e $checkfile)
				{
					$pairwise_finish = 0;
					next;
				}
				if($pairwise_manuallystop == 0)
				{
					print "pairwise modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "pairwise modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$pairwise_finish = 0;
					next;
				}else{
					print "pairwise modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "pairwise modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;	
					$pairwise_finish = 0;
					next;			
				}
			}
				
		}
		
		if($voronota_finish)
		{
			$checkfile = "$dir_output/ALL_scores/feature_voronota.$targetname";
			if(-e $checkfile or $voronota_manuallystop == 1)
			{
				if(-e $checkfile)
				{
					$voronota_finish = 0;
					next;
				}
				if($voronota_manuallystop == 0)
				{
					print "voronota modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "voronota modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$voronota_finish = 0;
					next;
				}else{
					print "voronota modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "voronota modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;	
					$voronota_finish = 0;
					next;			
				}
			}
				
		}
		
		if($DeepQA_finish)
		{
			$checkfile = "$dir_output/ALL_scores/feature_DeepQA.$targetname";
			if(-e $checkfile or $DeepQA_manuallystop == 1)
			{
				if(-e $checkfile)
				{
					$DeepQA_finish = 0;
					next;
				}
				if($DeepQA_manuallystop == 0)
				{
					print "DeepQA modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "DeepQA modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$DeepQA_finish = 0;
					next;
				}else{
					print "DeepQA modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "DeepQA modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;	
					$DeepQA_finish = 0;
					next;			
				}
				
			}
		}
		
		if($SBROD_finish)
		{
			$checkfile = "$dir_output/ALL_scores/feature_SBROD.$targetname";
			if(-e $checkfile or $SBROD_manuallystop == 1)
			{
				if(-e $checkfile)
				{
					$SBROD_finish = 0;
					next;
				}
				if($SBROD_manuallystop == 0)
				{
					print "SBROD modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "SBROD modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$SBROD_finish = 0;
					next;
				}else{
					print "SBROD modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "SBROD modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;	
					$SBROD_finish = 0;
					next;			
				}
				
			}
		}
		
		if($Proq3_finish)
		{
			$checkfile1 = "$dir_output/ALL_scores/feature_proq2.$targetname";
			$checkfile2 = "$dir_output/ALL_scores/feature_proq3.$targetname";
			$checkfile3= "$dir_output/ALL_scores/feature_proq3_lowres.$targetname";
			$checkfile4 = "$dir_output/ALL_scores/feature_proq3_highres.$targetname";
			if((-e $checkfile1 and -e $checkfile2 and -e $checkfile3 and -e $checkfile4) or $Proq3_manuallystop == 1)
			{
				if(-e $checkfile1 and -e $checkfile2 and -e $checkfile3 and -e $checkfile4)
				{
					$Proq3_finish = 0;
					next;
				}
				if($Proq3_manuallystop == 0)
				{
					print "Proq3 modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "Proq3 modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$Proq3_finish = 0;
					next;
				}else{
					print "Proq3 modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "Proq3 modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;	
					$Proq3_finish = 0;
					next;			
				}
			}
				
		}
		if($dncon2_finish)
		{

			$checkfile1 = "$dir_output/ALL_scores/feature_dncon2_short-range.$targetname";
			$checkfile2 = "$dir_output/ALL_scores/feature_dncon2_medium-range.$targetname";
			$checkfile3= "$dir_output/ALL_scores/feature_dncon2_long-range.$targetname";
			if((-e $checkfile1 and -e $checkfile2 and -e $checkfile3) or $dncon2_manuallystop == 1)
			{
				if(-e $checkfile1 and -e $checkfile2 and -e $checkfile3)
				{
					$dncon2_finish = 0;
					next;
				}
				if($dncon2_manuallystop == 0)
				{
					print "dncon2 modeling finished!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "dncon2 modeling finished! ($model_diff_hrs hr)\n";
					close STATUS;
					$dncon2_finish = 0;
					next;
				}else{
					print "dncon2 modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
					$finishtime = time();
					$model_diff_hrs = ($finishtime - $checktime)/3600;
					open(STATUS,">>$dir_output/modelling_status.txt")|| die "Failed to write $dir_output/modelling_status.txt \n";
					print STATUS "dncon2 modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs hr)\n";
					close STATUS;	
					$dncon2_finish = 0;
					next;			
				}
			}
				
		}
		
		print "\n!!!!!!! Checking method status !!!!!! \n";
		print "!!!!!! OPUS:".$OPUS_finish."\tlocal_global:".$local_global_finish."\tRF_SRS:".$RF_SRS_finish."\tRWplus:".$RWplus_finish."\tdope:".$dope_finish."\tmodfoldclust2:".$modfoldclust2_finish."\tpcons:".$pcons_finish."\tpairwise:".$pairwise_finish."\tvoronota:".$voronota_finish."\tDeepQA:".$DeepQA_finish."\tProq3:".$Proq3_finish."\tSBROD:".$SBROD_finish."\tdncon2:".$dncon2_finish." !!!!!! \n\n";
		
		
		if($OPUS_finish== 0 and $local_global_finish== 0 and $RF_SRS_finish== 0 and $RWplus_finish== 0 and $dope_finish== 0 and $modfoldclust2_finish== 0 and $pcons_finish== 0 and $pairwise_finish== 0  and $voronota_finish== 0 and $DeepQA_finish== 0 and $Proq3_finish== 0 and $SBROD_finish== 0 and $dncon2_finish== 0)
		{
			last;
		}
		
		sleep(2);
		$currenttime = time();
	    $model_check_hrs = ($currenttime - $checktime);
		if($model_check_hrs > $EXEC_LIMIT_HRS)
		#if($model_check_hrs > 60*3)
		{
			for ($k = 0; $k < @tools; $k++)
			{
				$tool = $tools[$k];
				$kidpid = $thread_ids[$k];
				print "<$tool> has ran more than $EXEC_LIMIT_HRS hr, skip it and kill process $kidpid !\n";
				
				
				if($tool eq 'OPUS')
				{
					$OPUS_manuallystop = 1;
				}
				if($tool eq 'local_global')
				{
					$local_global_manuallystop = 1;
				}
				if($tool eq 'RF_SRS')
				{
					$RF_SRS_manuallystop = 1;
				}
				if($tool eq 'RWplus')
				{
					$RWplus_manuallystop = 1;
				}
				if($tool eq 'dope')
				{
					$dope_manuallystop = 1;
				}
				if($tool eq 'modfoldclust2')
				{
					$modfoldclust2_manuallystop = 1;
				}
				if($tool eq 'pcons')
				{
					$pcons_manuallystop = 1;
				}
				if($tool eq 'pairwise')
				{
					$pairwise_manuallystop = 1;
				}
				if($tool eq 'voronota')
				{
					$voronota_manuallystop = 1;
				}
				if($tool eq 'DeepQA')
				{
					$DeepQA_manuallystop = 1;
				}
				if($tool eq 'Proq3')
				{
					$Proq3_manuallystop = 1;
				}
				if($tool eq 'SBROD')
				{
					$SBROD_manuallystop = 1;
				}
				if($tool eq 'dncon2')
				{
					$dncon2_manuallystop = 1;
				}
			}
		}	
		sleep(600);
	}
}
		

sleep(10);
$f_RF_SRS=$TMP_output."/"."feature_RF_SRS.".$targetname;                                                        # RF_SRS score
$f_ss_sim=$TMP_output."/"."local_global_features/Global_features/1_feature_ss_sim.".$targetname;                   # secondary structure similarity
$f_ss_pen=$TMP_output."/"."local_global_features/Global_features/2_feature_ss_penalty.".$targetname;               # secondary structure penalty
$f_eucli=$TMP_output."/"."local_global_features/Global_features/3_feature_euclidean.".$targetname;                 # euclidean pairwise distance
$f_surf=$TMP_output."/"."local_global_features/Global_features/4_feature_surface.".$targetname;                    # surface
$f_w_surf=$TMP_output."/"."local_global_features/Global_features/5_feature_weighted.".$targetname;                 # weighted surface
$f_t_surf=$TMP_output."/"."local_global_features/Global_features/6_feature_total_surf.".$targetname;               # total surface
$f_solv=$TMP_output."/"."local_global_features/Global_features/7_feature_solvent.".$targetname;                    # solvent accessibility score
$f_RW=$TMP_output."/"."feature_RWplus.".$targetname;                                                             # RWplus score
$f_dope=$TMP_output."/"."feature_dope.".$targetname;                                                            # dope score

=pod
system("cp $score_modfold $ALL_14_scores");
system("cp $score_pcons $ALL_14_scores");
system("cp $score_pairwise $ALL_14_scores/feature_pairwiseScore.$targetname");

system("cp $ren_RF_SRS $ALL_14_scores");
system("cp $ren_dope $ALL_14_scores");
system("cp $ren_RWplus $ALL_14_scores");

system("cp $ren_voronota $ALL_14_scores");
system("cp $ren_DeepQA $ALL_14_scores");
system("cp $ren_Proq2_global $ALL_14_scores");
system("cp $ren_Proq3_global $ALL_14_scores");
system("cp $ren_Proq3_lowres $ALL_14_scores");
system("cp $ren_Proq3_highres $ALL_14_scores");
system("cp $ren_SBROD $ALL_14_scores");
system("cp $ren_dncon2_short $ALL_14_scores");
system("cp $ren_dncon2_medium $ALL_14_scores");
system("cp $ren_dncon2_long $ALL_14_scores");
=cut
system("cp $ren_DeepQA $ALL_14_scores");
 

 

=pod
system("cp $score_modfold $ALL_scores");
system("cp $score_pcons $ALL_scores");
system("cp $score_pairwise $ALL_scores/feature_pairwiseScore.$targetname");

system("cp $ren_RF_SRS $ALL_scores");
system("cp $ren_dope $ALL_scores");
system("cp $ren_RWplus $ALL_scores");

system("cp $f_RF_SRS $ALL_scores/feature_RF_SRS.$targetname");
system("cp $f_ss_sim $ALL_scores/feature_ss_sim.$targetname");
system("cp $f_ss_pen $ALL_scores/feature_ss_penalty.$targetname");
system("cp $f_eucli $ALL_scores/feature_euclidean.$targetname");
system("cp $f_surf $ALL_scores/feature_surface.$targetname");
system("cp $f_w_surf $ALL_scores/feature_weighted.$targetname");
system("cp $f_t_surf $ALL_scores/feature_total_surf.$targetname");
system("cp $f_solv $ALL_scores/feature_solvent.$targetname");

system("cp $ren_voronota $ALL_scores");
system("cp $ren_DeepQA $ALL_scores");

system("cp $ren_Proq2_global $ALL_scores");
system("cp $ren_Proq3_global $ALL_scores");
system("cp $ren_Proq3_lowres $ALL_scores");
system("cp $ren_Proq3_highres $ALL_scores");
system("cp $ren_SBROD $ALL_scores");
system("cp $ren_dncon2_short $ALL_scores");
system("cp $ren_dncon2_medium $ALL_scores");
system("cp $ren_dncon2_long $ALL_scores");
=cut
system("cp $ren_DeepQA $ALL_scores");

my($score_log) = $dir_output."/"."score.log";
chdir($dir_output);
#system("rm -rf $TMP_output");
system("rm -rf $models_proq3");
system("rm -rf $models_folder");
system("rm -rf $models_DeepQA");
system("rm -rf $models_dncon2");
system("rm -rf $models_local_global");
system("rm -rf $TMP_output/local_global_features");
system("rm -rf $TMP_output/Proq3/proq_out.tar.gz");
system("rm -rf $TMP_output/ren_filtered_model");
system("rm -rf $TMP_output/feature_energy");
system("rm -rf $dir_output/LOG");
system("chmod -R 777 $dir_output/*");


END:
print " !!!!Feature generationg finished!\n";

$DeepRank_finishtime = time();
$DeepRank_diff_hrs = ($DeepRank_finishtime - $DeepRank_starttime)/3600;
print "\n!!!!Feature generationg finished within $DeepRank_diff_hrs hrs!\n\n";


 sub filter_score($$)
 { 
    my($dir_scores,$log)=@_;
    my($IN,$line,$OUT,$file,$path_score);
    my(@tem,@files);
    my(%hash);
    my($flag)=0;
    my($total,$key,$value);
    $OUT = new FileHandle ">$log";
    opendir(DIR,"$dir_scores");
    @files = readdir(DIR);    
    foreach $file (@files)
    {
      if($file eq "." || $file eq "..")
      {
         next;
      }
      $path_score = $dir_scores."/".$file;
      $total = 0;
      %hash = ();
      $IN = new FileHandle "$path_score";
      while(defined($line=<$IN>))
      {
         chomp($line);
         @tem = split(/\s+/,$line);
         if($tem[0] eq "REMARK" || $tem[0] eq "PFRMAT" ||$tem[0] eq "TARGET" ||$tem[0] eq "AUTHOR" ||$tem[0] eq "METHOD" ||$tem[0] eq "MODEL" || $tem[0] eq "QMODE" || $tem[0] eq "END")
         {
             next;
         }
         if(looks_like_number($tem[0]) || $tem[0] eq "X")
         {
             next;
         }
		 if(@tem<2)
		 {
			 next;
		 }
         $total++;
         if(exists $hash{$tem[1]})
         {
             $hash{$tem[1]}++;
         }         
         else
         {
             $hash{$tem[1]}=1;
         }
      }
      $IN->close();
      ###### now check whether this score is reliable #######
      $total/=2;
      foreach $key (keys %hash)
      {
         if($hash{$key} > $total)
         {
            $flag = 1;
            print $OUT "!!!!! WARNING, check the score $path_score, more than half models have the same score $key, removed.\n";
			system("rm $path_score");
         }
         
      }  
      if($total==0)
      {
         $flag = 1;
         print $OUT "!!!!! WARNING, check the score $path_score, no score is generated! Removed.\n";
         system("rm $path_score");
      }
    }
    if($flag == 0)
    {
       print $OUT "All scores are generated properly, not missing any one.\n";
    }
    print $OUT "\n**********************************\n";
    $OUT->close();
 }
 


