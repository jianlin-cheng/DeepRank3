#! /usr/bin/perl -w
=pod
You may freely copy and distribute this document so long as the copyright is left intact. You may freely copy and post unaltered versions of this document in HTML and Postscript formats on a web site or ftp site. Lastly, if you do something injurious or stupid
because of this document, I don't want to know about it. Unless it's amusing.
=cut
 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 use POSIX;
 #use strict; # force disciplined use of variables
 if (@ARGV != 4)
    { # @ARGV used in scalar context = number of args
	  print("This script add chain to all server prediction pdbs, with each subfold for one target.    One input, another script add_chainID_to_pdb.pl, and one output\n");
	  print "\nFor example:\n";
	  print "perl $0 ../data_downloaded_from_CASP/data_server_prediction/casp8_server_prediction add_chainID_to_pdb.pl ../data_downloaded_from_CASP/data_server_prediction/chain_added_casp8_server_prediction\n";

	  exit(0);
	}
 
 my($dir_models)=$ARGV[0];
 my($tool)=$ARGV[1]; #/home/jh7x3/DeepQA_Revision/tools/proq3/run_ProQ3_model.sh
 my($fasta_seq)=$ARGV[2];
 my($output)=$ARGV[3];

 -s $dir_models || die "Cannot open input folder\n";
  -s $tool || die "Cannot open input $tool\n";
  -s $fasta_seq || die "Cannot open input $fasta_seq\n";
 -s $output || system("mkdir $output");
 my($return,$file,$target,$target_path,$path_in,$path_out);
 my(@files,@targets);
 
 
$proq_method_starttime = time();

chdir($output);

open(LOG,">$output/run.log") || die "Failed to open $output/run.log\n";

 $target_path=$dir_models;
 $path_out=$output;
 -s $path_out || system("mkdir $path_out");

my $prepare_file_ss =  $fasta_seq.".ss2";
my $prepare_file_acc =  $fasta_seq.".acc";
my $prepare_file_fasta =  $fasta_seq.".fasta";
my $prepare_file_mtx =  $fasta_seq.".mtx";
my $prepare_file_psi =  $fasta_seq.".psi";

if(-e $prepare_file_ss and -e $prepare_file_acc and -e $prepare_file_fasta and -e $prepare_file_mtx and -e $prepare_file_psi)
{
	print "\n\n---------- found the preparation files for $fasta_seq\n\n";

}else{
	print LOG "\t$tool  -fasta  $fasta_seq  -only-build-profile\n";
	$return = system("$tool  -fasta  $fasta_seq  -only-build-profile");
	if($return)
	{
	 print "$tool  -fasta  $fasta_seq  -only-build-profile fails !\n";
	 exit(0);
	}

}



#### generate parallel list 
opendir(TMPDIR,"$target_path") || die "Failed to open $target_path\n";
@models_array = readdir(TMPDIR);
closedir(TMPDIR);
$model_num=0;
open(LIST,">$output/model.list") || die "Failed to open $output/model.list\n";
%modeprefix2model=();
foreach $mod (@models_array)
{
	chomp $mod;
	if($mod eq '.' or $mod eq '..')
	{
		next;
	}
	#should we check model seq here?
	$model_num++;
	if(index($mod,'.')>0)
	{
		$modelname = substr($mod,0,index($mod,'.pdb'));
	}else{
		$modelname = $mod;
	}
	print LIST "$target_path/$mod\n";
	$modeprefix2model{$modelname} = $mod; # this just for output， in case some model has pdb prefix
}
close LIST;

if($model_num<=20)
{
	$fork_num = 1;
	$batch = $model_num;
}else{
	$fork_num = 3;
	$batch = ceil($model_num/3);
}


`rm $path_out/Proq3D_parallel_*.is_*`;
`rm $path_out/feature_proq*`;

for ($i=1; $i<=$fork_num; $i++) {
	$begin=1+($i-1)*$batch;
	$end=$batch+($i-1)*$batch;
	$indx=$i-1;
    $f1=$path_out."/model_".$indx.".list";
	if(-e $f1)
	{
		`rm $f1`;
	}
	if(-d "$path_out/parallel_$indx")
	{
		`rm $path_out/parallel_$indx/*`;
	}else
	{
		`mkdir $path_out/parallel_$indx`;
	}
	if(-d "$path_out/parallel_out_$indx")
	{
		`rm $path_out/parallel_out_$indx/*`;
	}else
	{
		`mkdir $path_out/parallel_out_$indx`;
	}
    open(IN1, "$output/model.list") or die "Failed to open $output/model.list, $!\n";
    $c=0;
    while ($seq = <IN1>){
		chomp($seq);
		$c++;
		if ($c>=$begin && $c<=$end) {
    		
    		open(OUT1, ">>$f1");
    		print OUT1 "$seq\n";
    		close(OUT1);
			#`cp $prepare_file_ss  $prepare_file_acc  $prepare_file_fasta $prepare_file_mtx  $prepare_file_psi $path_out/parallel_out_$indx`;
			`cp $seq $path_out/parallel_$indx`;
    	}	
    }
    close IN1;
}



$parallel_lists="parallel_0";
for($i=1;$i<$fork_num;$i++)
{
	$parallel_lists .= ",parallel_$i";
	
}

@fork_methods	= split(/,/,$parallel_lists);

$post_process = 0; 
$thread_num = @fork_methods;
%thread_ids = ();
$EXEC_LIMIT_HRS = 60*60*10;#30 hrs
 
#$EXEC_LIMIT_HRS = 60*3;#10 hrs
for ($i = 0; $i < @fork_methods; $i++)
{
	$method = $fork_methods[$i];
	if ( !defined( $kidpid = fork() ) )
	{
		die "can't create process $i to run <$method>\n";
	}
	elsif ($kidpid == 0)
	{
		print "start thread $i\n";
	
		$method_starttime = time();
		
		chdir("$path_out/parallel_out_$i");
		### generate proq3
		$res = "$path_out/Proq3D_parallel_$i.is_running";
		print LOG "\t$tool  -profile  $fasta_seq     $path_out/parallel_$i/* -outpath $path_out/parallel_out_$i -deep yes  -repack no &>> $res\n";
		$return = system("$tool  -profile  $fasta_seq     $path_out/parallel_$i/* -outpath $path_out/parallel_out_$i -deep yes -repack no &>> $res");
		if($return)
		{
		 print "$tool  -profile  $fasta_seq     $path_out/parallel_$i/* -outpath $path_out/parallel_out_$i -deep yes -repack no &>> $res fails !\n";
		 exit(0);
		}
		  
		#ToDo: Check if dfire ran successfully			
		$method_finishtime = time();
		$method_diff_hrs = ($method_finishtime - $method_starttime)/60;
		print "1. proq parallel $i modeling finished within $method_diff_hrs min!\n\n";
		if(-e "$path_out/Proq3D_parallel_$i.is_running")
		{
			system("mv $path_out/Proq3D_parallel_$i.is_running $path_out/Proq3D_parallel_$i.is_finished");
		}
		open(TMP,">>$path_out/Proq3D_parallel_$i.is_finished");
		print TMP "proq parallel $i modeling finished within $method_diff_hrs min!\n\n";
		close TMP;		
		exit 0;
		
	}else{
		$thread_ids[$i] = $kidpid;
		print "The process id of the thread $i is $thread_ids[$i].\n\n";
	}


}


#if ($i == @servers && $post_process == 0)
if ($i == $thread_num && $post_process == 0)
{
	print "The main process starts to wait for the base predictors to finish...\n";
	$post_process = 1;
	$method_finish=0;
	$method_manuallystop = 0;
	%check_fork = ();
	foreach $li (@fork_methods)
	{
		$check_fork{$li} = 1;
	}
	$checktime = time();
	while(1)
	{
	
		$method_finish_num =0;
		for ($j = 0; $j < @fork_methods; $j++)
		{
			$checkfile = "$path_out/Proq3D_parallel_$j.is_finished";
			if(-e $checkfile)
			{
				$method_finish_num ++;
				next;
			}
		}
		if($method_finish_num == @fork_methods)
		{
			$method_finish = 1;
		}
		if($method_finish == 1 or $method_manuallystop == 1)
		{
			
			if($method_manuallystop == 0)
			{
				print "proq method modeling finished!\n";
				$finishtime = time();
				$model_diff_hrs = ($finishtime - $checktime)/60;
				open(STATUS,">>$path_out/Proq3_modelling_status.txt")|| die "Failed to write $path_out/Proq3_modelling_status.txt \n";
				print  "proq method modeling finished! ($model_diff_hrs min)\n";
				print STATUS "proq method modeling finished! ($model_diff_hrs min)\n";
				close STATUS;
				last;
			}else{
				print "proq method modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped!\n";
				$finishtime = time();
				$model_diff_hrs = ($finishtime - $checktime)/60;
				open(STATUS,">>$path_out/Proq3_modelling_status.txt")|| die "Failed to write $path_out/Proq3_modelling_status.txt\n";
				print "proq method modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs min)\n";
				print STATUS "proq method modeling took >$EXEC_LIMIT_HRS hr! Automatically stopped! Ran ($model_diff_hrs min)\n";
				close STATUS;	
				last;
			}
		}
		
		print "\n!!!!!!! Checking method status !!!!!! \n";
		for ($j = 0; $j < @fork_methods; $j++)
		{
			$checkfile = "$path_out/Proq3D_parallel_$j.is_finished";
			if(-e $checkfile)
			{
				print "!!!! detect $checkfile\n";
			}else{
				print "!!!! waiting for $checkfile\n";
			}
		}
		print "\n\n";
		
		
		sleep(2);
		$currenttime = time();
	    $model_check_hrs = ($currenttime - $checktime);
		if($model_check_hrs > $EXEC_LIMIT_HRS)
		#if($model_check_hrs > 60*3)
		{
			for ($k = 0; $k < @fork_methods; $k++)
			{
				$method = $fork_methods[$k];
				$kidpid = $thread_ids[$k];
				print "<$method> has ran more than $EXEC_LIMIT_HRS hr, skip it and kill process $kidpid !\n";
				
				$method_manuallystop = 1;
				
			}
			
		}	
		sleep(60*5);
	}
}


print "\n!!!!!!! Checking method status !!!!!! \n";
for ($j = 0; $j < @fork_methods; $j++)
{
	$checkfile = "$path_out/Proq3D_parallel_$j.is_finished";
	if(-e $checkfile)
	{
		print "!!!! detect $checkfile\n";
	}else{
		print "!!!! waiting for $checkfile\n";
	}
}
print "\n\n";
### summarize the parallel 
if(-d "$path_out/proq_out")
{
	`rm $path_out/proq_out/*`;
}else{
	`mkdir $path_out/proq_out`;
}
`cp $path_out/parallel_out_*/*  $path_out/proq_out`;


=pod
### generate proq3d
print LOG "\t$tool  -profile  $fasta_seq     $target_path/* -outpath $path_out  -deep yes\n";
$return = system("$tool  -profile  $fasta_seq     $target_path/* -outpath $path_out  -deep yes");
if($return)
{
 print "$tool  -profile  $fasta_seq     $target_path/* -outpath $path_out  -deep yes fails !\n";
 exit(0);
}
=cut


#### processing the results

$outfolder_score1 = $path_out.'/feature_proq2D_global.txt';
$outfolder_score2 = $path_out.'/feature_proq3D_global.txt';
$outfolder_score3 = $path_out.'/feature_proq3D_ProQRosCenD_global.txt';
$outfolder_score4 = $path_out.'/feature_proq3D_ProQRosFAD_global.txt';


open(PROQ2,">$outfolder_score1") || die "Failed to open file $outfolder_score1\n";
open(PROQ3,">$outfolder_score2") || die "Failed to open file $outfolder_score2\n";
open(PROQ3LOW,">$outfolder_score3") || die "Failed to open file $outfolder_score3\n";
open(PROQ3HIGH,">$outfolder_score4") || die "Failed to open file $outfolder_score4\n";


%proq2d_hash=();
%proq3d_hash=();
%proq3d_ProQRosCenD_hash=();
%proq3d_ProQRosFAD_hash=();
opendir(DIR,"$path_out/proq_out") || die "Failed to open dir $path_out/proq_out\n";
@proqfiles = readdir(DIR);
closedir(DIR); 

## process the global score 
foreach $file (@proqfiles)
{
	chomp $file;
	if($file eq '.' or $file eq '..')
	{
		next;
	}
	if(index($file,'proq3.global') <0)
	{
		next;
	}
	
	$modelname = substr($file,0,index($file,'.'));
	
	$scorefile = "$path_out/proq_out/$modelname.pdb.proq3.global";
	if(!(-e $scorefile))
	{
		die "couldn't find $scorefile\n";
	}else{
		#print "parse file $scorefile\n";
	}
	open(TMP,"$scorefile") || die "Failed to open file $scorefile\n";
	@content = <TMP>;
	close TMP;
	shift @content;
	$line = shift @content;
	chomp $line;
	@tmp2 = split(/\s/,$line); #ProQ2D ProQRosCenD ProQRosFAD ProQ3D
	$proq2D = $tmp2[0];
	$proq3D_ProQRosCenD = $tmp2[1];
	$proq3D_ProQRosFAD = $tmp2[2];
	$proq3D = $tmp2[3];


	#if($proq2D==0 and $proq3D==0)
	#{
	#  print "$scorefile has strange score, check it\n";
	#  next;
	#}

	if(exists($proq2d_hash{$modelname}))
	{
	  die "duplicate $modelname in $dir_models\n";
	}else{
	  $proq2d_hash{$modelname} = $proq2D;
	}

	if(exists($proq3d_hash{$modelname}))
	{
	  die "duplicate $modelname in $dir_models\n";
	}else{
	  $proq3d_hash{$modelname} = $proq3D;
	}

	if(exists($proq3d_ProQRosCenD_hash{$modelname}))
	{
	  die "duplicate $modelname in $dir_models\n";
	}else{
	  $proq3d_ProQRosCenD_hash{$modelname} = $proq3D_ProQRosCenD;
	}

	if(exists($proq3d_ProQRosFAD_hash{$modelname}))
	{
	  die "duplicate $modelname in $dir_models\n";
	}else{
	  $proq3d_ProQRosFAD_hash{$modelname} = $proq3D_ProQRosFAD;
	}
	
	if(exists($modeprefix2model{$modelname}))
	{
		$modelname=$modeprefix2model{$modelname};
	}else{
		print "Failed to find $modelname in modeprefix2model\n\n";
		next;
	}
	print PROQ2 "$modelname\t$proq2D\n";
	print PROQ3 "$modelname\t$proq3D\n";
	print PROQ3LOW "$modelname\t$proq3D_ProQRosCenD\n";
	print PROQ3HIGH "$modelname\t$proq3D_ProQRosFAD\n";
	
	
}

close PROQ2;
close PROQ3;
close PROQ3LOW;
close PROQ3HIGH;



print "$outfolder_score1 generated!\n";
print "$outfolder_score2 generated!\n";
print "$outfolder_score3 generated!\n";
print "$outfolder_score4 generated!\n\n";


## process the local score 

=pod
$outfolder_score1 = $path_out.'/feature_proq2D_local.txt';
$outfolder_score2 = $path_out.'/feature_proq3D_local.txt';
$outfolder_score3 = $path_out.'/feature_proq3D_ProQRosCenD_local.txt';
$outfolder_score4 = $path_out.'/feature_proq3D_ProQRosFAD_local.txt';

open(PROQ2,">$outfolder_score1") || die "Failed to open file $outfolder_score1\n";
open(PROQ3,">$outfolder_score2") || die "Failed to open file $outfolder_score2\n";
open(PROQ3LOW,">$outfolder_score3") || die "Failed to open file $outfolder_score3\n";
open(PROQ3HIGH,">$outfolder_score4") || die "Failed to open file $outfolder_score4\n";

foreach $file (@proqfiles)
{
	chomp $file;
	if($file eq '.' or $file eq '..')
	{
		next;
	}
	if(index($file,'proq3.local') <0)
	{
		next;
	}
	
	$modelname = substr($file,0,index($file,'.'));
	
	$scorefile = "$path_out/proq_out/$modelname.pdb.proq3.local";
	if(!(-e $scorefile))
	{
		die "couldn't find $scorefile\n";
	}else{
		#print "parse file $scorefile\n";
	}
	open(TMP,"$scorefile") || die "Failed to open file $scorefile\n";
	@content = <TMP>;
	close TMP;
	shift @content;

	$proq2D_local = "";
	$proq3D_ProQRosCenD_local = "";
	$proq3D_ProQRosFAD_local = "";
	$proq3D_local = "";
	foreach $line (@content)
	{
		chomp $line;
		@tmp2 = split(/\s/,$line); #ProQ2D ProQRosCenD ProQRosFAD ProQ3D
		  if($tmp2[0] > 1)
		  {
			$tmp2[0] = 1;
		  }
		  if($tmp2[1] > 1)
		  {
			$tmp2[1] = 1;
		  }
		  if($tmp2[2] > 1)
		  {
			$tmp2[2] = 1;
		  }
		  if($tmp2[3] > 1)
		  {
			$tmp2[3] = 1;
		  }
		  
		  if($tmp2[0] <0)
		  {
			$tmp2[0] = 0.1;
		  }
		  if($tmp2[0] <0)
		  {
			$tmp2[0] = 0.1;
		  }
		  if($tmp2[1] <0)
		  {
			$tmp2[1] = 0.1;
		  }
		  if($tmp2[2] <0)
		  {
			$tmp2[2] = 0.1;
		  }
		  if($tmp2[3] <0)
		  {
			$tmp2[3] = 0.1;
		  }
		  $proq2D_score_convert = 3* sqrt((1-$tmp2[0])/$tmp2[0]);
		  $proq3D_ProQRosCenD_score_convert = 3*  sqrt((1-$tmp2[1])/$tmp2[1]);
		  $proq3D_ProQRosFAD_convert = 3*  sqrt((1-$tmp2[2])/$tmp2[2]);
		  $proq3D_score_convert = 3*  sqrt((1-$tmp2[3])/$tmp2[3]);
		  
		  if($proq2D_score_convert>15)
		  {
			$proq2D_score_convert=15;
		  }
		  if($proq2D_score_convert<0)
		  {
			$proq2D_score_convert=0;
		  }
		  
		  if($proq3D_ProQRosCenD_score_convert>15)
		  {
			$proq3D_ProQRosCenD_score_convert=15;
		  }
		  if($proq3D_ProQRosCenD_score_convert<0)
		  {
			$proq3D_ProQRosCenD_score_convert=0;
		  }
		  
		  if($proq3D_ProQRosFAD_convert>15)
		  {
			$proq3D_ProQRosFAD_convert=15;
		  }
		  if($proq3D_ProQRosFAD_convert<0)
		  {
			$proq3D_ProQRosFAD_convert=0;
		  }
		  
		  if($proq3D_score_convert>15)
		  {
			$proq3D_score_convert=15;
		  }
		  if($proq3D_score_convert<0)
		  {
			$proq3D_score_convert=0;
		  }
	  
		$proq2D_local .= " ".$proq2D_score_convert;
		$proq3D_ProQRosCenD_local .= " ".$proq3D_ProQRosCenD_score_convert;
		$proq3D_ProQRosFAD_local.= " ".$proq3D_ProQRosFAD_convert;
		$proq3D_local .= " ".$proq3D_score_convert;
	}

	 
	if(exists($proq2d_hash{$modelname}))
	{
	  $proq2d_hash{$modelname} .= $proq2D_local;
	  
	}else{
	  die "no global score for $modelname in $dir_models\n";
	}

	if(exists($proq3d_hash{$modelname}))
	{
	  $proq3d_hash{$modelname} .= $proq3D_local;
	}else{
	  die "no global score for $modelname in $dir_models\n";
	}

	if(exists($proq3d_ProQRosCenD_hash{$modelname}))
	{
	  $proq3d_ProQRosCenD_hash{$modelname} .= $proq3D_ProQRosCenD_local;
	}else{
	  die "no global score for $modelname in $dir_models\n";
	}

	if(exists($proq3d_ProQRosFAD_hash{$modelname}))
	{
	  $proq3d_ProQRosFAD_hash{$modelname} .= $proq3D_ProQRosFAD_local;
	}else{
	  die "no global score for $modelname in $dir_models\n";
	}
  
	print PROQ2 "$proq2D_local\n";
	print PROQ3 "$proq3D_local\n";
	print PROQ3LOW "$proq3D_ProQRosCenD_local\n";
	print PROQ3HIGH "$proq3D_ProQRosFAD_local\n";

}



close PROQ2;
close PROQ3;
close PROQ3LOW;
close PROQ3HIGH;


print "$outfolder_score1 generated!\n";
print "$outfolder_score2 generated!\n";
print "$outfolder_score3 generated!\n";
print "$outfolder_score4 generated!\n\n";

### output format 

$outfolder_score1 = $path_out.'/feature_proq2D_local_global.txt';
$outfolder_score2 = $path_out.'/feature_proq3D_local_global.txt';
$outfolder_score3 = $path_out.'/feature_proq3D_ProQRosCenD_local_global.txt';
$outfolder_score4 = $path_out.'/feature_proq3D_ProQRosFAD_local_global.txt';

open(PROQ2,">$outfolder_score1") || die "Failed to open file $outfolder_score1\n";
open(PROQ3,">$outfolder_score2") || die "Failed to open file $outfolder_score2\n";
open(PROQ3LOW,">$outfolder_score3") || die "Failed to open file $outfolder_score3\n";
open(PROQ3HIGH,">$outfolder_score4") || die "Failed to open file $outfolder_score4\n";

foreach $mod (keys %proq2d_hash)
{
	if(exists($modeprefix2model{$mod}))
	{
		$mod=$modeprefix2model{$mod};
		print PROQ2 "$mod ".$proq2d_hash{$mod}."\n";
	}else{
		print "Failed to find $mod in modeprefix2model\n\n";
	}

}

foreach $mod (keys %proq3d_hash)
{
	if(exists($modeprefix2model{$mod}))
	{
		$mod=$modeprefix2model{$mod};
		print PROQ3 "$mod ".$proq3d_hash{$mod}."\n";
	}else{
		print "Failed to find $mod in modeprefix2model\n\n";
	}

}

foreach $mod (keys %proq3d_ProQRosCenD_hash)
{
	if(exists($modeprefix2model{$mod}))
	{
		$mod=$modeprefix2model{$mod};
		print PROQ3LOW "$mod ".$proq3d_ProQRosCenD_hash{$mod}."\n";
	}else{
		print "Failed to find $mod in modeprefix2model\n\n";
	}

}

foreach $mod (keys %proq3d_ProQRosFAD_hash)
{
	if(exists($modeprefix2model{$mod}))
	{
		$mod=$modeprefix2model{$mod};
		print PROQ3HIGH "$mod ".$proq3d_ProQRosFAD_hash{$mod}."\n";
	}else{
		print "Failed to find $mod in modeprefix2model\n\n";
	}

}

close PROQ2;
close PROQ3;
close PROQ3LOW;
close PROQ3HIGH;
 
close LOG;


print "$outfolder_score1 generated!\n";
print "$outfolder_score2 generated!\n";
print "$outfolder_score3 generated!\n";
print "$outfolder_score4 generated!\n\n";
=cut

print "Clearning .....\n";
chdir($output);
`rm -rf parallel_*`;
`rm -rf model_*.list`;
`tar -zcf proq_out.tar.gz proq_out`;
`rm -rf proq_out`;

#ToDo: Check if dfire ran successfully			
$proq_method_finishtime = time();
$method_diff_hrs = ($proq_method_finishtime - $proq_method_starttime)/3600;
print "1. proq3D parallel $i modeling finished within $method_diff_hrs hr!\n\n";