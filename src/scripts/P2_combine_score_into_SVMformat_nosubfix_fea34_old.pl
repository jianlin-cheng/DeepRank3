#!/usr/bin/perl -w

$numArgs = @ARGV;
if($numArgs != 4)
{   
	print "the number of parameters is not correct!\n";
	exit(1);
}

$native_folder	= "$ARGV[0]"; #/storage/htc/bdm/jh7x3/scratch_file_backup/DeepCov_QA/data//casp8_native
$infolder		= "$ARGV[1]";
$outputfile1	= "$ARGV[2]"; #
$outputfile2	= "$ARGV[3]";

open(OUT1,">$outputfile1") || die "Failed to find $outputfile1\n";
open(OUT2,">$outputfile2") || die "Failed to find $outputfile2\n";
#$all_features_list = "feature_DeepQA,feature_pairwiseScore,feature_RF_SRS,feature_dfire,feature_pcons,feature_RWplus,feature_voronota,feature_dope,feature_proq2,feature_proq3_lowres,feature_proq3_highres,feature_proq3,modfoldclust2,feature_modeleva,feature_OPUS,feature_QApro,NOVEL_final_prediction,feature_total_surf,feature_ss_sim,feature_solvent,feature_surface,feature_weighted,feature_euclidean,feature_ss_penalty,feature_model_check2,feature_svmqa";


$all_features_list2="feature_DeepQA,feature_RF_SRS,feature_RWplus,feature_voronota,feature_dope,feature_proq2,feature_proq3_lowres,feature_proq3_highres,feature_proq3,feature_OPUS,feature_total_surf,feature_ss_sim,feature_solvent,feature_weighted,feature_euclidean,feature_ss_penalty,feature_SBROD,feature_pairwiseScore,modfoldclust2,feature_pcons,feature_dncon4_short-range,feature_dncon4_medium-range,feature_dncon4_long-range,feature_dist_gist,feature_dist_precl2_long,feature_dist_precl2,feature_dist_psnr,feature_dist_recall_long,feature_dist_orb_num,feature_dist_pearson,feature_dist_phash,feature_dist_recall,feature_dist_rmse,feature_dist_ssim";


$all_features_list2 =~ s/\s//g;

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
      
$cou=0;
opendir(DIR,$infolder) || die "Failed to open dir $infolder\n";
@targets = readdir(DIR);
closedir(DIR);

foreach $target (@targets)
{
	chomp $target;
	if($target eq '.' or $target eq '..')
	{
		next;
	}
	if(substr($target,0,1) ne 'T')
	{
		next;
	}
  $cou++;
  
  
  $native_file1 = "$native_folder/${target}_filtered.pdb";
  $native_file2 = "$native_folder/${target}.pdb";
  if(-e $native_file1)
  {
	$native_file = $native_file1;
  }elsif(-e $native_file2)
  {
	$native_file = $native_file2;
  }else
  {
    print "Failed to find $native_file1\n\n";
    next;
  }
  
  print "Processing $cou:$target\n\n";
  $score_dir = $infolder.'/'.$target;
	
  
  ### 1. check if LGA_score.$target exist
  
  $LGA_file = "$score_dir/ALL_scores/LGA_score.$target";
  
  if(!(-e $LGA_file))
  {
    next;
  }
  
  %LGA_score_list = ();
  open(IN,"$LGA_file") || die "Failed to open file $LGA_file\n";
  $LGA_model_num = 0;
  while(<IN>)
  {
    $line=$_;
    chomp $line;
    if(index($line,'TS')<0)
    {
      next;
    }
    @tmp = split(/\t/,$line);
    $model = $tmp[0];
    $score = $tmp[1];
    $LGA_score_list{$model} = $score;
    $LGA_model_num++;
  }
  close IN;
  
  
  ### 2. check if all methods have generated score for models as LGA
  $incomplete = 0;
  $fea_id=0;
  $title = "LGA";
  foreach $method (@all_features)
  {
      $method_score = "$score_dir/ALL_scores/$method.$target";
      if(!(-e $method_score))
      {
         print "Failed to find $method_score\n";
         print OUT2 "$target incomplete (missing $method_score)\n";
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
        if(index($line,'TS')<0)
        {
          next;
        }
        
        $model_num++;
      }
      close IN; 
      if($model_num!=$LGA_model_num)
      {
         print "The model number in $method_score ($model_num) not match $LGA_file ($LGA_model_num)\n";
         print OUT2 "$target incomplete $method_score ($model_num) not match $LGA_file ($LGA_model_num)\n";
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
        if(index($line,'TS')<0)
        {
          next;
        }
        
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
    next;
  }else
  {
    print "$target is complete\n";
  }
  
  foreach $mod (sort keys %LGA_score_list)
  {
    @tmp = split(/\s/,$LGA_score_list{$mod});
    $cur_fea = @tmp;
    if(@tmp != 35)
    {
      die "Not enough scores ($cur_fea only) for model $mod\n";
    }
    print OUT1 $LGA_score_list{$mod}." #$target:$mod\n";
  }
  
}
close OUT1;
close OUT2;
