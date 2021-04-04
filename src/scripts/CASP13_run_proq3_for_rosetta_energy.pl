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

### generate proq3
print LOG "\t$tool  -profile  $fasta_seq     $target_path/* -outpath $path_out -deep no\n";
$return = system("$tool  -profile  $fasta_seq     $target_path/* -outpath $path_out -deep no");
if($return)
{
 print "$tool  -profile  $fasta_seq     $target_path/* -outpath $path_out  -deep yes fails !\n";
 exit(0);
}


#### processing the results

$outfolder_score1 = $path_out.'/feature_proq2_global.txt';
$outfolder_score2 = $path_out.'/feature_proq3_global.txt';
$outfolder_score3 = $path_out.'/feature_proq3_ProQRosCenD_global.txt';
$outfolder_score4 = $path_out.'/feature_proq3_ProQRosFAD_global.txt';


open(PROQ2,">$outfolder_score1") || die "Failed to open file $outfolder_score1\n";
open(PROQ3,">$outfolder_score2") || die "Failed to open file $outfolder_score2\n";
open(PROQ3LOW,">$outfolder_score3") || die "Failed to open file $outfolder_score3\n";
open(PROQ3HIGH,">$outfolder_score4") || die "Failed to open file $outfolder_score4\n";


#%proq2_hash=();
#%proq3_hash=();
#%proq3_ProQRosCenD_hash=();
#%proq3_ProQRosFAD_hash=();
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
	$proq2 = $tmp2[0];
	$proq3_ProQRosCenD = $tmp2[1];
	$proq3_ProQRosFAD = $tmp2[2];
	$proq3 = $tmp2[3];


	#if($proq2==0 and $proq3==0)
	#{
	#  print "$scorefile has strange score, check it\n";
	#  next;
	#}

	if(exists($proq2d_hash{$modelname}))
	{
	  die "duplicate $modelname in $target_dir\n";
	}else{
	  $proq2d_hash{$modelname} = $proq2;
	}

	if(exists($proq3d_hash{$modelname}))
	{
	  die "duplicate $modelname in $target_dir\n";
	}else{
	  $proq3d_hash{$modelname} = $proq3;
	}

	if(exists($proq3d_ProQRosCenD_hash{$modelname}))
	{
	  die "duplicate $modelname in $target_dir\n";
	}else{
	  $proq3d_ProQRosCenD_hash{$modelname} = $proq3_ProQRosCenD;
	}

	if(exists($proq3d_ProQRosFAD_hash{$modelname}))
	{
	  die "duplicate $modelname in $target_dir\n";
	}else{
	  $proq3d_ProQRosFAD_hash{$modelname} = $proq3_ProQRosFAD;
	}
	
	print PROQ2 "$modelname\t$proq2\n";
	print PROQ3 "$modelname\t$proq3\n";
	print PROQ3LOW "$modelname\t$proq3_ProQRosCenD\n";
	print PROQ3HIGH "$modelname\t$proq3_ProQRosFAD\n";
	
	
}

close PROQ2;
close PROQ3;
close PROQ3LOW;
close PROQ3HIGH;
