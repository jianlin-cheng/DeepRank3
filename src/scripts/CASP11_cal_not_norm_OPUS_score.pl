##########################################################################################################
#                  Function about calculating the OPUS_PSP score                          				 #
#																										 #
#										Renzhi Cao  													 #
#																										 #
#									    3/12/2013														 #
#																										 #
#																										 #
#									Revised at 3/12/2013	                         					 #
#																										 #
##########################################################################################################
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
 use Cwd 'abs_path'; 
 sub create_list($$);
 sub process_output($$@);
  if (@ARGV != 3)
    { # @ARGV used in scalar context = number of args
	  print("This script tries to calculate OPUS_PSP score for all models, the input folder has the subfolders with the target name\n");
      print("This script only for benchmarking the normalization of OPUS_PSP score. \nHere we should use absolute path for each model, since calculating the score needs absolute path\n");
          print "Revised at 10/16/2012, the OPUS_PSP score should be 1000000 in default here, maybe this will improve the performance!\n";
     print "!!!!!!!!!!!!Attention, you have to use absolute path! And we can only use the version in sysbio server\n";

	  print("You should execute the perl program like this: perl $PROGRAM_NAME dir_OPUS_PSP(with the file opus_psp inside this folder) dir_input_target_model addr_output\n");
      print("\n********** example******\n");

#	  print("perl $PROGRAM_NAME /rose/space1/rcrg4/tool/OPUS/OPUS_PSP /rose/space1/renzhi/evaluation_for_CASP/test/casp8_all_scores/scwrl_processed_models_casp8 /rose/space1/renzhi/evaluation_for_CASP/QA_score_casp8/not_normed_OPUS_score\n");
#  	  print "perl $PROGRAM_NAME /rose/space1/rcrg4/tool/OPUS/OPUS_PSP /rose/space1/renzhi/evaluation_for_CASP/test/casp9_all_scores/casp9_scwrl_processed_models /rose/space1/renzhi/evaluation_for_CASP/QA_score_casp9/not_normed_OPUS_score\n";
          print "perl $0 /home/rcrg4/tools/OPUS/OPUS_PSP /home/rcrg4/Server/test/T0648-149804384417881-eva-data/filtered-T0648 /home/rcrg4/Server/test/T0648-149804384417881-eva-data/not_normed_OPUS_score\n";
	  exit(1) ;
    }
 my $starttime = localtime();
 print "\n The time started at : $starttime.\n";
 my($dir_exe)=$ARGV[0];

 my($input_pdb)=$ARGV[1];
 my($addr_output)=$ARGV[2];
 my($output_dir)=$addr_output."_tmp";

##########################################################################################################
#              Function about openning a directory and processing the files                				 #
#																										 #
#										Renzhi Cao  													 #
#																										 #
#									    12/27/2011														 #
#																										 #
##########################################################################################################
if(!-s $output_dir)
{
	system("mkdir $output_dir");
}
-s $input_pdb || die "no input folder: $input_pdb!\n";
opendir(DIR, "$input_pdb");
my($NUM);
my($IN,$OUT);
my($path_name,$path_matrix);
my($line);
my(@tem_split,@tem2);
my(@names,@DFIRE_score_all,@tree_count,@for_rank);
my($index_name,$index_dope);
my($i,$j,$key,$key_rank);
my($the_name);
my($file_name);
my($tem_path,$read_folder2,$read_folder_a,$read_path);
my($write_name,$write_tree);
my(@targets);
my($target,$target_name);
my($count)=0;
my($return_val,$i);
my(@missing_folder)=();
my($missing_index)=0;
my(@score_appollo)=();
my(@names_list);
my($index_score,$sum,$i_sum);
my($work_dir);
my($rwplus_score_ret,$rwplus_score,$list_path);
my($dope_score);
my($min,$max);
my($exe)=$dir_exe."/"."opus_psp";

my($out_tem) = $output_dir."/"."TEM";
system("mkdir $out_tem");
my($opus_config,$opus_exe);

my(%hash); # this hash table tries to score the model name and the energy score

#my @files = readdir(DIR);
#foreach my $file (@files)
#{
#	if($file eq '.' || $file eq '..')
#	{
#		next;
#	}
##########do something to the file###################
    my($file) = $input_pdb;
print "Processing $file...\n";
    $write_tree = $addr_output;
    $write_tree = abs_path($write_tree);
    #$write_tree=$output_dir."/".$file.".OPUS_PSP_score";
	
    $read_folder2=$input_pdb;  # read the models inside
    $list_path=$out_tem."/"."tem.list";
    $tem_path=$out_tem."/"."tem.TEM";
    @names_list=();                                      # the name list
    @names_list=create_list($read_folder2,$list_path);
    system("cp $input_pdb/* $out_tem/");
#print "Get name list @names_list\n";
    chdir("$out_tem");
    #### copy and add the opus exe and config file #####
    #
       $opus_exe = $out_tem."/"."opus_psp";
       system("cp $exe $opus_exe");
       $opus_config = $out_tem."/"."config.psp";
       $OUT = new FileHandle ">$opus_config";
       print $OUT $dir_exe."/"."energy_dir/";
       $OUT->close();
    #
    ####################################################
    
	$return_val=system("./opus_psp < $list_path > $tem_path");
        if($return_val !=0)
	{
		print "./opus_psp < $list_path > $tem_path fails\n";
                system("rm $opus_config");
                system("rm $opus_exe");
		exit(0);
	}
#die;   
    #### remove the opus exe and config file ###########
    #
        system("rm $opus_config");
        system("rm $opus_exe");
    #
    ####################################################
	process_output($tem_path,$write_tree,@names_list);

    system("rm $tem_path");
    system("rm $list_path");
    system("rm -R $output_dir");
 
#}#end foreach outside
 sub process_output($$@)
 {
	 my($tem_input,$output,@name_lists)=@_;
	 my($IN,$OUT,$line);
	 my(@tem_split);


#print "Get namelist: @name_lists\n";

	 $OUT=new FileHandle ">$output";
	 defined($OUT) || die "cannot open $output\n";
	 $IN=new FileHandle "$tem_input";
	 my($index)=0;
	 my($start)=0;
	 defined($IN) || die "cannot open $tem_input\n";
	 while(defined($line=<$IN>))
	 {
		 chomp($line);
		 $line=~s/\s+$//;
		 if(substr($line,0,5) eq "Input")
		 {
			 $start=1;
			 next;
		 }
		 if($start == 0)
		 {
			 next;
		 }
         @tem_split=split(/\s+/,$line);
		 if(@tem_split!=5)
		 {# this is head information
			 print "skip head : $line\n";
			 next;
		 }
		 print $OUT $tem_split[1]."\t".$tem_split[2]."\n";
		 $index++;
	 }
     $OUT->close();
	 $IN->close();
 }
 sub create_list($$)
 {
	 my($folder,$out)=@_;
     my($OUT,$path);
	 $OUT=new FileHandle ">$out";
	 my(@name_lists)=();
	 my($index)=0;
	 defined($OUT) || die "Cannot open output $out\n";

     opendir(DIR, "$folder");
     my(@targets) = readdir(DIR);
     foreach my $target (@targets)
     {
	    if($target eq '.' || $target eq '..')
	    {
		    next;
	    }
		$path=$folder."/".$target;
		$name_lists[$index]=$target;
		$index++;
		print $OUT $target."\n";
	}
	$OUT->close();
	return @name_lists;
 }



 my $endtime = localtime();
 print  "\nThe time ended at : $endtime.\n";
