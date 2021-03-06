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
 use Cwd;
 use Cwd 'abs_path';
  if (@ARGV != 2)
    { # @ARGV used in scalar context = number of args
	  print "For CASP11\n";
	  print("Need modeller!\n");
	  print("This script tries to calculate the dope score for all models, two input parameters, one is the input folder, and one output file!\n");
      print("Use dope score, convert the range to [0,1]. \nHere we should use absolute path for each model, since calculating the score needs absolute path\n");
	  print("You should execute the perl program like this: perl $PROGRAM_NAME  dir_input_target_model addr_output\n");
      print("\n********** example******\n");
#	  print("perl $PROGRAM_NAME /rose/space1/renzhi/evaluation_for_CASP/new_all_casp10_predictions_stage1 /rose/space1/renzhi/evaluation_for_CASP/test/all_casp10_dope_score_stage1\n");
#	  print("perl $PROGRAM_NAME /rose/space1/renzhi/evaluation_for_CASP/new_all_casp10_predictions_stage2 /rose/space1/renzhi/evaluation_for_CASP/test/all_casp10_dope_score_stage2\n");
      
	  print "perl $0 /home/rcrg4/test/test_target_prediction/T0516 /home/rcrg4/test/test_dope_prediction/T0516.DOPE_SCORE\n";
	  exit(1) ;
    }
 my $starttime = localtime();
 print "\n The time started at : $starttime.\n";
 my($input_dir)=abs_path($ARGV[0]);
 my($addr_output)=abs_path($ARGV[1]);

 ############### modeller is needed, so add this part ############
 #$ENV{'PATH'}.=':/home/jianliu/DeepRank3/tools/modeller-9.15/bin';
 $ENV{'PATH'}.=':/home/jianliu/DeepRank3/tools/modeller-9.16/bin';
 #$ENV{'LD_LIBRARY_PATH'}.=':/home/jianliu/DeepRank3/tools/modeller-9.15/lib/x86_64-intel8';
 $ENV{'LD_LIBRARY_PATH'}.=':/home/jianliu/DeepRank3/tools/modeller-9.16/lib/x86_64-intel8';
 #################################################################

##########################################################################################################
#              Function about openning a directory and processing the files                				 #
#																										 #
#										Renzhi Cao  													 #
#																										 #
#									    12/27/2011														 #
#																										 #
##########################################################################################################

my($NUM);
my($IN,$OUT);
my($path_name,$path_matrix);
my($line);
my(@tem_split,@tem2);
my(@names,@dope_score_all,@tree_count,@for_rank);
my($index_name,$index_dope);
my($i,$j,$key,$key_rank);
my($the_name);
my($file_name);
my($read_folder,$read_folder2,$read_folder_a,$read_path);
my($write_name,$write_tree);
my(@targets);
my($target,$target_name);
my($count)=0;
my($return_val);
my(@missing_folder)=();
my($missing_index)=0;
my(@score_appollo)=();
my($index_score);
my($work_dir);
my($dope_script,$pycommand);
my($dope_score);
my($min,$max);
my(%hash); # this hash table tries to score the model name and the prediction score

##########do something to the file###################


	@dope_score_all=();
	@names=();
	$index_name=0;
    opendir(DIR, "$input_dir");
    @targets = readdir(DIR);
    foreach my $target (@targets)
    {
	    if($target eq '.' || $target eq '..')
	    {
		    next;
	    }    
        $read_path=$input_dir."/".$target;  # name for this model
print "Process $read_path...\n";
        $work_dir=$addr_output."_tmp_folder";
		-s $work_dir || system("mkdir $work_dir");

        chdir($work_dir) || die "can't change to directly $work_dir\n";
        $dope_script = "assess_dope.py";
        # Removes the python script file if exists
        if ( -f $dope_script)
        {
           `rm -f $work_dir/$dope_script`;
        }

#print "We are at $work_dir, and we want to write a script there, $dope_script!\n";
#exit(0);


        open(PY,">$dope_script") || die "can't write the script $dope_script!\n";
        print PY "from modeller import *    # Load standard Modeller classes\n";
        print PY "from modeller.scripts import complete_pdb    # Load the complete_pdb class"."\n";
        print PY "\n";
        print PY "env = environ()\n";
        print PY "env.libs.topology.read(file='\$(LIB)/top_heav.lib')\n";
        print PY "env.libs.parameters.read(file='\$(LIB)/par.lib')\n";
        print PY "\n";
        print PY "mdl = complete_pdb(env,'$read_path')\n";
        print PY "atmsel = selection(mdl.chains[0])     # Select all atoms in the first chain\n";
        print PY "atmsel = selection(mdl.chains[0])\n";
        print PY "score = atmsel.assess_dope()\n";
        close(PY);
        #$pycommand = "mod9.15 ".$dope_script;
        $pycommand = "mod9.16 ".$dope_script;
        system("$pycommand > /dev/null 2>&1");

#print "Running $pycommand, now search for $work_dir/assess_dope.log!\n";
#exit(0);
        

        open(DOPE_CHECK, "$work_dir/assess_dope.log") || die "Can't open dope log file.\n";
        while(<DOPE_CHECK>)
        {
             $line = $_;
             if($line =~ /DOPE score               :/)
             {
                $dope_score = substr($line,(index($line, ":")+1),(length($line)-(index($line, ":")+1)));
                $dope_score =~ s/^\s+//; #remove leading spaces
                $dope_score =~ s/\s+$//; #remove trailing spaces
                $dope_score =~ s/ //gi;
                $dope_score =~ s/[^0-9.-]//gi;
                $dope_score =~ s/[0-9]-[0-9]//gi;
             }
        }
        close DOPE_CHECK;
        `rm $work_dir/assess_dope.log`;
        `rm $dope_script`;
        $dope_score_all[$index_name]=$dope_score;
		$names[$index_name]=$target;
		$index_name++;

	}#end of inside foreach
	#system("rm -R $work_dir");
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
		print $OUT $names[$i]."\t".$dope_score_all[$i]."\n";
	}
	$OUT->close();

    system("rm -R $work_dir");
 my $endtime = localtime();
 print  "\nThe time ended at : $endtime.\n";
