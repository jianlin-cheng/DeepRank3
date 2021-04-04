 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 use strict; # force disciplined use of variables
 
 if (@ARGV != 3)
    { # @ARGV used in scalar context = number of args
		  print "For CASP11\n";
		  print "This script will process the modelevaluator score file, and the input model list, for the model when modelevaluator fails, we use the average score of other models to replace it\n";
		  print "perl $0 addr_modeleva_score model_list addr_output\n";
		  print "For example:\n";
		  print "perl $0 \n";

		  exit(0);
	}


  my($input)=$ARGV[0];
  my($list)=$ARGV[1];
  my($output)=$ARGV[2];

  if(!-s $input || !-s $list)
  {
	  print "Not existing $input or $list!\n";
	  exit(0);
  }
  
  my($ren_len,$ren_IN,$ren_line);
  my(@ren_split,@ren_models);
  $ren_len=0;
  ####### get the model name from the list file which appollo generated, since my program also use appollo's list#
  $ren_IN = new FileHandle "$list";
  @ren_models=();
  while ( defined($ren_line = <$ren_IN>))
 { 
   chomp($ren_line);
   $ren_line=~s/\s+$//;  # remove the windows character
   @ren_split=split(/\//,$ren_line);
   $ren_models[$ren_len]=$ren_split[@ren_split-1];
   $ren_len++;
 }
 $ren_IN->close();
 
 my($ren_i,$ren_j);
 my(@ren_model_eval)=();

 for($ren_i=0;$ren_i<$ren_len;$ren_i++)
 {
   $ren_model_eval[$ren_i]=-1;  # initialize with -1
 }



 $ren_IN = new FileHandle "$input";

 my($total)=0;
 my($count)=0;
 while ( defined($ren_line = <$ren_IN>))
 {
   chomp($ren_line);
   $ren_line=~s/\s+$//;  # remove the windows character
   @ren_split=split(/\s+/,$ren_line);
   if(@ren_split<2)
   {
      next;
   }
   if($ren_split[0] eq "PFRMAT" || $ren_split[0] eq "TARGET" || $ren_split[0] eq "END" || $ren_split[0] eq "MODEL" || $ren_split[0] eq "QMODE")
   {# the head infor
      next;
   }
   for($ren_j=0;$ren_j<$ren_len;$ren_j++)
   {
      if($ren_split[0] eq $ren_models[$ren_j])
      {
         last;
      }
   }
   if($ren_j==$ren_len)
   {
      print $ren_split[0]." is not found in original name file ".$list."\n";
   }
   else
   {
      $ren_model_eval[$ren_j]=$ren_split[1];
      $total+=$ren_model_eval[$ren_j];
      $count++;
   }
 }
 $ren_IN->close();

 if($count== 0)
 {
	 print "There is no model generated using modelevaluator, we set all models with the quality score 0.5!\n";
         $total=0.5;
         $count=1;
#	 exit(0);
 }

 $total/=$count;     # this is the average score

 my($OUT) = new FileHandle ">$output";
 for($ren_i=0;$ren_i<$ren_len;$ren_i++)
 {
	 if($ren_model_eval[$ren_i] < 0)
	 {
		 $ren_model_eval[$ren_i] = $total;
	 }
	 print $OUT $ren_models[$ren_i]."\t".$ren_model_eval[$ren_i]."\n";
 }
 $OUT->close();
 
