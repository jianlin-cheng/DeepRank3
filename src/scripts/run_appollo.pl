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
 if (@ARGV != 7)
 {
     print "special for running in parallel, after finished, remove one file!\n";
     print "This program tries to run appollo ... input: executable_file, namelist_file, sequence file, old_TM_score, output,target_name, remove file\n";
     print "For example:\n";
     print "perl $0 /exports/store2/rcrg4/CASP11_server/renzhi_scripts/revised_appollo_show_matrix T0648.mlist_filtered T0648 /exports/store2/rcrg4/tools/TM_score_old_version/TMscore_32 matrix_pairwise/T0648 T0648 /exports/store2/rcrg4/CASP11_server/data_CASP11/T0648-149804384417881-eva-data/revised_appollo.is_running\n";
     exit(0);
 }
 my($exe)=$ARGV[0];
 my($namelist)=$ARGV[1];
 my($sequence)=$ARGV[2];
 my($TM)=$ARGV[3];
 my($output)=$ARGV[4];
 my($target)=$ARGV[5];
 my($remove_file)=$ARGV[6];
 my($return_val);
 my($fault);
 $return_val=system("$exe $namelist $sequence $TM $output $target");
 if($return_val!=0)
 { 
    print "fails!\n";
    $fault=$remove_file."_failed";
    system("cp $remove_file $fault");
    exit(0);
 } 
 $return_val=system("rm $remove_file");
 if($return_val!=0)
 {
    print "rm fails!\n";
    exit(0);
 }
 
