#! /usr/bin/perl -w
#
 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 use strict; # force disciplined use of variables
 use Cwd;
 use Cwd 'abs_path';
 sub get_con_best_model($);
 sub get_pairwise_best_model($);

 if(@ARGV<3)
 {
    print "This script will validate the best consensus based model, compare it with the pairwise best model, Zhang_server_TS1, MULTICOM-CLUSTER_TS1, somehow show whether our prediction is safe.\n";
   
    print "perl $0 dir_human_prediction_folder addr_tm_score addr_output\n";
    print "For example:\n";
    
    print "\n******** CASP11 human prediction *********\n";
    print "perl $0 /home/rcrg4/HT0793 /home/rcrg4/tools/TM_score_old_version/TMscore_32 /home/casp11_human/renzhi_consensus/result/validation_T0793\n";

    exit(0);
 }
 my($dir_human_target)=$ARGV[0];
 my($tm_score)=$ARGV[1];
 my($addr_out)=$ARGV[2];

 my($tmp_out)=$addr_out.".tmp"; 

 system("mkdir $tmp_out");
 
 

 my($con_best_name) = get_con_best_model($dir_human_target);
 my($pairwise_best_name,$best_pairwise_score) = get_pairwise_best_model($dir_human_target);

 if($con_best_name eq "NULL" || $pairwise_best_name eq "NULL")
 {
	 print "Error, not existing the best consensus score model or best pairwise model, check $dir_human_target!\n";
	 exit(0);
 }
 
 my($IN,$OUT,$line);
 my($filter_models) = "NULL";
 my(@tem_split);

 opendir(DIR,"$dir_human_target");
 my(@folders) = readdir(DIR);
 foreach my $folder (@folders)
 {
	 if($folder eq "." || $folder eq "..")
	 {
		 next;
	 }
	 @tem_split=split(/\-/,$folder);
	 if(@tem_split<2)
	 {
		 next;
	 }
	 if($tem_split[0] ne "filtered")
	 {
		 next;
	 }
     $filter_models = $dir_human_target."/".$folder;
	 last;
 }
 if($filter_models eq "NULL")
 {
	 print "Not finding the filtered model folder : $filter_models!\n";
	 exit(0);
 }
 

 my($Zhang_ts1) = $filter_models."/"."Zhang-Server_TS1";
 my($cluster_ts1) = $filter_models."/"."MULTICOM-CLUSTER_TS1";
 my($con_best) = $filter_models."/".$con_best_name;
 my($pairwise_best) =$filter_models."/".$pairwise_best_name;
 if(!-s $Zhang_ts1 || !-s $cluster_ts1 || !-s $con_best || !-s $pairwise_best)
 {
	 print "Not existing the model $Zhang_ts1, $cluster_ts1, $con_best, $pairwise_best!\n";
	 exit(0);
 }
 
 ##### compare the GDT score #########
 my($tm_con_pairwise,$tm_con_cluster,$tm_con_zhang);
 $tm_con_pairwise = $tmp_out."/".$con_best_name."_vs_".$pairwise_best_name;
 $tm_con_cluster = $tmp_out."/".$con_best_name."_vs_"."MULTICOM-CLUSTER_TS1";
 $tm_con_zhang = $tmp_out."/".$con_best_name."_vs_"."Zhang-Server_TS1";
 
 system("$tm_score $con_best $pairwise_best > $tm_con_pairwise");
 system("$tm_score $con_best $cluster_ts1 > $tm_con_cluster");
 system("$tm_score $con_best $Zhang_ts1 > $tm_con_zhang");

 my($tm_pairwise_cluster) = $tmp_out."/".$pairwise_best_name."_VS_"."MULTICOM-CLUSTER_TS1";
 my($tm_pairwise_zhang) = $tmp_out."/".$pairwise_best_name."_VS_"."Zhang-Server_TS1"; 
 my($tm_zhang_cluster) = $tmp_out."/"."Zhang_server_TS1_VS_MULTICOM-CLUSTER_TS1";

 system("$tm_score $pairwise_best $cluster_ts1 > $tm_pairwise_cluster");
 system("$tm_score $pairwise_best $Zhang_ts1 > $tm_pairwise_zhang");
 system("$tm_score $Zhang_ts1 $cluster_ts1 > $tm_zhang_cluster");

 my(@tem);
 ###### get the real GDT scores #######
 my($score_pairwise_cluster,$score_pairwise_zhang,$score_zhang_cluster);

     $IN = new FileHandle "$tm_pairwise_cluster";
     while(defined($line=<$IN>))
     {
        chomp($line);
        if($line=~m/GDT-score/)
        {
          @tem = split(/\s+/,$line);
          $score_pairwise_cluster = $tem[2];
          last;
        }
     }
     $IN->close();

     $IN = new FileHandle "$tm_pairwise_zhang";
     while(defined($line=<$IN>))
     {
        chomp($line);
        if($line=~m/GDT-score/)
        {
          @tem = split(/\s+/,$line);
          $score_pairwise_zhang = $tem[2];
          last;
        }
     }
     $IN->close();

     $IN = new FileHandle "$tm_zhang_cluster";
     while(defined($line=<$IN>))
     {
        chomp($line);
        if($line=~m/GDT-score/)
        {
          @tem = split(/\s+/,$line);
          $score_zhang_cluster = $tem[2];
          last;
        }
     }
     $IN->close();
 #
 #
 my($score_vs_pairwise,$score_vs_cluster,$score_vs_zhang);
 
     $IN = new FileHandle "$tm_con_pairwise";
     while(defined($line=<$IN>))
     {
        chomp($line);
        if($line=~m/GDT-score/)
        {
          @tem = split(/\s+/,$line);
          $score_vs_pairwise = $tem[2];
          last;
        }
     }
     $IN->close();

     $IN = new FileHandle "$tm_con_cluster";
     while(defined($line=<$IN>))
     {
        chomp($line);
        if($line=~m/GDT-score/)
        {
          @tem = split(/\s+/,$line);
          $score_vs_cluster = $tem[2];
          last;
        }
     }
     $IN->close();

     $IN = new FileHandle "$tm_con_zhang";
     while(defined($line=<$IN>))
     {
        chomp($line);
        if($line=~m/GDT-score/)
        {
          @tem = split(/\s+/,$line);
          $score_vs_zhang = $tem[2];
          last;
        }
     }
     $IN->close();

  
   ##### output the result ##########
   $OUT = new FileHandle ">$addr_out";
   print $OUT "Consensus_best_model $con_best_name. The pairwise based best model is $pairwise_best_name, and the pairwise score for this model is $best_pairwise_score!\n";
   print $OUT "Here is the TM score output path, and GDT score for comparing consensus best model with the pairwise top model, zhang_server_TS1, and MULTICOM-CLUSTER_TS1 : \n";
   print $OUT "$tm_con_pairwise   =>   $score_vs_pairwise\n";
   print $OUT "$tm_con_cluster   =>   $score_vs_cluster\n";
   print $OUT "$tm_con_zhang   =>   $score_vs_zhang\n";
   print $OUT "\n";
   print $OUT "$tm_zhang_cluster   =>  $score_zhang_cluster\n";
   print $OUT "$tm_pairwise_zhang  =>  $score_pairwise_zhang\n";
   print $OUT "$tm_pairwise_cluster  =>  $score_pairwise_cluster\n";
   $OUT->close();
 
 

 
 
# system("rm -R $tmp_out");
 

 sub get_con_best_model($)
 {# this function will return the consensus based best model, check Re_ranking.txt in the input folder!
	 my($dir_input)=@_;
	 my($path) = $dir_input."/"."Re_ranking.txt";
	 if(!-s $path)
	 {
		 print "Error, not existing the consensus best ranking file $path! \n";
		 return "ERROR";
	 }
     my($IN) = new FileHandle "$path";
	 my($line);
	 my(@tem);
	 if(defined($line=<$IN>))
	 {
		 chomp($line);
         @tem = split(/\s+/,$line);
	 }
	 $IN->close();
	 return $tem[0];
 }

 sub get_pairwise_best_model($)
 {# this function will return the pairwise based best model, check Re_ranking.txt in the input folder!
	 my($dir_input)=@_;
	 my($scores_folder) = $dir_input."/"."ALL_scores";
         my($scores_folder2) = $dir_input."/"."ALL_14_scores";
	 if(!-s $scores_folder)
	 {
		 print "Error, not existing the pairwise best ranking folder $scores_folder! \n";
		 return "ERROR";
	 }
         if(-s $scores_folder2)
         {# we use the new version
             $scores_folder = $scores_folder2;
         }
	 my(@tem);
	 my($path)="NULL";
     opendir(DIR,"$scores_folder");
     my(@folders) = readdir(DIR);
     foreach my $folder (@folders)
     {
		 if($folder eq "." || $folder eq "..")
		 {
			 next;
		 }
         @tem = split(/\./,$folder);
		 if(@tem<2)
		 {
			 next;
		 }
		 if($tem[1] ne "gdt")
		 {
			 next;
		 }
         $path = $scores_folder."/".$folder;
		 last;
	 }
	 if($path eq "NULL")
	 {
		 return "NULL";
	 }
	 my($IN,$line);
	 
	 $IN =new FileHandle "$path";
	 while(defined($line=<$IN>))
	 {
		 chomp($line);
		 @tem= split(/\s+/,$line);
		 if(@tem<2)
		 {
			 next;
		 }
         if($tem[0] eq "REMARK" || $tem[0] eq "PFRMAT" ||$tem[0] eq "TARGET" ||$tem[0] eq "AUTHOR" ||$tem[0] eq "METHOD" ||$tem[0] eq "MODEL" || $tem[0] eq "QMODE" || $tem[0] eq "END")
#		 if($tem[0] eq "PFRMAT" || $tem[0] eq "TARGET" || $tem[0] eq "MODEL" || $tem[0] eq "QMODE")
		 {# skip head information
			 next;
		 }
		 last;
	 }
	 $IN->close();
	 return ($tem[0],$tem[1]);

 }
