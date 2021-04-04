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

	  print("This script tries to normalize the dope score, so we can use the normalized dfire score to train NN network.\n");
	  print "perl $PROGRAM_NAME addr_sequence(*.fasta) addr_not_normed_dope_score(*.dope_score) addr_output\n";
	  
	  print "For example:\n\n";
	  print "perl $PROGRAM_NAME ../../test/casp9_seq/T0516.fasta ../../test/test_dope_prediction/T0516.dope_score ../../test/test_dope_prediction/T0516.normed_dope\n";
	  exit(0);
	}
 
 my($addr_seq)=$ARGV[0];
 my($addr_score)=$ARGV[1];
 my($addr_output)=$ARGV[2];
 -s $addr_seq || die "cannot open sequence file $addr_seq\n";
 -s $addr_score || die "cannot open not normed dope score file $addr_score\n";


 my($file,$path,$line,$IN,$OUT,$path_seq,$name,$seq,$length,$path_out);
 my(@files,@tem_split);

	 $path=$addr_score;           # the target file
	 $seq=readseq($addr_seq);
     $length=length($seq);                  # get the length of the sequence
	 
	 norm_score($path,$length,$addr_output);     # normalize the score


sub norm_score($$$)
{# normalize the score
	my($input,$len,$out)=@_; 
    my($IN,$OUT,$line);
	my(@tem_split);
	my($a)=-130.2;
	#my($b)=2396.9; 
	my($b)=0; 
	##### native score = $a * len + $b ####
	my($min)=$a*$len+$b;     # the native score
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
