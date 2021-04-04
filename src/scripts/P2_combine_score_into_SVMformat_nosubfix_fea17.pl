#!/usr/bin/perl -w

$numArgs = @ARGV;
if($numArgs != 5)
{   
	print "the number of parameters is not correct!\n";
	exit(1);
}

$modeldir		= "$ARGV[0]";
$score_dir		= "$ARGV[1]";
$targetid		= "$ARGV[2]";
$outputfile1	= "$ARGV[3]"; 
$LGA_score	= "$ARGV[4]"; 

open(OUT1,">$outputfile1") || die "Failed to find $outputfile1\n";

$all_features_list2="feature_RF_SRS,feature_RWplus,feature_voronota,feature_dope,feature_OPUS,feature_SBROD,feature_dist_gist,feature_dist_precl2_long,feature_dist_precl2,feature_dist_psnr,feature_dist_recall_long,feature_dist_orb_num,feature_dist_pearson,feature_dist_phash,feature_dist_recall,feature_dist_rmse,feature_dist_ssim";


@all_features = split(',',$all_features_list2);

print "Total features number: ".@all_features."\n";


$fea_id=0;
$title = "LGA";
foreach $method (@all_features)
{
    $fea_id++;
    $title .=" $fea_id:$method";    
}

print OUT1 "#$title\n";
   
#$LGA_score = "$score_dir/LGA_score.$targetid";
%LGA_score_list = ();
$LGA_model_num=0;
if(!(-e $LGA_score))
{
	print "Didn't find native score, initialize as 0....\n";
	#$cou=0;
	opendir(DIR,$modeldir) || die "Failed to open dir $modeldir\n";
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
}else{

	print "Detect native score....\n";
	#$cou=0;
	open(TMP,$LGA_score) || die "Failed to open dir $LGA_score\n";
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
}

### 2. check if all methods have generated score for models as LGA
$incomplete = 0;
$fea_id=0;
$title = "LGA";
foreach $method (@all_features)
{
  $method_score = "$score_dir/$method.$targetid";
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
	 print "The model number in $method_score ($model_num) not match model number ($LGA_model_num)\n";
	 $incomplete=1;
	 last;
	
  }
  
  
  ### output the socre 
  $fea_id++;
  $title .=" $fea_id:$method";
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
	
	
	if($method eq 'feature_SBROD')
	{
	  @tmp2 = split(/\//,$model);
	  $model = pop @tmp2;
	  chomp $model;
	  
	}
	if($method eq 'feature_SVMQA')
        {
          $score = pop @tmp;
          chomp $score;
        }

        if($method eq 'feature_dist_rmse')
        {
          if($score eq 'nan')
          {
                $score = 0;
          }else
          {
                $score = 1/(1+exp($score));
          }
        }

        if($method eq 'feature_dist_orb_num')
        {
                $score = $score/255;
        }

        if($method eq 'feature_dist_psnr')
        {
                $score = $score /100;
        }

        if(!defined($score))
        {
          $score=0;
        }
        if($score eq 'nan')
        {
                $score = 0;
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
	die "$targetid is incomplete\n";
}else
{
	print "$targetid is complete\n";
}

foreach $mod (sort keys %LGA_score_list)
{
@tmp = split(/\s/,$LGA_score_list{$mod});
$fea_num = @tmp;
if(@tmp != 18)
{
  print "!!!!!! Warning: Not enough scores ($fea_num) for model $mod, check $LGA_score_list{$mod},\n pass\n";
}
print OUT1 $LGA_score_list{$mod}." #$targetid:$mod\n";
}

close OUT1;
