#! /usr/bin/perl -w
#
 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 use strict; # force disciplined use of variables
 use Cwd;
 use Cwd 'abs_path';

 if(@ARGV<4)
 {
    print "This script will use the Modfoldclust2 jar file to do QA.\n";
    print "perl $0 addr_modfoldclust2 targetname target_folder sequence_fasta addr_output\n";
    print "For example:\n";
    print "perl $0 /home/rcrg4/tools/ModFOLDclust2/ModFOLDclust2.jar T0515 /home/rcrg4/tools/ModFOLDclust2/T0515_example_models /home/rcrg4/tools/ModFOLDclust2/T0515.fasta ../result/T0515_modfoldclust2\n";
    print "\n********** CASP11 human prediction ************\n";
#    print "perl $0 /home/rcrg4/tools/ModFOLDclust2/ModFOLDclust2.jar T0759 /home/rcrg4/Benchmark/data/CASP11_prediction_human /home/rcrg4/Benchmark/data/CASP11_seq_human/T0759.fasta ../result/CASP11_modfoldclust2_human/T0759.modfoldclust2_score\n";
    print "perl $0 /home/rcrg4/tools/ModFOLDclust2/ModFOLDclust2.jar T0759 /home/rcrg4/Benchmark/data/CASP11_prediction_human/T0759 /home/rcrg4/Benchmark/data/CASP11_seq_human/T0759.fasta ../result/CASP11_modfoldclust2_human/T0759.modfoldclust2_score\n";
    exit(0);
 }
 my($modfold)=$ARGV[0];
 my($target_name)=$ARGV[1];
 my($target)=$ARGV[2];
 my($seq)=$ARGV[3];
 my($addr_out)=$ARGV[4];
 
 my($tmp_out)=$addr_out.".tmp";     # try to put the temporary file inside this folder
 -s $tmp_out || system("mkdir $tmp_out");
 
 system("cp -R $target/* $tmp_out/");      # put all models inside this tem folder
 $tmp_out = abs_path($tmp_out);
 $tmp_out.="/";
 $seq = abs_path($seq);
 $seq.="/";
 if(system("java -jar $modfold $target_name $seq $tmp_out"))
 {
    print "java -jar $modfold $target_name $seq $tmp_out fails!\n";
    exit(0);
 } 
 my($out) = $tmp_out."/".$target_name."_ModFOLDclust2.sort";
 if(!-s $out)
 {
    print "Fail, no output $out!\n";
    print "Trying _ModFOLDclust.unsort\n";
    $out = $tmp_out."/".$target_name."_ModFOLDclust.unsort";
    if(!-s $out)
    {
      print "No help, bye!\n";
      exit(0);
    }
 } 
 ##### parse the out file #####
 my($IN,$OUT,$line);
 my(@tem);
 $IN = new FileHandle "$out";
 $OUT=new FileHandle ">$addr_out";
 while(defined($line=<$IN>))
 {
   chomp($line);
   @tem = split(/\s+/,$line);
   if(@tem<1)
   {
     next;
   }
   print $OUT $tem[0]."\t".$tem[1]."\n";
 }

 $IN->close(); 
 $OUT->close();
# system("cp $out $addr_out");

 system("rm -R $tmp_out");
 


