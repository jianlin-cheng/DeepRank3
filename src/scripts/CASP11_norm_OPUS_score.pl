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
 sub readseq($);
 sub norm_score($$$);
##############standard Amino Acids (3 letter <-> 1 letter)#######
my(%amino)=();
$amino{"ALA"} = 'A';
$amino{"CYS"} = 'C';
$amino{"ASP"} = 'D';
$amino{"GLU"} = 'E';
$amino{"PHE"} = 'F';
$amino{"GLY"} = 'G';
$amino{"HIS"} = 'H';
$amino{"ILE"} = 'I';
$amino{"LYS"} = 'K';
$amino{"LEU"} = 'L';
$amino{"MET"} = 'M';
$amino{"ASN"} = 'N';
$amino{"PRO"} = 'P';
$amino{"GLN"} = 'Q';
$amino{"ARG"} = 'R';
$amino{"SER"} = 'S';
$amino{"THR"} = 'T';
$amino{"VAL"} = 'V';
$amino{"TRP"} = 'W';
$amino{"TYR"} = 'Y';
###################################################################
  if (@ARGV != 3)
    { # @ARGV used in scalar context = number of args
          print "For CASP11\n";
	  print("This script tries to normalize the OPUS_PSP score, so we can use the normalized dfire score to train NN network.\n");
	  print "perl $PROGRAM_NAME addr_sequence addr_not_normed_dfire_score addr_output\n";
	  
	  print "For example:\n\n";
#	  print "perl $PROGRAM_NAME ../../casp9_evaluation_test/data/standard_casp9_release_sequence ../result/not_normed_score_casp9/not_normed_OPUS_score_scw_pro ../result/normed_score_casp9/normed_OPUS_score_casp9\n";
	  exit(0);
	}
 my($addr_seq)=$ARGV[0];
 my($addr_score)=$ARGV[1];
 my($addr_output)=$ARGV[2]; 

# my($dir_seq)=$ARGV[0];
# my($dir_score)=$ARGV[1];
# my($dir_output)=$ARGV[2];

# -s $dir_seq || die "Not find $dir_seq\n";
# -s $dir_score || die "Not find $dir_score\n";
# -s $dir_output || system("mkdir $dir_output");

 my($file,$path,$line,$IN,$OUT,$path_seq,$name,$seq,$length,$path_out);
 my(@files,@tem_split);
# opendir(DIR,"$dir_score");
# @files = readdir(DIR);
# foreach $file (@files)
# {
#	 if($file eq '.' || $file eq '..')
#	 {
#		 next;
#	 }
         $path = $addr_score;
#	 $path=$dir_score."/".$file;           # the target file
#	 @tem_split=split(/\./,$file); 
#	 $name=$tem_split[0];                  # the target name
         $path_seq = $addr_seq;
#     $path_seq=$dir_seq."/".$name.".fasta";     # the sequence path
#	 if(!-s $path_seq)
#	 {
#		 print "We don't find the path for sequence: $path_seq, please check whether the sequence file name is in format *.fasta, or missing sequence for this target\n";
#		 next;
#	 }
	 $seq=readseq($path_seq);
         $length=length($seq);                  # get the length of the sequence
         $path_out = $addr_output;
#	 $path_out=$dir_output."/".$name.".norm_OPUS_PSP_score";   # the output file
	 norm_score($path,$length,$path_out);     # normalize the score
# }

sub norm_score($$$)
{# normalize the score
	my($input,$len,$out)=@_; 
    my($IN,$OUT,$line);
	my(@tem_split);
	my($a)=-17.97;
	#my($b)=6589.5; 

	my($b)=7000;
	##### native score = $a * len + $b ####
	my($min)=$a*$len;     # the native score
	my($max)=$b;             # the max score
	my($count)=0;             # count the number of models less or equal than the min score, or larger equal to the max score
    my($real_score);        # the real score, for energy score, the less the better, so we convert that, to make the larger the better.
	$OUT = new FileHandle ">$out";
	defined($OUT) || die "cannot open output file $out\n";
    $IN=new FileHandle "$input";
	defined($IN) || die "cannot open $input\n";
    while(defined($line=<$IN>))
	{
		chomp($line);
		$line=~s/\s+$//;
		@tem_split=split(/\s+/,$line);
        if($tem_split[1] < $min)
		{
			$tem_split[1] = $min;
			$count++;
		}
		if($tem_split[1] > $max)
		{
			$tem_split[1] = $max;
			$count++;    
		}
		$real_score=($max-$tem_split[1])/($max-$min);
		print $OUT $tem_split[0]."\t".$real_score."\n";
	}
	if($count!=0)
	{
	   print "$count models out of [$min,$max]\n";
	}
	$IN->close();
	$OUT->close();
}

sub readseq($)
 {# read the fasta sequence
         my($addr_seq)=@_;
     my($IN,$line);
         my(@tem_split);
         my($seq)="";
         $IN=new FileHandle "$addr_seq";
         defined($IN) || die "cannot open input sequence file $addr_seq\n";
         while(defined($line=<$IN>))
         {
                  chomp($line);
                  $line=~s/\s+$//;  # remove the windows character
          if(substr($line,0,1) eq ">")
                  {# this is the head
                          next;
                  }
                  if($line eq "")
                  {# empty
                          next;
                  }
                  $seq.=$line;
         }
         $IN->close();
         return $seq;
 }
