#! /usr/bin/perl -w
=pod
You may freely copy and distribute this document so long as the copyright is left intact. You may freely copy and post unaltered versions of this document in HTML and Postscript formats on a web site or ftp site. Lastly, if you do something injurious or stupid
because of this document, I don't want to know about it. Unless it's amusing.
=cut
 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
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

### generate proq3d
print LOG "\t$tool  -profile  $fasta_seq     $target_path/* -outpath $path_out  -deep yes\n";
$return = system("$tool  -profile  $fasta_seq     $target_path/* -outpath $path_out  -deep yes");
if($return)
{
 print "$tool  -profile  $fasta_seq     $target_path/* -outpath $path_out  -deep yes fails !\n";
 exit(0);
}


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
opendir(DIR,$path_out) || die "Failed to open dir $path_out\n";
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
	if(index($file,'proq3.sscore.global') <0)
	{
		next;
	}
	
	$modelname = substr($file,0,index($file,'.'));
	
	$scorefile = "$path_out/$modelname.pdb.proq3.sscore.global";
	if(!(-e $scorefile))
	{
		die "couldn't find $scorefile\n";
	}else{
		print "parse file $scorefile\n";
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
	  die "duplicate $modelname in $target_dir\n";
	}else{
	  $proq2d_hash{$modelname} = $proq2D;
	}

	if(exists($proq3d_hash{$modelname}))
	{
	  die "duplicate $modelname in $target_dir\n";
	}else{
	  $proq3d_hash{$modelname} = $proq3D;
	}

	if(exists($proq3d_ProQRosCenD_hash{$modelname}))
	{
	  die "duplicate $modelname in $target_dir\n";
	}else{
	  $proq3d_ProQRosCenD_hash{$modelname} = $proq3D_ProQRosCenD;
	}

	if(exists($proq3d_ProQRosFAD_hash{$modelname}))
	{
	  die "duplicate $modelname in $target_dir\n";
	}else{
	  $proq3d_ProQRosFAD_hash{$modelname} = $proq3D_ProQRosFAD;
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

## process the local score 


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
	if(index($file,'proq3.sscore.local') <0)
	{
		next;
	}
	
	$modelname = substr($file,0,index($file,'.'));
	
	$scorefile = "$path_out/$modelname.pdb.proq3.sscore.local";
	if(!(-e $scorefile))
	{
		die "couldn't find $scorefile\n";
	}else{
		print "parse file $scorefile\n";
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
	  die "no global score for $modelname in $target_dir\n";
	}

	if(exists($proq3d_hash{$modelname}))
	{
	  $proq3d_hash{$modelname} .= $proq3D_local;
	}else{
	  die "no global score for $modelname in $target_dir\n";
	}

	if(exists($proq3d_ProQRosCenD_hash{$modelname}))
	{
	  $proq3d_ProQRosCenD_hash{$modelname} .= $proq3D_ProQRosCenD_local;
	}else{
	  die "no global score for $modelname in $target_dir\n";
	}

	if(exists($proq3d_ProQRosFAD_hash{$modelname}))
	{
	  $proq3d_ProQRosFAD_hash{$modelname} .= $proq3D_ProQRosFAD_local;
	}else{
	  die "no global score for $modelname in $target_dir\n";
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
print PROQ2 "$mod ".$proq2d_hash{$mod}."\n";
}

foreach $mod (keys %proq3d_hash)
{
print PROQ3 "$mod ".$proq3d_hash{$mod}."\n";
}

foreach $mod (keys %proq3d_ProQRosCenD_hash)
{
print PROQ3LOW "$mod ".$proq3d_ProQRosCenD_hash{$mod}."\n";
}

foreach $mod (keys %proq3d_ProQRosFAD_hash)
{
print PROQ3HIGH "$mod ".$proq3d_ProQRosFAD_hash{$mod}."\n";
}

close PROQ2;
close PROQ3;
close PROQ3LOW;
close PROQ3HIGH;
 
close LOG;
