#! /usr/bin/perl -w
#
 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 use strict; # force disciplined use of variables
 use Cwd;
 use Cwd 'abs_path';
 use Scalar::Util qw(looks_like_number);

 if(@ARGV<2)
 {
    print "This script will generate a ranking alignment of all different rankings in input folder, and also generate a average concensus ranking!\n";
    print "perl $0 dir_input_rankings dir_output\n";
    print "For example:\n";
    print "perl $0 /home/casp11_human/renzhi_consensus/all_scores/T0759 /home/casp11_human/renzhi_consensus/all_scores/T0759_scores\n";
    exit(0);
 }
 my($dir_input)=$ARGV[0];
 my($dir_out)=$ARGV[1];
 
 -s $dir_out || system("mkdir $dir_out");

 my($file,$path_target,$name,$path_seq,$path_out);
 my(@files,@tem);
 my(%hash) = ();           # temporary store the scores
 my(%align_rank) = ();     # store the aligned ranking, key is the ranking index, and value is all model name with this ranking index
 my(@score_names)=();      # store all score names
 my($index_score)=0;

 my($i_rank,$key,$value,$IN,$OUT,$line,$path_align,$path_final);
 my($max_len)=-1;
 opendir(DIR,"$dir_input");
 @files = readdir(DIR);
 foreach $file (@files)
 {
    if($file eq "." || $file eq "..")
    {
       next;
    }
    $path_target = $dir_input."/".$file;
#    @tem = split(/\./,$file);
#    @tem = split(/\_/,$tem[1]);
    
#    $name = $tem[0];
    $name = $file;
    $score_names[$index_score++]=$name;             # get the name
    print "Processing score name $name ...\n";
    %hash=();
    ##### read the ranking file #######
    $IN = new FileHandle "$path_target";
    while(defined($line=<$IN>))
    {
       chomp($line);
       @tem=split(/\s+/,$line);
       if(@tem<2)
       {
          next;
       }
       if($tem[0] eq "REMARK" || $tem[0] eq "PFRMAT" ||$tem[0] eq "TARGET" ||$tem[0] eq "AUTHOR" ||$tem[0] eq "METHOD" ||$tem[0] eq "MODEL" || $tem[0] eq "QMODE" || $tem[0] eq "END")
       {
           next;
       }
       if(looks_like_number($tem[0]) || $tem[0] eq "X")
       {
           next;
       }
       $hash{$tem[0]}=$tem[1];

    }
    $IN->close();

=pod
if($name eq "energyqa")
{
   foreach $key (keys %hash)
   {
     print $key."\t".$hash{$key}."\n";
   }
   exit(0);
}
=cut

    ###### rank the score ######
    $i_rank = 0;
    foreach $key (sort{$hash{$b} <=> $hash{$a}} keys %hash)
    {
       if(not exists $align_rank{$i_rank})
       {
          $align_rank{$i_rank} = $key;
       }
       else
       {
          $align_rank{$i_rank}.="|".$key;
       }
       $i_rank++;
    }
	if($max_len == -1)
	{
		$max_len = $i_rank;
	}
	if($i_rank<$max_len)
	{
		for(;$i_rank<$max_len;$i_rank++)
		{
			$align_rank{$i_rank}.="|"."-1";
		}
	}
    if($i_rank>$max_len)
    {
       $max_len = $i_rank;
    }
 }
 $path_align = $dir_out."/"."Aligned_all_scores.txt";
 $OUT = new FileHandle ">$path_align";
 for($i_rank=0;$i_rank<$index_score;$i_rank++)
 {
     print $OUT $score_names[$i_rank]."\t";
 }
 print $OUT "\n";
 my($i);
 for($i_rank=0;$i_rank<$max_len;$i_rank++)
 {
    @tem =split(/\|/,$align_rank{$i_rank});
    for($i=0;$i<@tem;$i++)
    {
       print $OUT $tem[$i]."\t";
    }
    print $OUT "\n";
 }
 $OUT -> close();


 $path_final = $dir_out."/"."ranking.txt";
 my(@tem222);
 my(%con_ranking)=();           # key is model name, value is normed average score
 foreach $key (keys %align_rank)
 {
    @tem = split(/\|/,$align_rank{$key});
    for($i=0;$i<@tem;$i++)   
    {
       if(not exists $con_ranking{$tem[$i]})
       {
          $con_ranking{$tem[$i]} = "1"."|".$key;
       }
       else
       {
          @tem222=split(/\|/,$con_ranking{$tem[$i]});
          $tem222[0]++;
          $tem222[1]+=$key;
          $con_ranking{$tem[$i]} = $tem222[0]."|".$tem222[1];
       }
    }
 }
 foreach $key (keys %con_ranking)
 {
    @tem=split(/\|/,$con_ranking{$key});
    $tem[1]/=$tem[0];
    $con_ranking{$key}=$tem[1];
    $con_ranking{$key}/=$max_len;
 }
 
 $OUT = new FileHandle ">$path_final";
 foreach $key (sort{$con_ranking{$a} <=> $con_ranking{$b}} keys %con_ranking)
 {
    print $OUT $key."\t".$con_ranking{$key}."\n";
 }
 $OUT->close();
