#! /usr/bin/perl -w
#
$ENV{'LD_LIBRARY_PATH'}.=':/home/jianliu/DeepRank3/tools/rosetta_2014.16.56682_bundle/main/source/build/external/release/linux/2.6/64/x86/gcc/4.4/default/';
$ENV{'LD_LIBRARY_PATH'}.=':/home/jianliu/DeepRank3/tools/rosetta_2014.16.56682_bundle/main/source/build/src/release/linux/2.6/64/x86/gcc/4.4/default/';
 
 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 use strict; # force disciplined use of variables
 use Cwd;
 use Cwd 'abs_path';
 sub get_length($);
 if(@ARGV<6)
 {
    print "This script will use the Proq inside rosetta to do QA.\n";
    print "perl $0 addr_proq2_in_rosetta_patch addr_rosetta_score_executable_file addr_rosetta_database target_folder sequence addr_output\n";
    print "For example:\n";
    print "perl $0 /home/rcrg4/tools/rosetta_proq2/ProQ_scripts-master/bin/run_all_external.pl /home/rcrg4/tools/rosetta_2014.16.56682_bundle/main/source/bin/score.linuxgccrelease /home/rcrg4/tools/rosetta_2014.16.56682_bundle/main/database ../data/casp9_server_prediction/T0554 ../data/casp9_seq/T0554.fasta ../result/T0554_proq2_score\n";
    print "\n***********For CASP11 human prediction**************\n";
    print "perl $0 /home/rcrg4/tools/rosetta_proq2/ProQ_scripts-master/bin/run_all_external.pl /home/rcrg4/tools/rosetta_2014.16.56682_bundle/main/source/bin/score.linuxgccrelease /home/rcrg4/tools/rosetta_2014.16.56682_bundle/main/database ../data/CASP11_prediction_human/T0759 ../data/CASP11_seq_human/T0759.fasta ../result/CASP11_proq2_human/T0759.proq2_score\n";
    exit(0);
 }
 my($proq2_tool)=abs_path($ARGV[0]);
 my($proq2_in_rosetta)=abs_path($ARGV[1]);
 my($rosetta_database)=abs_path($ARGV[2]);
 my($target)=abs_path($ARGV[3]);
 my($seq)=abs_path($ARGV[4]);
 my($addr_out)=abs_path($ARGV[5]);
 my($tmp_out)=$addr_out.".tmp"; 
 if(-s $tmp_out)
 {
   print "already find some prediction output, delete it!\n";
   system("rm -R $tmp_out");
 }
 -s $tmp_out || system("mkdir $tmp_out");

 system("cp $seq $tmp_out/");                # copy the sequence

 my($file);
 my(@files);
 opendir(DIR,"$tmp_out");
 @files = readdir(DIR);
 if(@files != 3)
 {
    print "error for the folder $tmp_out\n";
    exit(0);
 }
 for($file = 0; $file <3; $file++)
 {
    if($files[$file] eq "." || $files[$file] eq "..")
    {
    }
    else
    {
       last;
    }
 }
 my($seq_name)=$files[$file];                # get the sequence name

 my($new_seq)=$tmp_out."/".$seq_name;
 if(system("perl $proq2_tool -fasta $new_seq"))
 {
    print "perl $proq2_tool -fasta $new_seq fails!\n";
    exit(0);
 }
 my($seq_len) = get_length($new_seq);
 my($tmp_out_result) = $tmp_out."/"."Proq_score.sc";      # the output file
 
 chdir($tmp_out);
 
 my($path_model);
 opendir(DIR,"$target");
 @files = readdir(DIR);
 foreach $file (@files)
 {
   if($file eq "." || $file eq "..")
   {
     next;
   }
   if(system("$proq2_in_rosetta -database $rosetta_database -in:file:fullatom -ProQ:basename $seq_name -in:file:s $target/$file -out:file:scorefile $tmp_out_result -score:weights ProQ2 -ProQ:normalize $seq_len"))
   {
     print "$proq2_in_rosetta -database $rosetta_database -in:file:fullatom -ProQ:basename $seq_name -in:file:s $target/$file -out:file:scorefile $tmp_out_result -score:weights ProQ2 -ProQ:normalize $seq_len fails!\n";
    #exit(0);
   }
 }
 ###### get the mapping from the model name to rosetta based model name ######
 my(%hash_name)=();
 my(@tt);
 my($model_name,$i);
 opendir(DIR,"$target");
 @files=readdir(DIR);
 foreach $file (@files)
 {
    if($file eq "." || $file eq "..")
    {
      next;
    }
    @tt = split(/\./,$file);
    if($tt[@tt-1] eq "pdb")
    {
      $model_name = $tt[0];
      for($i=1;$i<@tt-1;$i++)
      {
         $model_name.=".".$tt[$i];
      }
      $model_name.="_0001";
    }
    else
    {
      $model_name=$file."_0001";
    }
    if(not exists $hash_name{$model_name})
    {
       $hash_name{$model_name} = $file;
    }
    else
    {
       print "Warning, the name $model_name is existing!! check $file\n";
    }
 }


 ###### now parse this proq2 out to real output file ######
 my($IN,$OUT,$line);
 my(%hash)=();
 my(@tem_split);
 $IN = new FileHandle "$tmp_out_result";
 $OUT = new FileHandle ">$addr_out";
 if(defined($line=<$IN>))
 {
   # skip the head
 }
 while(defined($line=<$IN>))
 {
    chomp($line);
    @tem_split=split(/\s+/,$line);
    if(@tem_split<2)
    {
	next;
    }
    #print $OUT $tem_split[0]."\t".$tem_split[1]."\n";
    if(not exists $hash_name{$tem_split[14]})
    {
       print "Not existing $tem_split[14] as model name!\n";
       exit(0);
    }
    if(not exists $hash{$hash_name{$tem_split[14]}})
    {
        $hash{$hash_name{$tem_split[14]}} = $tem_split[1];
    }
 }
 my($key);
 foreach $key (sort{$hash{$b} <=> $hash{$a}} keys %hash)
 {
    print $OUT $key."\t".$hash{$key}."\n";
 } 

 $IN->close();
 $OUT->close();

 
 system("rm -R $tmp_out");
 

 sub get_length($)
 {
    my($seq)=@_;
    my($IN,$sequence,$line);
    $sequence = "NULL";
    $IN = new FileHandle "$seq"; 
    while(defined($line=<$IN>))
    {
      chomp($line);
      if(substr($line,0,1) eq ">")    
      {
         next;
      }
      if($sequence eq "NULL") {$sequence=$line;}
      else
      {
         $sequence.=$line;
      }
    }
    $IN->close();
    return length($sequence);
 } 
