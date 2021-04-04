#! /usr/bin/perl -w
#
use Cwd;

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

our %AA3TO1 = qw(ALA A ASN N CYS C GLN Q HIS H LEU L MET M PRO P THR T TYR Y ARG R ASP D GLU E GLY G ILE I LYS K PHE F SER S TRP W VAL V);
our %AA1TO3 = reverse %AA3TO1;


############## Revise the path ########################
$DeepRank_install = "/home/jianliu/DeepRank3/";
$H_script = "$DeepRank_install/src/scripts";
$H_tool = "$DeepRank_install/tools";

########################################################


if(@ARGV <4 or @ARGV >7)
{
die "The number of parameter is not correct!\n";
}

$targetname = $ARGV[0];
$seqfile = abs_path($ARGV[1]);
$dir_models = abs_path($ARGV[2]);
$dir_output = abs_path($ARGV[3]);
$dncon4_file = $ARGV[4]; 
$dist_file = $ARGV[5];
$native_score = $ARGV[6]; # optional


if(!defined($dncon4_file))
{
        $dncon4_file='None';
}
else
{
	$dncon4_file=abs_path($dncon4_file)
}

if(!defined($dist_file))
{
        $dist_file='None';
}
else
{
	$dist_file=abs_path($dist_file)
}

if(!defined($native_score))
{
	$native_score='None';
}

$DeepRank_starttime = time();

if(!(-d $dir_output))
{
	`mkdir $dir_output`;
}


##### filter the models according to the fasta sequence 
if(!(-d "$dir_output/mod2"))
{
	`mkdir  $dir_output/mod2`;
}else{
	`rm -rf $dir_output/mod2/*`;
}

open(INPUT, "$seqfile") || die "ERROR! Could not open $seqfile\n";
@fasta_arr = <INPUT>;
close INPUT;
shift @fasta_arr;
$fasta_seq = shift @fasta_arr;
chomp $fasta_seq;

opendir(DIR,$dir_models) || die "Failed to open dir $dir_models\n";
@targets = readdir(DIR);
closedir(DIR);
$model_num = 0;
foreach $model (@targets)
{
	chomp $model;
	if($model eq '.' or $model eq '..')
	{
		next;
	}
	$file_PDB = "$dir_models/$model";
	$seq = "";
	open(INPUTPDB, "$file_PDB") || die "ERROR! Could not open $file_PDB\n";
	while(<INPUTPDB>){
		next if $_ !~ m/^ATOM/;
		next unless (parse_pdb_row($_,"aname") eq "CA");
		confess "ERROR!: ".parse_pdb_row($_,"rname")." residue not defined! \nFile: $file_PDB! \nLine : $_" if (not defined $AA3TO1{parse_pdb_row($_,"rname")});
		my $res = $AA3TO1{parse_pdb_row($_,"rname")};
		$seq .= $res;
	}
	close INPUTPDB;
	if($seq eq $fasta_seq)
	{
		$model_num++;
		$modelnew=$model;
		if(substr($modelnew,length($modelnew)-4) eq '.pdb')  ## for the qa, if the model name is too long, OPUS will fail, like MULTICOM-CONSTRUCT_TS1.pd
		{
			#$modelnew .= '.pdb';
			$modelnew = substr($modelnew,0,length($modelnew)-4);
		}
		### do we need add scwrl here?????
		
		$status=system("$H_tool/scwrl4/Scwrl4 -i $file_PDB -o $dir_output/mod2/$modelnew.tmp 2>&1 &> /dev/null");
		if($status!=0)
		{
		  print  "$H_tool/scwrl4/Scwrl4 -i $file_PDB -o $dir_output/mod2/$modelnew.tmp fails !\n";
		}

		if(!-s "$dir_output/mod2/$modelnew.tmp")
		{# scwrl fails in this case, only CA atom is in the pdb, we directly copy it from original
			print("scwrl fails in this case, only CA atom is in the pdb\n");
			next;
		}
		
		
		
		$seq2 = "";
		open(INPUTPDB, "$dir_output/mod2/$modelnew.tmp") || die "ERROR! Could not open $dir_output/mod2/$modelnew.tmp\n";
		while(<INPUTPDB>){
			next if $_ !~ m/^ATOM/;
			next unless (parse_pdb_row($_,"aname") eq "CA");
			confess "ERROR!: ".parse_pdb_row($_,"rname")." residue not defined! \nFile: $file_PDB! \nLine : $_" if (not defined $AA3TO1{parse_pdb_row($_,"rname")});
			my $res = $AA3TO1{parse_pdb_row($_,"rname")};
			$seq2 .= $res;
		}
		close INPUTPDB;
		
		if($seq2 ne $seq)
		{
			`rm $dir_output/mod2/$modelnew.tmp`;
			next;
		}else{
			`mv $dir_output/mod2/$modelnew.tmp $dir_output/mod2/$modelnew`;
		}
	}else{
	
		print "Warning: sequence not match!!!\n$seq\n$fasta_seq\n\n";
	}
}

## redefine dir_models
$dir_models = "$dir_output/mod2";
print "$model_num models are selected for evaluation\n";


##### create folder
my($TMP_output) = $dir_output."/"."TMP";
-s $TMP_output || system("mkdir $TMP_output");

# my($ren_dncon2_features)=$TMP_output."/dncon2";
# if(!(-d $ren_dncon2_features))
# {
# 	`mkdir $ren_dncon2_features`;
# }


$ALL_scores = $dir_output."/"."ALL_scores/";
system("mkdir -p  $ALL_scores");

$ALL_14_scores = $dir_output."/"."ALL_14_scores/";
system("mkdir -p $ALL_14_scores");

$LGA_model_num=0;
$validate = 1;
if($native_score ne 'None')
{
	print "Detecting native score $native_score, validating......\n\n";
	
	if(-e $native_score)
	{
		open(TMP,$native_score) || die "Failed to open dir $native_score\n";
		@content = <TMP>;
		close TMP;

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
		opendir(DIR,$dir_models) || die "Failed to open dir $dir_models\n";
		@targets = readdir(DIR);
		closedir(DIR);
		foreach $model (@targets)
		{
			chomp $model;
			if($model eq '.' or $model eq '..')
			{
				next;
			}
		   if(!exists($LGA_score_list{$model} ))
		   {
				print "Failed to find the model $model in your native score, incorrect native file, ignore\n\n";
				$validate = 0;
				last;
		   }
		}
	}else{
		$validate = 0;
	}
}

if($validate ==0)
{
	$native_score='None';
}else{
	print "Loading native score $native_score\n\n";
}
##### (1) Run feature generation
print "\n\n##### (1) Run feature generation\n\n";
print("perl $H_script/P1_feature_generation_parallel_deeprank3_singleQA.pl $targetname $seqfile $dir_models $dir_output $dncon4_file $dist_file\n");
$status = system("perl $H_script/P1_feature_generation_parallel_deeprank3_singleQA.pl $targetname $seqfile $dir_models $dir_output $dncon4_file $dist_file");
if($status)# if failed, should we use at least one score?
{
	die "Failed to run the feature generation\n";
}


print "!!!!!! Checking if all features are generated successfully\n\n";

$all_features_list2="feature_DeepQA,feature_RF_SRS,feature_RWplus,feature_voronota,feature_dope,feature_proq2,feature_proq3_lowres,feature_proq3_highres,feature_proq3,feature_OPUS,feature_total_surf,feature_ss_sim,feature_solvent,feature_weighted,feature_euclidean,feature_ss_penalty,feature_SBROD,feature_dncon4_short-range,feature_dncon4_medium-range,feature_dncon4_long-range,feature_dist_gist,feature_dist_precl2_long,feature_dist_precl2,feature_dist_psnr,feature_dist_recall_long,feature_dist_orb_num,feature_dist_pearson,feature_dist_phash,feature_dist_recall,feature_dist_rmse,feature_dist_ssim";


@all_features = split(',',$all_features_list2);

%LGA_score_list = ();
$LGA_model_num=0;

opendir(DIR,$dir_models) || die "Failed to open dir $dir_models\n";
@targets = readdir(DIR);
closedir(DIR);
foreach $model (@targets)
{
	chomp $model;
	if($model eq '.' or $model eq '..')
	{
		next;
	}
	$LGA_model_num++;
  $LGA_score_list{$model} = 0; # this is for prediction
}


### 2. check if all methods have generated score for models as LGA
$check_iteration=0;
while($check_iteration<4)
{
	sleep(10);
	$check_iteration++;
	$incomplete=0;
	foreach $method (@all_features)
	{
	  $method_score = "$dir_output/ALL_scores/$method.$targetname";
	  if(!(-e $method_score))
	  {
		 print "$targetname incomplete (missing $method_score)\n";
		 $incomplete=1;
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
		
		
		if($method eq 'feature_SBROD')
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
		 print "The model number in $method_score ($model_num) not match model number ($LGA_model_num), removing it\n";
		 `mv $method_score $method_score.old_$check_iteration`;
		 $incomplete=1;
	  }
	}
	if($incomplete == 0)
	{
		print "\n\n!!!!!!!!!! All features are generated correctly\n\n";
		last;
	}
	print "\n\n##### (1) Re-Run feature generation with iteration $check_iteration\n\n";
	print("perl $H_script/P1_feature_generation_parallel_deeprank3_singleQA.pl $targetname $seqfile $dir_models $dir_output $dncon4_file $dist_file\n");
	$status = system("perl $H_script/P1_feature_generation_parallel_deeprank3_singleQA.pl  $targetname $seqfile $dir_models $dir_output $dncon4_file $dist_file");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the feature generation\n";
	}
}




##### (2)  check if contact file exists and Run feature organization

#### make prediction with contact file
if(-e "$ALL_scores/feature_dncon4_short-range.$targetname" and -e "$ALL_scores/feature_dncon4_medium-range.$targetname" and -e "$ALL_scores/feature_dncon4_long-range.$targetname")
{

	##### Run feature organization
	print "\n\n##### (2) Run feature organization\n\n";
	print("perl $H_script/P2_combine_score_into_SVMformat_nosubfix_fea31.pl $dir_models $dir_output/ALL_scores/ $targetname  $dir_output/feat_singleQA.txt $native_score\n");
	$status = system("perl $H_script/P2_combine_score_into_SVMformat_nosubfix_fea31.pl $dir_models $dir_output/ALL_scores/ $targetname  $dir_output/feat_singleQA.txt $native_score");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the feature organization\n";
	}


	##### (3) Run make prediction for gdt score 
	print "\n\n##### (3) Run make prediction for gdt score\n\n";
	`mkdir $dir_output/10_fold_prediction_singleQA/`;
	print("perl $H_script/P3_make_prediction_by_10folds.pl $dir_output/feat_singleQA.txt test $H_script/python_lib/DeepRank3_singleQA_fea31_models/ $dir_output/10_fold_prediction_singleQA/\n");
	$status = system("perl $H_script/P3_make_prediction_by_10folds.pl $dir_output/feat_singleQA.txt test $H_script/python_lib/DeepRank3_singleQA_fea31_models/ $dir_output/10_fold_prediction_singleQA/");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the prediction for gdt\n";
	}

	## add into training and testing dataset 
	print("perl $H_script/P4_add_prediction2feature_feature31_10folds_avg.pl $dir_output/feat_singleQA.txt  test $dir_output/10_fold_prediction_singleQA/  $dir_output/feat_with10folds_singleQA.txt\n");
	$status = system("perl $H_script/P4_add_prediction2feature_feature31_10folds_avg.pl $dir_output/feat_singleQA.txt  test $dir_output/10_fold_prediction_singleQA/  $dir_output/feat_with10folds_singleQA.txt");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run <P1_add_prediction2feature_feature31_10folds.pl>\n";
	}

	print("THEANO_FLAGS=floatX=float32,device=cpu python $H_script/python_lib/predict_main_auto_NN_single.py nadam $dir_output/feat_with10folds_singleQA.txt $H_script/python_lib/DeepRank3_singleQA_fea31_models/10fold_2nd_stage_avg_optnadam_htsigmoid_hn10   $dir_output/feat_gdt_predict_singleQA.txt\n");
	$status = system("THEANO_FLAGS=floatX=float32,device=cpu python $H_script/python_lib/predict_main_auto_NN_single.py nadam $dir_output/feat_with10folds_singleQA.txt $H_script/python_lib/DeepRank3_singleQA_fea31_models/10fold_2nd_stage_avg_optnadam_htsigmoid_hn10   $dir_output/feat_gdt_predict_singleQA.txt");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the prediction for gdt\n";
	}



	print("perl $H_script/P5_add_prediction2feature_feature32.pl $dir_output/feat_singleQA.txt   $dir_output/feat_gdt_predict_singleQA.txt  $dir_output/feat_gdt_predict_withall_singleQA.txt\n");
	$status = system("perl $H_script/P5_add_prediction2feature_feature32.pl $dir_output/feat_singleQA.txt   $dir_output/feat_gdt_predict_singleQA.txt  $dir_output/feat_gdt_predict_withall_singleQA.txt");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the prediction adding for gdt\n";
	}

	$status = system("perl $H_script/P6_get_model2prediction.pl $dir_output/feat_singleQA.txt  $dir_output/feat_gdt_predict_singleQA.txt  $dir_output/DeepRank3_SingleQA_unsort.txt");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to get final prediction for gdt\n";
	}
	
	system("perl $H_script/sort_deep_qa_score.pl $dir_output/DeepRank3_SingleQA_unsort.txt $dir_output/DeepRank3_SingleQA.txt");


	#### ** if LGA_score exists
	if($native_score ne 'None')
	{
		`mkdir $dir_output/feature_analysis/`;
		system("perl $H_script/P7_evaluate_feature_by_targets.pl  $dir_output/feat_gdt_predict_withall_singleQA.txt  $dir_output/feature_analysis/  $dir_output/feat_gdt_predict_withall_SingleQA.eva");
	}

}

if(-d "$dir_output/mod2")
{
	`rm -rf $dir_output/mod2`;
}
print "\nFinal prediction: $dir_output/DeepRank3_SingleQA.txt\n\n";

$DeepRank_finishtime = time();
$method_diff_hrs = ($DeepRank_finishtime - $DeepRank_starttime)/3600;

print "\n\n####### DeepRank prediction done within $method_diff_hrs hr!!!!!\n\n";



sub parse_pdb_row{
	my $row = shift;
	my $param = shift;
	my $result;
	$result = substr($row,6,5) if ($param eq "anum");
	$result = substr($row,12,4) if ($param eq "aname");
	$result = substr($row,16,1) if ($param eq "altloc");
	$result = substr($row,17,3) if ($param eq "rname");
	$result = substr($row,22,5) if ($param eq "rnum");
	$result = substr($row,21,1) if ($param eq "chain");
	$result = substr($row,30,8) if ($param eq "x");
	$result = substr($row,38,8) if ($param eq "y");
	$result = substr($row,46,8) if ($param eq "z");
	print "Invalid row[$row] or parameter[$param]" if (not defined $result);
	$result =~ s/\s+//g;
	return $result;
}
