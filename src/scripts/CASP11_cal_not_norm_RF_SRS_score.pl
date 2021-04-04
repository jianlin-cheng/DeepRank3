##########################################################################################################
#                  Function about calculating the RF_SRS score                          				 #
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
  if (@ARGV != 4)
    { # @ARGV used in scalar context = number of args
		print "For CASP11\n";

	  print("This script tries to calculate RF_SRS score for all models, the input folder has the subfolders with the target name\n");
      print("This script only for benchmarking the normalization of RF_SRS score. \nHere we should use absolute path for each model, since calculating the score needs absolute path\n");
          print "Revised at 10/16/2012, the RF_SRS score should be 1000000 in default here, maybe this will improve the performance!\n";
	  print "\n*********************\nThe RF_SRS has two different potential file, RF_HA_SRS and RF_CB_SRS_OD\n***************\n";

	  print("You should execute the perl program like this: perl $PROGRAM_NAME exe_calc_energy addr_potential_file dir_input_target_model addr_output\n");
      print("\n********** example******\n");
      print "perl $0 /home/rcrg4/tool/Energy_function_RF_SRS/calc_energy /home/rcrg4/tool/Energy_function_RF_SRS/RF_CB_SRS_OD ../../test/test_target_prediction/T0516_test ../../test/test_RF_SRS_T0516\n";

  	  exit(1) ;
    }
 my $starttime = localtime();
 print "\n The time started at : $starttime.\n";
 my($exe)=$ARGV[0];
 my($addr_potential)=$ARGV[1];
 my($input_pdb)=$ARGV[2];
 my($addr_output)=$ARGV[3];
##########################################################################################################
#              Function about openning a directory and processing the files                				 #
#																										 #
#										Renzhi Cao  													 #
#																										 #
#									    12/27/2011														 #
#																										 #
##########################################################################################################

-s $input_pdb || die "no input folder: $input_pdb!\n";

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
my($read_folder,$read_folder2,$read_folder_a,$read_path);
my($write_name,$write_tree);
my(@targets);
my($target,$target_name);
my($count)=0;
my($return_val,$i);
my(@missing_folder)=();
my($missing_index)=0;
my(@score_appollo)=();
my($index_score,$sum,$i_sum);
my($work_dir);
my($rwplus_score_ret,$rwplus_score);
my($dope_score);
my($min,$max);
my(%hash); # this hash table tries to score the model name and the prediction score



	@DFIRE_score_all=(); # initialization
	@names=();
    $index_name=0;    # index for the total number of models

    opendir(DIR, "$input_pdb");
    @targets = readdir(DIR);
    foreach my $target (@targets)
    {
	    if($target eq '.' || $target eq '..')
	    {
		    next;
	    }    
        $read_path=$input_pdb."/".$target;  # name for this model
print "Process $read_path...\n";
########### calculate RWplus score #######################
         
         
         $write_tree=$addr_output."_tmp_RF_SRS";
         open (File, "&gt;$write_tree");
         chmod (0777, $write_tree);
         close (File);
         #Execute RWplus to calculate the potential energy of each model
         $rwplus_score_ret = system("$exe $read_path $addr_potential > $write_tree");
         if ($rwplus_score_ret != 0)
         {
              print "Fail to excute ./$exe $read_path $addr_potential > $write_tree \n";
              #CleanUp();
              #die "failed to execute RWplus.\n";
         }
         $rwplus_score=1000000;  #initialize
         open(RWPLUS_CHECK, "$write_tree") || print "Can't open energy output file $write_tree.\n";
         while(<RWPLUS_CHECK>)
         {
              $line = $_;
              $line =~ s/\n//;
			  @tem_split=split(/\s+/,$line);

			  if(@tem_split>1)
			  {
				  next;
			  }
			  $rwplus_score=$line;
         }
         close RWPLUS_CHECK;
         `rm $write_tree`;
##########################################################
        $names[$index_name]=$target;
        $DFIRE_score_all[$index_name]=$rwplus_score;
		$index_name++;

	}#end of inside foreach
    #if($index_name<2)
	#{
	#	print "Only $index_name models???\n";
	#	exit(0);
	#}

#################  save the score result #################
    $write_tree=$addr_output;
    if(-e $write_tree)
	{
	     print "the result file | : $write_tree  ...Exists!\n"; 
	}
    else
	{ 
	     open (File, "&gt;$write_tree");
	     chmod (0777, $write_tree); 
         close (File);
    }
    $OUT = new FileHandle "> $write_tree";
    if (! defined($OUT) ) 
    {
       croak "Unable to open output file: $write_tree. Bye-bye.";
       exit(1);
    }
    for($i=0;$i<$index_name;$i++)
	{
		print $OUT $names[$i]."\t".$DFIRE_score_all[$i]."\n";
	}
	$OUT->close();


 my $endtime = localtime();
 print  "\nThe time ended at : $endtime.\n";
