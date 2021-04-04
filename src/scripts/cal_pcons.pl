#! /usr/bin/perl -w
#
 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 use strict; # force disciplined use of variables
 use Cwd;
 use Cwd 'abs_path';
 sub add_author($$);

 if(@ARGV<3)
 {
    print "This script will use the Pcons to do QA.\n";
    print "Revised by Renzhi, add the AUTHOR information for all predictions!\n";
    print "perl $0 addr_Pcons target_folder addr_output\n";
    print "For example:\n";
    print "perl $0 /home/rcrg4/tools/Pcons/bin/pcons ../data/casp9_server_prediction/T0554 ../result/T0554_pcons_score \n";
    print "\n******** CASP11 human prediction *********\n";
    print "perl $0 /home/rcrg4/tools/Pcons/bin/pcons ../data/CASP11_prediction_human/T0759 ../result/CASP11_pcons_human/T0759.pcons_score\n";
    exit(0);
 }
 my($pcons)=$ARGV[0];
 my($target)=$ARGV[1];
 my($addr_out)=$ARGV[2];
 my($tmp_out)=$addr_out.".tmp"; 
# my($filtered_pre) = $addr_out."_tmp_models";
# -s $filtered_pre || system("mkdir $filtered_pre");
 #system("cp $target/* $filtered_pre/"); 
# add_author($target,$filtered_pre);
 my($tmp_matrix) = $addr_out.".matrix";
 if(system("$pcons -d $target -superimpose_all -m $tmp_matrix> $tmp_out"))
 {
    print "$pcons -d $target -superimpose_all -m $tmp_matrix> $tmp_out fails!\n";
    system("touch $addr_out");
    my($OUT_p) = new FileHandle ">$addr_out";
    print $OUT_p "   ";
    $OUT_p->close();
    exit(0);
 }
 system("rm $tmp_matrix");
# system("rm -R $filtered_pre");
 ###### now parse this casp format out to real output file ######
 my($IN,$OUT,$line);
 my(%hash)=();
 my(@tem_split);
 $IN = new FileHandle "$tmp_out";
 $OUT = new FileHandle ">$addr_out";
 while(defined($line=<$IN>))
 {
    chomp($line);
    @tem_split=split(/\s+/,$line);
    if(@tem_split<2)
    {
	next;
    }
    if($tem_split[0] eq "PFRMAT" || $tem_split[0] eq "TARGET" || $tem_split[0] eq "END" || $tem_split[0] eq "MODEL" || $tem_split[0] eq "QMODE")
    {# the head infor
        next;
    }
    if($tem_split[0] eq "Done")
    {
        next;
    }
    if($tem_split[0] eq "AUTHOR" || $tem_split[0] eq "REMARK" || $tem_split[0] eq "METHOD") 
    {
        next;
    }
    #print $OUT $tem_split[0]."\t".$tem_split[1]."\n";
    if(not exists $hash{$tem_split[0]})
    {
        $hash{$tem_split[0]} = $tem_split[1];
    }
 }
 my($key);
 foreach $key (sort{$hash{$b} <=> $hash{$a}} keys %hash)
 {
    print $OUT $key."\t".$hash{$key}."\n";
 } 

 $IN->close();
 $OUT->close();

 
# system("rm -R $tmp_out");
 
 sub add_author($$)
 {
    my($input_dir,$out_dir)=@_;
    my($i,$author,$path_in,$path_out,$file,$IN,$line,$OUT);
    my(@files,@tem);
    opendir(DIR,$input_dir);
    @files = readdir(DIR);
    foreach $file (@files)
    {
      if($file eq "." || $file eq "..") 
      {
         next;
      }
      $path_in = $input_dir."/".$file;
      $path_out = $out_dir."/".$file;
      @tem = split(/\./,$file);
      if($tem[@tem-1] eq "pdb")
      {
         $author = $tem[0];
      }
      else
      {
         @tem = split(/\_/,$file);
         $author = $tem[0];
      }
      $author = $file;
      $IN = new FileHandle "$path_in";
      $OUT = new FileHandle ">$path_out";
      print $OUT "AUTHOR\t$author\n";
      while(defined($line=<$IN>))
      {
         print $OUT $line;
      }
      $OUT->close();
      $IN->close();
    }
 }

