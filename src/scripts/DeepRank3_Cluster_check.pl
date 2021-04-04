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

our %AA3TO1 = qw(ALA A ASN N CYS C GLN Q HIS H LEU L MET M PRO P THR T TYR Y ARG R ASP D GLU E GLY G ILE I LYS K PHE F SER S TRP W VAL V);
our %AA1TO3 = reverse %AA3TO1;


############## Revise the path ########################
my($H_script) = "/home/casp13/Human_QA_package/HUMAN/scripts";
my($H_tool) = "/home/casp13/Human_QA_package/HUMAN/tools";

########################################################


if(@ARGV <4 or @ARGV >6)
{
die "The number of parameter is not correct!\n";
}

$targetname = $ARGV[0];
$seqfile = abs_path($ARGV[1]);
$dir_models = abs_path($ARGV[2]);
$dir_output = abs_path($ARGV[3]);
$contact_file = $ARGV[4]; # optional
$native_score = $ARGV[5]; # optional

if(!defined($native_score))
{
	$native_score='None';
}
if(!defined($contact_file))
{
	$contact_file='None';
}

$human_method_starttime = time();

if(!(-d $dir_output))
{
	`mkdir $dir_output`;
}

$dir_models_orig = $dir_models;
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

%model_mapping=();
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
		#if(substr($modelnew,length($modelnew)-4) ne '.pdb') ## proq will report no subfix
		#{
		#	$modelnew .= '.pdb';
		#}
		$model_mapping{$modelnew} = $model;
		### do we need add scwrl here?????
		`cp $file_PDB  $dir_output/mod2/$modelnew`;
	}
}

## redefine dir_models
$dir_models = "$dir_output/mod2";
print "$model_num models are selected for evaluation\n";


##### create folder
my($TMP_output) = $dir_output."/"."TMP";
-s $TMP_output || system("mkdir $TMP_output");

my($ren_dncon2_features)=$TMP_output."/dncon2";
if(!(-d $ren_dncon2_features))
{
	`mkdir $ren_dncon2_features`;
}


$ALL_scores = $dir_output."/"."ALL_scores/";
system("mkdir -p  $ALL_scores");

$ALL_14_scores = $dir_output."/"."ALL_14_scores/";
system("mkdir -p $ALL_14_scores");


if($contact_file ne 'None')
{
	print "Detecting contact file $contact_file, validating......\n\n";
	
	if(-e $contact_file)
	{
		`cp $contact_file $ren_dncon2_features/$targetname.dncon2.rr`;
	}
}

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
		   if(!exists($LGA_score_list{$model_mapping{$model}} ))
		   {
				print "Failed to find the model $model_mapping{$model} in your native score, incorrect native file, ignore\n\n";
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
print("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_feature_generation.pl $targetname $seqfile $dir_models $dir_output\n");
$status = system("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_feature_generation.pl $targetname $seqfile $dir_models $dir_output");
if($status)# if failed, should we use at least one score?
{
	die "Failed to run the feature generation\n";
}


print "!!!!!! Checking if all features are generated successfully\n\n";

#$all_features_list2 = "feature_DeepQA,feature_pairwiseScore,feature_RF_SRS,feature_pcons,feature_RWplus,feature_voronota,feature_dope,feature_proq2,feature_proq3_lowres,feature_proq3_highres,feature_proq3,modfoldclust2,feature_OPUS,feature_total_surf,feature_ss_sim,feature_solvent,feature_weighted,feature_euclidean,feature_ss_penalty,feature_SBROD,feature_dncon2_short-range,feature_dncon2_medium-range,feature_dncon2_long-range";
$all_features_list2 = "feature_DeepQA,feature_RF_SRS,feature_RWplus,feature_voronota,feature_dope,feature_proq2,feature_proq3_lowres,feature_proq3_highres,feature_proq3,feature_OPUS,feature_total_surf,feature_ss_sim,feature_solvent,feature_weighted,feature_euclidean,feature_ss_penalty,feature_SBROD,feature_dncon2_short-range,feature_dncon2_medium-range,feature_dncon2_long-range";
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
	# perl /home/casp13/Human_QA_package/scripts/P1_feature_generation_casp13_parallel.pl  T0946 /home/casp13/Human_QA_package/Jie_dev_casp13/data/casp12_original_seq//T0946.fasta  /home/casp13/Human_QA_package/HQA_cp12//T0946/T0946 /home/casp13/Human_QA_package/HQA_cp12//T0946_para1
	print("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_feature_generation.pl $targetname $seqfile $dir_models $dir_output\n");
	$status = system("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_feature_generation.pl $targetname $seqfile $dir_models $dir_output");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the feature generation\n";
	}
}

##### check apollo score, if abinitio, use singleQA 
$apollo_score = "$ALL_scores/feature_pairwiseScore.$targetname";
%LGA_score_list = ();
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

open(IN,"$apollo_score") || die "Failed to open file $apollo_score\n";
$max_apollo = 0;
while(<IN>)
{
	$line=$_;
	chomp $line;
	$line =~ s/^\s+|\s+$//g;
		
	@tmp = split(/\s++/,$line);
	$model = $tmp[0];
	$score = $tmp[1];
	
	if(!exists($LGA_score_list{$model}))
	{
	  next;
	}
	
	if($score > $max_apollo)
 	{
		$max_apollo = $score;
	} 
}
close IN;	  
if($max_apollo < 0.14)
{
	print "Switching to single QA method\n\n";
	print("/home/casp14/DeepRank_hybrid/M1_DeepRank_SingleQA_20fea/scripts/run_DeepRank_singleQA.sh $targetname $seqfile  $dir_models_orig  $dir_output $contact_file $native_score >$dir_output/run_singleQA.log\n\n");
	system("/home/casp14/DeepRank_hybrid/M1_DeepRank_SingleQA_20fea/scripts/run_DeepRank_singleQA.sh $targetname $seqfile  $dir_models_orig  $dir_output $contact_file $native_score >$dir_output/run_singleQA.log");
	goto FINISH;
}
##### (2)  check if contact file exists and Run feature organization

#### make prediction with contact file
if(-e "$ALL_scores/feature_dncon2_short-range.$targetname" and -e "$ALL_scores/feature_dncon2_medium-range.$targetname" and -e "$ALL_scores/feature_dncon2_long-range.$targetname")
{

	##### Run feature organization
	print "\n\n##### (2) Run feature organization\n\n";
	print("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_combine_score_into_SVMformat.pl $dir_models $dir_output/ALL_scores/ $targetname  $dir_output/feat.txt $native_score\n");
	$status = system("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_combine_score_into_SVMformat.pl $dir_models $dir_output/ALL_scores/ $targetname  $dir_output/feat.txt $native_score");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the feature organization\n";
	}


	##### (3) Run make prediction for gdt score
	print "\n\n##### (3) Run make prediction for gdt score\n\n";
	`mkdir $dir_output/10_fold_prediction/`;

	print("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_make_prediction_by_10folds.pl $dir_output/feat.txt test /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/ $dir_output/10_fold_prediction/\n");
	$status = system("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_make_prediction_by_10folds.pl $dir_output/feat.txt test /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/ $dir_output/10_fold_prediction/");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the prediction for gdt\n";
	}

	## add into training and testing dataset 
	print("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_add_prediction2feature_feature23_10folds.pl $dir_output/feat.txt  test $dir_output/10_fold_prediction/  $dir_output/feat_with10folds.txt\n");
	$status = system("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_add_prediction2feature_feature23_10folds.pl $dir_output/feat.txt  test $dir_output/10_fold_prediction/  $dir_output/feat_with10folds.txt");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run <P1_add_prediction2feature_feature23_10folds.pl>\n";
	}

	print("THEANO_FLAGS=floatX=float32,device=cpu python /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/predict_main.py nadam $dir_output/feat_with10folds.txt /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/10fold_2nd_stage_optnadam_htsigmoid_hn5   $dir_output/feat_gdt_predict.txt\n");
	$status = system("THEANO_FLAGS=floatX=float32,device=cpu python /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/predict_main.py nadam $dir_output/feat_with10folds.txt /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/10fold_2nd_stage_optnadam_htsigmoid_hn5  $dir_output/feat_gdt_predict.txt");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the prediction for gdt\n";
	}

	print("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_add_prediction2feature_feature34.pl $dir_output/feat_with10folds.txt   $dir_output/feat_gdt_predict.txt  $dir_output/feat_gdt_predict_withall.txt\n");
	$status = system("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_add_prediction2feature_feature34.pl $dir_output/feat_with10folds.txt   $dir_output/feat_gdt_predict.txt  $dir_output/feat_gdt_predict_withall.txt");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the prediction adding for gdt\n";
	}

	print("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_get_model2prediction.pl $dir_output/feat.txt  $dir_output/feat_gdt_predict.txt  $dir_output/HumanQA_gdt_prediction_tmp.txt\n");
	$status = system("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_get_model2prediction.pl $dir_output/feat.txt  $dir_output/feat_gdt_predict.txt  $dir_output/HumanQA_gdt_prediction_tmp.txt");
	
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to get final prediction for gdt\n";
	}
	
	## sort the prediction

	open(EVA, "$dir_output/HumanQA_gdt_prediction_tmp.txt") || die "can't read $dir_output/HumanQA_gdt_prediction_tmp.txt.\n";
	@eva = <EVA>;
	close EVA; 


	@model_info = (); 
	foreach $record (@eva)
	{
			chomp $record;
			@fields = split(/\s+/, $record);
			@fields == 2 || die "the format of $input_file is wrong.\n";
			$model_name = shift @fields;
			$score = shift @fields; 

			push @model_info, {
					name => $model_mapping{$model_name},
					score => $score 
			}

	}

	#rank all the models by max score
	@model_info = sort { $b->{"score"} <=> $a->{"score"}} @model_info; 

	$num = @model_info; 

	open(OUT, ">$dir_output/HumanQA_gdt_prediction.txt") || die "can't create file $dir_output/HumanQA_gdt_prediction.txt.\n";
	for ($i = 0; $i < $num; $i++)
	{
			print OUT $model_info[$i]->{"name"}, "\t", $model_info[$i]->{"score"}, "\n";  
	}
	close OUT; 
	
	`rm $dir_output/HumanQA_gdt_prediction_tmp.txt`;

		
	`perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_combine_10folds_prediction.pl  $dir_output/10_fold_prediction/ $dir_output/10_fold_prediction/10_fold_combined.prediction`;
	`perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_add_prediction2feature_feature24_single.pl $dir_output/feat_with10folds.txt $dir_output/10_fold_prediction/10_fold_combined.prediction $dir_output/10_fold_prediction/10_fold_combined.prediction_withFeature`;
	
	#### ** if LGA_score exists
	if($native_score ne 'None')
	{
		`mkdir $dir_output/feature_analysis/`;
		system("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_evaluate_feature_by_targets_20180201.pl  $dir_output/feat_gdt_predict_withall.txt  $dir_output/feature_analysis/  $dir_output/feat_gdt_predict_withall.eva");
		`rm -rf $dir_output/feature_analysis/`;
		
		`mkdir $dir_output/feature_analysis/`;
		system("perl /home/casp14/DeepRank_hybrid/M2_DeepRank_ConSingleQA_23fea/scripts/P1_evaluate_feature_by_targets_20180201.pl $dir_output/10_fold_prediction/10_fold_combined.prediction_withFeature  $dir_output/feature_analysis/  $dir_output/10_fold_prediction/10_fold_combined.prediction_withFeature.eva");
		`rm -rf $dir_output/feature_analysis/`;
	}			
						
						
}
=pod
else
{
	#### make prediction without contact file
	##### Run feature organization
	print "\n\n##### (2) Run feature organization\n\n";
	# perl /home/casp13/Human_QA_package/scripts/P2_combine_score_into_SVMformat.pl $dir_models $dir_output/ALL_scores/ $targetname  $dir_output/feat.txt
	print("perl /home/casp13/Human_QA_package/scripts/P2_combine_score_into_SVMformat_withoutcontact_nopdbprefix_V2.pl $dir_models $dir_output/ALL_scores/ $targetname  $dir_output/feat_nocontact.txt $native_score\n");
	$status = system("perl /home/casp13/Human_QA_package/scripts/P2_combine_score_into_SVMformat_withoutcontact_nopdbprefix_V2.pl $dir_models $dir_output/ALL_scores/ $targetname  $dir_output/feat_nocontact.txt $native_score");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the feature organization\n";
	}


	##### (3) Run make prediction for gdt score
	print "\n\n##### (3) Run make prediction for gdt score\n\n";
	`mkdir $dir_output/10_fold_prediction_withoutcontact/`;

	#perl /home/casp13/Human_QA_package/scripts/python_lib/P1_add_prediction2feature_feature26_10folds.pl /home/casp13/Human_QA_package/HQA_cp12/T0946_para3/feat_nocontact.txt  test /home/casp13/Human_QA_package/HQA_cp12/T0946_para3/10_fold_prediction_withoutcontact/  /home/casp13/Human_QA_package/HQA_cp12/T0946_para3/feat_nocontact_with10folds.txt
	print("perl /home/casp13/Human_QA_package/scripts/python_lib/P3_make_prediction_by_10folds.pl $dir_output/feat_nocontact.txt test /home/casp13/Human_QA_package/scripts/python_lib/model_gdt_feature26_withoutcontact_10folds/ $dir_output/10_fold_prediction_withoutcontact/\n");
	$status = system("perl /home/casp13/Human_QA_package/scripts/python_lib/P3_make_prediction_by_10folds.pl $dir_output/feat_nocontact.txt test /home/casp13/Human_QA_package/scripts/python_lib/model_gdt_feature26_withoutcontact_10folds/ $dir_output/10_fold_prediction_withoutcontact/");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the prediction for gdt\n";
	}

	## add into training and testing dataset 
	#perl /home/casp13/Human_QA_package/scripts/python_lib/P1_add_prediction2feature_feature26_10folds.pl /home/casp13/Human_QA_package/HQA_cp12/T0946_para3/feat_nocontact.txt  test /home/casp13/Human_QA_package/HQA_cp12/T0946_para3/10_fold_prediction_withoutcontact/  /home/casp13/Human_QA_package/HQA_cp12/T0946_para3/feat_nocontact_with10folds.txt
	print("perl /home/casp13/Human_QA_package/scripts/python_lib/P1_add_prediction2feature_feature26_10folds.pl $dir_output/feat_nocontact.txt  test $dir_output/10_fold_prediction_withoutcontact/  $dir_output/feat_nocontact_with10folds.txt\n");
	$status = system("perl /home/casp13/Human_QA_package/scripts/python_lib/P1_add_prediction2feature_feature26_10folds.pl $dir_output/feat_nocontact.txt  test $dir_output/10_fold_prediction_withoutcontact/  $dir_output/feat_nocontact_with10folds.txt");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run <P1_add_prediction2feature_feature26_10folds.pl>\n";
	}


	#THEANO_FLAGS=floatX=float32,device=cpu python /home/casp13/Human_QA_package/scripts/python_lib/predict_main_iterative_20170902_auto_NN.py nadam /home/casp13/Human_QA_package/HQA_cp12/T0946_para3/feat_with10folds.txt /home/casp13/Human_QA_package/scripts/python_lib/model_gdt_feature29_10folds/10fold_2nd_stage_optnadam_htsigmoid_hn5   /home/casp13/Human_QA_package/HQA_cp12/T0946_para3/feat_gdt_predict.txt
	print("THEANO_FLAGS=floatX=float32,device=cpu python /home/casp13/Human_QA_package/scripts/python_lib/predict_main_iterative_20170902_auto_NN.py nadam $dir_output/feat_nocontact_with10folds.txt /home/casp13/Human_QA_package/scripts/python_lib/model_gdt_feature26_withoutcontact_10folds/10fold_2nd_stage_optnadam_htsigmoid_hn50_5   $dir_output/feat_nocontact_gdt_predict.txt\n");
	$status = system("THEANO_FLAGS=floatX=float32,device=cpu python /home/casp13/Human_QA_package/scripts/python_lib/predict_main_iterative_20170902_auto_NN.py nadam $dir_output/feat_nocontact_with10folds.txt /home/casp13/Human_QA_package/scripts/python_lib/model_gdt_feature26_withoutcontact_10folds/10fold_2nd_stage_optnadam_htsigmoid_hn50_5   $dir_output/feat_nocontact_gdt_predict.txt");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the prediction for gdt\n";
	}



	print("perl /home/casp13/Human_QA_package/scripts/P3_add_prediction2feature_feature26.pl $dir_output/feat_nocontact.txt   $dir_output/feat_nocontact_gdt_predict.txt  $dir_output/feat_nocontact_gdt_predict_withall.txt\n");
	$status = system("perl /home/casp13/Human_QA_package/scripts/P3_add_prediction2feature_feature26.pl $dir_output/feat_nocontact.txt   $dir_output/feat_nocontact_gdt_predict.txt  $dir_output/feat_nocontact_gdt_predict_withall.txt");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to run the prediction adding for gdt\n";
	}

	print("perl /home/casp13/Human_QA_package/scripts/P3_get_model2prediction.pl $dir_output/feat_nocontact.txt  $dir_output/feat_nocontact_gdt_predict.txt  $dir_output/HumanQA_gdt_prediction.txt\n");
	$status = system("perl /home/casp13/Human_QA_package/scripts/P3_get_model2prediction.pl $dir_output/feat_nocontact.txt  $dir_output/feat_nocontact_gdt_predict.txt  $dir_output/HumanQA_gdt_prediction.txt");
	if($status)# if failed, should we use at least one score?
	{
		die "Failed to get final prediction for gdt\n";
	}


	#### ** if LGA_score exists
	if($native_score ne 'None')
	{
		`mkdir $dir_output/feature_analysis/`;
		system("perl /home/casp13/Human_QA_package/scripts/P4_evaluate_feature_by_targets_20180201.pl  $dir_output/feat_nocontact_gdt_predict_withall.txt  $dir_output/feature_analysis/  $dir_output/feat_nocontact_gdt_predict_withall.eva");
	}

}
=cut

		
=pod	

##### (4) Run make prediction for without contact score
print "\n\n##### (4) Run make prediction for loss\n\n";
print("THEANO_FLAGS=floatX=float32,device=cpu python /home/casp13/Human_QA_package/scripts/python_lib/predict_main_iterative_20170902_auto_NN.py nadam $dir_output/feat.txt  /home/casp13/Human_QA_package/scripts/python_lib/model_loss_20180301 $dir_output/feat_loss_predict.txt\n");
$status = system("THEANO_FLAGS=floatX=float32,device=cpu python /home/casp13/Human_QA_package/scripts/python_lib/predict_main_iterative_20170902_auto_NN.py nadam $dir_output/feat.txt  /home/casp13/Human_QA_package/scripts/python_lib/model_loss_20180301 $dir_output/feat_loss_predict.txt");
if($status)# if failed, should we use at least one score?
{
	die "Failed to run the prediction for loss\n";
}	
	
print("perl /home/casp13/Human_QA_package/scripts/P3_add_loss_prediction2feature_feature25.pl $dir_output/feat.txt   $dir_output/feat.txt $dir_output/feat_loss_predict.txt  $dir_output/feat_loss_predict_withall.txt\n");
$status = system("perl /home/casp13/Human_QA_package/scripts/P3_add_loss_prediction2feature_feature25.pl $dir_output/feat.txt  $dir_output/feat.txt  $dir_output/feat_loss_predict.txt  $dir_output/feat_loss_predict_withall.txt");
if($status)# if failed, should we use at least one score?
{
	die "Failed to run the prediction adding for loss\n";
}

print("perl /home/casp13/Human_QA_package/scripts/P3_get_model2prediction.pl $dir_output/feat.txt  $dir_output/feat_loss_predict.txt  $dir_output/HumanQA_loss_prediction.txt\n");
$status = system("perl /home/casp13/Human_QA_package/scripts/P3_get_model2prediction.pl $dir_output/feat.txt  $dir_output/feat_loss_predict.txt  $dir_output/HumanQA_loss_prediction.txt");
if($status)# if failed, should we use at least one score?
{
	die "Failed to get final prediction for gdt\n";
}
		
		
#### ** if LGA_score exists
if($native_score ne 'None')
{
	`mkdir $dir_output/feature_analysis/`;
	system("perl /home/casp13/Human_QA_package/scripts/P4_evaluate_feature_by_targets_20180201.pl  $dir_output/feat_loss_predict_withall.txt  $dir_output/feature_analysis/  $dir_output/feat_loss_predict_withall.eva");
}			
=cut

FINISH:
$human_method_finishtime = time();
$method_diff_hrs = ($human_method_finishtime - $human_method_starttime)/3600;

print "\n\n####### HumanQA prediction done within $method_diff_hrs hr!!!!!\n\n";




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
