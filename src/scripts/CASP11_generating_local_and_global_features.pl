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
 sub get_sequence_from_fasta($);           # get the sequence from the fasta file
 sub get_seq_from_atom($);                 # get the sequence from the pdb file
 sub read_sspro_acc($);                    # get the sspro sol information
 sub read_spinex($);                       # get the spineX information
 sub read_dssp($);					       # read the secondary from dssp parsed file
 sub convert_dssp_to_three_ss($);	       # convert a secondary structure of dssp into helix(G,H,I), strand(E,B), and loop(others).
 sub cal_difference($$);        # get the percentage of difference for two sequence
 sub cal_normalized_similarity($$$$$$); # calculate the secondary structure similarity for two sequences with unequal sequence length, and normalize the similarity score
 sub read_dssp_sol($);                     # read the dssp parsed amino acid and solvent accessibility
 sub convert_sol($$);                      # convert the solvent accessbility
 sub cal_normalized_penalty($$$$$$);       # calculate the secondary structure penalty for two sequences with unequal sequence length, and normalize the similarity score
 sub cal_penalty($$);                      # get the secondary structure penalty for two sequence
 sub cal_distance($);                      # calculate the pairwise euclidean distance
 sub get_coord($);
 sub cal_fractional_exposed($);        # get the fractional exposed area, check the paper
 sub cal_weighted_exposed($);        # get the weighted exposed area, check the paper
 sub cal_surface($);        # get the exposed surface area, check the paper
 sub generate_local_features($$$$$$$$$$$$$$$$$$);   # generate the local features for a model
 sub cal_local_surface_polor($$);                  # calculate normalized local surface polor score
 sub cal_local_weighted_exposed($$);                # calculate normalized local weighted exposed score
 sub cal_local_total_surface($$);                   # calculate normalized local total surface score
 sub convert_RMSD_to_score($);                      # convert the RMSD value of a residue to the score in the range [0,1].
 sub convert_score_to_RMSD($);                      # convert the score [0,1] to the RMSD value


  if (@ARGV != 10)
    { # @ARGV used in scalar context = number of args
	  
	  print "For CASP11. This script generate local and global features for one target!\n";
	  
	  print"This script generate the following features for each residue in the SVM format for all models in one target!\nThe not existing residue, like in 15 sliding window, the left 7 residue of the first residue, we use twenty 0 to represent, and all other features are normalized by the number of residue used.\n";
	  print " S-score is used, Si = 1/(1+(di/d0)*(di/d0)), d0 is set to sqrt(5), all di larger than 15 is set to 15, and the di is calculated by di =d0*sqrt(1/Si - 1). Cite <<prediction of global and local model quality in CASP7 using pcons and proq>>, <<a study of global measures for protein threading models>>.\n";

	  print "1. Secondary structure similarity of the model\n";
	  print "2. Secondary structure penalty of the model!\n";
	  print "3. Euclidean pairwise distance score of the model!\n";
	  print "4. Surface polar score of the model!\n";
	  print "5. Weighted exposed score of the model!\n";
	  print "6. Total surface area score of the model!\n";
	  print "7. Solvent accessibility score of the model!\n";
	  print "8. 15 residues windows of secondary structure similarity\n";
	  print "9. 15 residues windows of secondary structure penalty\n";
	  print "10.15 residues windows of euclidean pairwise distance score\n";
	  print "11.15 residues windows of surface polar score\n";
	  print "12.15 residues windows of weighted exposed score\n";
	  print "13.15 residues windows of total surface area score\n";
	  print "14.15 residues windows of solvent accessibility score\n";
	  print "15.features for 15 residues, each residue will have a 20 digit to represent, and use twenty 0 to represent the missing residues\n";

	  print "\n************** Renzhi Cao *******************\n";
	  print "Input:\n";
	  print "0. Dir of all models (for one target) Use the released target\n";
	  print "1. address of fasta sequence (use the released fasta sequence)\n";

	  print "2. address of LCS \n";
	  print "3. address of dsspcmbi\n";
	  print "4. address of dssp2dataset.pl\n";
	  print "5. address of Spx.pl(In spx tool)\n";
	  print "6. address of predict_acc.sh (In sspro tool)\n";
	  print "7. Dir of output\n";
          print "8. Address of resource\n";      

	  print "\n**************** Renzhi Cao *****************\n";
	  print "\nFor example:\n";
	  #print "perl $PROGRAM_NAME /exports/store1/rcrg4/REAL_NATIVE_from_CASP/data_downloaded_from_CASP/data_server_prediction/casp9_server_prediction/T0518 /exports/store1/rcrg4/REAL_NATIVE_from_CASP/data_downloaded_from_CASP/data_sequence/casp9_seq/T0518.fasta /exports/store1/rcrg4/REAL_NATIVE_from_CASP/result/local_QA_score_of_all_native_and_prediction_casp9/T0518 /exports/store1/rcrg4/tool_I_develop/LCS /exports/store1/tool/dsspcmbi ../Feature_generate_script/dssp2dataset.pl /exports/store1/tool/spine_X/spX.pl /exports/store1/tool/sspro4/bin/predict_acc.sh ../test/feature_F_1_local_QA_test\n";
#	  print "perl $0 /exports/store1/rcrg4/REAL_NATIVE_from_CASP/data_downloaded_from_CASP/data_server_prediction/casp9_server_prediction/T0518 /exports/store1/rcrg4/REAL_NATIVE_from_CASP/data_downloaded_from_CASP/data_sequence/casp9_seq/T0518.fasta /exports/store1/rcrg4/tool_I_develop/LCS /exports/store1/tool/dsspcmbi ../Feature_generate_script/dssp2dataset.pl /exports/store1/tool/spine_X/spX.pl /exports/store1/tool/sspro4/bin/predict_acc.sh ../test/test_feature_F_1_global_and_local_QA_features_testing resouce_to_delete\n";
          print "perl $0 ../data_CASP11/T0648-139803005126082-eva-data/scwrl_model/T0648 ../data_CASP11/T0648-139803005126082-eva-data/T0648 ../scripts/LCS ../renzhi_scripts/dsspcmbi ../renzhi_scripts/dssp2dataset.pl /rose/space1/renzhi/tool/spine_X/spX.pl /rose/space1/renzhi/tool/sspro4/bin/predict_acc.sh ../test/test_generateing_global_local_features ../test/123\n";

	  print "perl $0 /var/www/cgi-bin/QApro/test/T0649_eva_data/scwrl_model/T0649 /var/www/cgi-bin/QApro/test/T0649_eva_data/T0649 /var/www/cgi-bin/QApro/scripts/LCS /var/www/cgi-bin/QApro/renzhi_scripts/dsspcmbi /var/www/cgi-bin/QApro/renzhi_scripts/dssp2dataset.pl /rose/space1/renzhi/tool/spine_X/spX.pl /rose/space1/renzhi/tool/sspro4/bin/predict_acc.sh /var/www/cgi-bin/QApro/test/T0649_eva_data/local_global_features 123123\n";
	  exit(0);
	}


   my($dir_model)=$ARGV[0];
   my($addr_seq)=$ARGV[1];

   my($addr_LCS)=$ARGV[2];
   my($addr_dssp)=$ARGV[3];
   my($addr_dssp2dataset)=$ARGV[4];
   my($addr_spx)=$ARGV[5];
   my($addr_acc)=$ARGV[6];
   my($dir_output)=$ARGV[7];
   my($res)=$ARGV[8];
   my($targetname)=$ARGV[9];
   ########## set environment #############
   #$ENV{'spineXcodir'}='/rose/space1/renzhi/tool/spine_X/code';
   #$ENV{'spineXblast'}='/rose/space1/renzhi/tool/blast2.2.8';

   #######################################################################################################
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
	
	##################################################################
	##################################################################################################################################
	my(%aa_polar)=();              # tell whether a aminoacid is polar or not. If is polar, value is 1, else 0
	$aa_polar{'A'} = 0;
	#$aa_polar{'B'} = 0;
	$aa_polar{'C'} = 0;
	$aa_polar{'D'} = 1;
	$aa_polar{'E'} = 1;
	$aa_polar{'F'} = 0;
	$aa_polar{'G'} = 0;
	$aa_polar{'H'} = 1;
	$aa_polar{'I'} = 0;
	$aa_polar{'K'} = 1;
	$aa_polar{'L'} = 0;
	$aa_polar{'M'} = 0;
	$aa_polar{'N'} = 1;
	$aa_polar{'P'} = 0;
	$aa_polar{'Q'} = 1;
	$aa_polar{'R'} = 1;
	$aa_polar{'S'} = 1;
	$aa_polar{'T'} = 1;
	$aa_polar{'V'} = 0;
	$aa_polar{'W'} = 0;
	#$aa_polar{'X'} = 0;
	$aa_polar{'Y'} = 1;
	#$aa_polar{'Z'} = 0;
	###################################################################################################################################
	my(%aa_mass)=();
	$aa_mass{'A'} = 71.08;
	$aa_mass{'C'} = 103.14;
	$aa_mass{'D'} = 115.09;
	$aa_mass{'E'} = 129.12;
	$aa_mass{'F'} = 147.18;
	$aa_mass{'G'} = 57.05;
	$aa_mass{'H'} = 137.14;
	$aa_mass{'I'} = 113.16;
	$aa_mass{'K'} = 128.17;
	$aa_mass{'L'} = 113.16;
	$aa_mass{'M'} = 131.20;
	$aa_mass{'N'} = 114.10;
	$aa_mass{'P'} = 97.12;
	$aa_mass{'Q'} = 128.13;
	$aa_mass{'R'} = 156.19;
	$aa_mass{'T'} = 101.11;
	$aa_mass{'V'} = 99.13;
	$aa_mass{'W'} = 186.21;
	$aa_mass{'S'} = 87.08;
	$aa_mass{'Y'} = 163.18;

	###################################################################
	my(@aanames) = ('A', 'B', 'C','D','E','F','G','H','I','K','L','M','N','P','Q','R','S','T','V','W','X', 'Y', 'Z');
	my(@accth) = (106, 160, 135, 163, 194, 197, 84, 184, 169, 205, 164, 188, 157, 136, 198, 248, 130, 142, 142, 227, 180, 222, 196);
	my(%accth2)=();
	my($i);
	for ($i = 0; $i<=$#aanames; $i++) {
	        $accth2 {$aanames[$i]} = $accth[$i];
	}
	my(@standard_aanames)=('A','C','D','E','F','G','H','I','K','L','M','N','P','Q','R','S','T','V','W','Y');
	my(%aa_index)=();        # get the index for amino acid, since we only consider up-trigle matrix.
	for ($i = 0; $i<=$#standard_aanames; $i++) {
	    $aa_index{$standard_aanames[$i]}=$i;
	}    

   #######################################################################################################
   -s $dir_output || system("mkdir $dir_output");
   if(!-s $dir_model || !-s $addr_seq  || !-s $addr_LCS || !-s $addr_dssp || !-s $addr_dssp2dataset || !-s $addr_spx || !-s $addr_acc)
   {
	   print "not exists the following: !-s $dir_model || !-s $addr_seq || !-s $addr_LCS || !-s $addr_dssp || !-s $addr_dssp2dataset || !-s $addr_spx || !-s $addr_acc \n";
	   exit(0);
   }
   my($IN,$OUT,$file,$line,$return_val,$sequence,$key,$target,$value,$path_seq,$path_model,$seq_len,$model_name);
   my(@files,@tem_split,@tem222,@targets);

   ########## get the target name #####
   my($target_name);
   @tem_split=split(/\//,$dir_model);
   #$target_name = $tem_split[@tem_split-1];
   $target_name = $targetname;
   print "We get the target $target_name!\n";

   #######################################################################################################
   ######### 1. Extract the sequence from the fasta released sequence, we only use this sequence, and all model quality is based on this sequence #########
 #  my(%all_seqs)=();
   $sequence = get_sequence_from_fasta($addr_seq);
   $seq_len=length($sequence);
 print "Released sequence is :$sequence, the sequence length is : $seq_len\n";
=pod
   $all_seqs{$sequence}=1;
   my($selected_seq)=$sequence;
   $i=1;
   opendir(DIR,$dir_model);
   @files=readdir(DIR);
   foreach $file (@files)
   {
	   if($file eq "." || $file eq "..")
	   {
		   next;
	   }
	   $path_model = $dir_model."/".$file;
	   $sequence = get_seq_from_atom($path_model);
	   if(not exists $all_seqs{$sequence})
	   {
		   $all_seqs{$sequence}=1;
	   }
	   else
	   {
		   $all_seqs{$sequence}++;
		   if($all_seqs{$sequence} > $i)
		   {
			   $i=$all_seqs{$sequence};
			   $selected_seq = $sequence;
		   }
	   }
   }
   print "selected sequence is($i times among ".@files."):$selected_seq\n";
=cut   

=pod
   ########### 2. Load the real local quality score for each model ############################
   my(@tem_real_local)=();
   my($index_local)=0;
   my(%hash_real_local_QA)=();

   $IN = new FileHandle "$addr_real_local";
   while(defined($line=<$IN>))
   {
	   chomp($line);
	   @tem_split=split(/\s+/,$line);
	   if(@tem_split<2)
	   {
		   next;
	   }
	   if(@tem_split>$seq_len+1)
	   {# the number of local quality score should be less or equal to the sequence length!
		   print "Error! The number of residues in the model $tem_split[0] is larger than the sequence length : $seq_len! Check $addr_real_local:\n@tem_split\n";
		   exit(0);
	   }
	   @tem_real_local=();
	   $index_local=0;
	   $model_name="NULL";
	   for($i=0;$i<$seq_len;$i++)
	   {
		   $tem_real_local[$i]=-1;
	   }
	   for($i=1;$i<@tem_split;$i++)
	   {
		   $tem_real_local[$index_local++]=$tem_split[$i];
	   }
	   @tem222=split(/\_/,$tem_split[0]);
	   $model_name=$tem222[0];
       for($i=1;$i<@tem222-1;$i++)
	   {
		   $model_name.="_".$tem222[$i];
	   }
	   $i=@tem222-1;
	   if($tem222[$i] ne "filtered")
	   {# this name is not with the end "filtered", why?
		   #print "Warning! We get $tem222[$i], Check the name ($model_name) in $addr_real_local, at $line!\n";
		   $model_name.="_".$tem222[$i];
	   }
	   $key = $model_name;

	   if(not exists $hash_real_local_QA{$key})
	   {
		   $hash_real_local_QA{$key} = "@tem_real_local";
	   }
	   else
	   {
		   print "Error, the same name ($key) exits two times at $addr_real_local, at $line\n";
		   exit(0);
	   }


   }
   $IN->close();
=cut
   ############################################################################################
=pod  
   foreach $key (keys %hash_real_local_QA)
   {
	   @tem222=$hash_real_local_QA{$key};
	   for($i=0;$i<@tem222;$i++)
	   {
		   print $tem222[$i]."\n";
	   }
	   print "$key:".@tem222."\n";
	   exit(0);
   }
=cut
   ########## 3. Use dssp to parse the ss, sol of each model #####################
   my($dir_dssp_parsed)=$dir_output."/"."DSSP_result";
   -s $dir_dssp_parsed || system("mkdir $dir_dssp_parsed");
    my($path_target,$write_dssp,$dssp_parsed);
	opendir(DIR, "$dir_model");
	@targets=readdir(DIR);
	foreach $target (@targets)
	{
		if($target eq '.' || $target eq '..')
		{
			next;
		}
	    #print "Processing $target...\n";
		$path_target=$dir_model."/".$target;
	    $write_dssp=$dir_dssp_parsed."/".$target.".dsspout";         # the path for store the dssp output of this target $file
		if(-s $write_dssp)
		{# already processed
			#print "$target already processed, since $write_dssp exists! next ...\n";
			#next;
		}
		else
		{
		     open (File, "&gt;$write_dssp");
			 chmod (0777, $write_dssp);
	         close (File);		
		}


	    $return_val=system("$addr_dssp $path_target $write_dssp");
		if($return_val!=0)
		{
			print "$addr_dssp $path_target $write_dssp fails!\n";
		    #exit(0);
			next;
		}


		$dssp_parsed=$dir_dssp_parsed."/".$target.".dssp_parsed";  # the path for parsed dssp output result
		if(-s $dssp_parsed)
		{# already processed
			#print "$file already processed, since $dssp_parsed exists! next ...\n";
			#next;
		}
		else
		{
			 open (File, "&gt;$dssp_parsed");
		     chmod (0777, $dssp_parsed);
		     close (File);		
		}
		$return_val=system("perl $addr_dssp2dataset $write_dssp $dssp_parsed");
		if($return_val!=0)
		{
			print "perl $addr_dssp2dataset $write_dssp $dssp_parsed fails!\n";
			#exit(0);
			next;
		}
		system("rm $write_dssp");           # remove the original dssp output, we can just use the parsed dssp output .
	}# end of outside foreach
    ####### 4. Predict the secondary structure using SpineX #################
	######## use spineX to predict the secondary structure for the input sequence ############
	 # check already finished 
	 @tem_split=split(/\//,$addr_seq);
	 my($sequence_name)=$tem_split[@tem_split-1];         # get the sequence name

	 
	 my($tem_output)=$dir_output."/"."spineX_out";
	 -s $tem_output || system("mkdir $tem_output");
	 
	 my($spx_seq_dir)=$dir_output."/"."sequence_folder";
	 -s $spx_seq_dir || system("mkdir $spx_seq_dir");

	 $return_val = system("cp $addr_seq $spx_seq_dir/");
	 if($return_val !=0)
	 {
	         print "cp $addr_seq $spx_seq_dir/ fails\n"; 
	         exit(0);
	 }

	 my($tem_list)=$dir_output."/"."spineX_list";
	 $OUT = new FileHandle ">$tem_list";
	 print $OUT $sequence_name."\n";
	 $OUT->close();

	 my($check_path) = $dir_output."/"."spineX_out"."/".$sequence_name.".spXout";
	 if(-s $check_path)
	 {
	    print "already processed the output, skip!\n";
	    #return 1;
	 } 
	 else
	 {
		 $return_val = system("perl $addr_spx $tem_list $spx_seq_dir $tem_output");
		 if($return_val !=0)
		 {
	 	      print "perl $addr_spx $tem_list $spx_seq_dir $tem_output fails\n";
			  exit(0);
		 }
	 }



	 my($spinex_ss_file)=$tem_output."/".$sequence_name.".spXout";
	 if(!-s $spinex_ss_file)
	 {
		 print "$spinex_ss_file not exists, check why spineX fails! \n";
		 exit(0);
	 }
	 my($spi_seq,$spi_ss)=read_spinex($spinex_ss_file);
     
	 ######## 5. Predict the solvent accessibility using SSpro #############

	######## use sspro to predict the solvent accessbility for the input sequence ############
	 # check already finished 

	 
	 $tem_output=$dir_output."/"."$sequence_name.acc";
	 if(-s $tem_output)
	 {
	    print "already processed the output $tem_output, $addr_seq, skip!\n";  
		#return 1;
	 }
     else
	 {
		$return_val = system("perl $addr_acc $addr_seq $tem_output");
		print "running : perl $addr_acc $addr_seq $tem_output\n";

		if($return_val !=0)
		{
	         print "perl $addr_acc $addr_seq $tem_output fails\n";
             exit(0);
		}
	 }

	 my($acc_output)=$tem_output;
	 if(!-s $acc_output)
	 {
		 print "$acc_output not exists, check why sspro fails! \n";
		 exit(0);
	 }
	 my($sspro_seq,$sspro_sol)=read_sspro_acc($acc_output);

     
	 ##################################################################################################
	 #
	 #          I. Getting the global seven features for each model in this target, and then get the local features
	 #
	 ##################################################################################################

	 ######## 6. Preparing the features for each model ######################
	 my($tmp_features)=$dir_output."/"."Local_features";            # we put the SVM format data generated from each model in this folder
	 -s $tmp_features || system("mkdir $tmp_features");             
 	 my($LCS_dir)=$dir_output."/"."LCS";                                    # we put the result of LCS at this path
	 -s $LCS_dir || system("mkdir $LCS_dir");     
     my($dir_global)=$dir_output."/"."Global_features";             # we get the global features for each model

	 if(-s $dir_global)
	 {
		 print "The global feature folder has been generated, check why? Warning!!!\n";

	 }
	 -s $dir_global || system("mkdir $dir_global");
	 my($dir_fix)=$dir_output."/"."Fix_dssp";        # some models, dssp fails to parse some residue!
	 -s $dir_fix || system("mkdir $dir_fix");


     my($p_1)=$dir_global."/"."1_feature_ss_sim.".$target_name;
	 my($p_2)=$dir_global."/"."2_feature_ss_penalty.".$target_name;
	 my($p_3)=$dir_global."/"."3_feature_euclidean.".$target_name;
	 my($p_4)=$dir_global."/"."4_feature_surface.".$target_name;
	 my($p_5)=$dir_global."/"."5_feature_weighted.".$target_name;
	 my($p_6)=$dir_global."/"."6_feature_total_surf.".$target_name;
	 my($p_7)=$dir_global."/"."7_feature_solvent.".$target_name;

	 my($OUT_1)=new FileHandle ">$p_1";
	 #defined($OUT_1) || die "Cannot create $p_1!!!\n";
	 my($OUT_2)=new FileHandle ">$p_2";
	 my($OUT_3)=new FileHandle ">$p_3";
	 my($OUT_4)=new FileHandle ">$p_4";
	 my($OUT_5)=new FileHandle ">$p_5";
	 my($OUT_6)=new FileHandle ">$p_6";
	 my($OUT_7)=new FileHandle ">$p_7";


	 my($GF_1,$GF_2,$GF_3,$GF_4,$GF_5,$GF_6,$GF_7);                         # the global features for each model!
     my($dssp_of_model,$dssp_sol,$dssp_value_sol,$dssp_aa,$dssp_ss,$path_LCS,$path_real,$path_parse,$OUT_SS,$model_feature,$L_aligned_real_seq,$L_aligned_model_seq);
     my($seq_from_model,$path_fix_dssp);
	 opendir(DIR, "$dir_model");
	 @targets=readdir(DIR);
	 foreach $target (@targets)
	 {
		if($target eq '.' || $target eq '..')
		{
			next;
		}
		$path_target=$dir_model."/".$target;         # the path for this model
		$dssp_of_model = $dir_dssp_parsed."/".$target.".dssp_parsed";
		if(!-s $dssp_of_model)
		{
			print "not existing $dssp_of_model, the dssp program fails on this model? !\n";
			next;
		}
		($dssp_aa,$dssp_ss)=read_dssp($dssp_of_model);      # get the amino acids and secondary struture from the dssp parsed output
		$L_aligned_real_seq = $dssp_aa;
        $L_aligned_model_seq = $spi_seq;

        ### calculating global features ###
	    if($spi_seq eq $dssp_aa)
		{
			$GF_1 = cal_difference($dssp_ss,$spi_ss);        # calculate the secondary similarity score, no normalization!!!
			$GF_2 = cal_penalty($dssp_ss,$spi_ss);        # calculate the secondary penalty score, no normalization!!!
		}
		else
		{# we need to align the sequence and then normalize the similarity score based on the spineX predicted secondary structure
	        $path_LCS=$LCS_dir."/".$target.".alignment_spx";
	        $path_real = $LCS_dir."/".$target.".real_spx";
			$path_parse = $LCS_dir."/".$target.".parsed_spx";
			
	        $OUT_SS = new FileHandle ">$path_real";
			print $OUT_SS ">$target released sequence\n";
			print $OUT_SS $spi_seq."\n";
			$OUT_SS->close();
	        $OUT_SS = new FileHandle ">$path_parse";
			print $OUT_SS ">$target parsed from model sequence\n";
			print $OUT_SS $dssp_aa."\n";
			$OUT_SS->close();
			$GF_1 = cal_normalized_similarity($addr_LCS,$path_real,$path_parse,$path_LCS,$spi_ss,$dssp_ss);
			($GF_2,$L_aligned_real_seq,$L_aligned_model_seq) = cal_normalized_penalty($addr_LCS,$path_real,$path_parse,$path_LCS,$spi_ss,$dssp_ss);
		}
        $GF_3 = 1-cal_distance($path_target); # calculate the pairwise distance of all atoms from the pdb
        $GF_4 = cal_fractional_exposed($dssp_of_model); # calculate the proportion of exposed area
        $GF_5 = 1-cal_weighted_exposed($dssp_of_model); # calculate the weighted exposed score
		$GF_6 = 1-cal_surface($dssp_of_model);          # calculate the total surface area score
        
        ($dssp_aa,$dssp_value_sol,$dssp_sol)=read_dssp_sol($dssp_of_model);
		if($dssp_value_sol eq "NULL")
		{# this model has less than 3 residues to predict
			print "The model $target has less than 3 residues for prediction, we skip this model!\n";
			next;
		}
	    if($sspro_seq eq $dssp_aa)
		{
			$GF_7 = cal_difference($dssp_sol,$sspro_sol);        # calculate the secondary similarity score, no normalization!!!
		}
		else
		{# we need to align the sequence and then normalize the similarity score based on the sspro predicted solvent accessibility
	        $path_LCS=$LCS_dir."/".$target.".alignment_sspro";
	        $path_real = $LCS_dir."/".$target.".real_sspro";
			$path_parse = $LCS_dir."/".$target.".parsed_sspro";
			
	        $OUT_SS = new FileHandle ">$path_real";
			print $OUT_SS ">$target released sequence\n";
			print $OUT_SS $sspro_seq."\n";
			$OUT_SS->close();
	        $OUT_SS = new FileHandle ">$path_parse";
			print $OUT_SS ">$target parsed from model sequence\n";
			print $OUT_SS $dssp_aa."\n";
			$OUT_SS->close();		
			$GF_7 = cal_normalized_similarity($addr_LCS,$path_real,$path_parse,$path_LCS,$sspro_sol,$dssp_sol);
		}

		###### validate the features ######
		if($GF_1 == -1)
		{
			print "Error, the feature secondary structure similarity fails to calculate, check the reason! $path_target,$dssp_of_model\n";
			
			#exit(0);
		}
		if($GF_4 == -1)
		{
			print "Error, the fractional exposed area fails to calculate, check the reason $path_target, $dssp_of_model!\n";
			#exit(0);
		}
		if($GF_5 == 2)
		{
			print "Error, the weighted exposed score fails to calculate, check the reason $path_target, $dssp_of_model!\n";
			#exit(0);
		}
		if($GF_6 == 2)
		{
			print "Error, the total surface score fails to calculate, check the reason $path_target, $dssp_of_model!\n";
			#exit(0);
		}
		if($GF_7 == -1)
		{
			print "Error, the feature solvent accessibility similarity fails to calculate, check the reason,$path_target, $dssp_of_model!\n";
			#exit(0);
		}

        if($GF_1!=-1)
		{
			print $OUT_1 $target."\t".$GF_1."\n";
		}
        if($GF_2!=-1)
		{
			print $OUT_2 $target."\t".$GF_2."\n";
		}
        if($GF_3!=-1)
		{
			print $OUT_3 $target."\t".$GF_3."\n";
		}
        if($GF_4!=-1)
		{
			print $OUT_4 $target."\t".$GF_4."\n";
		}
        if($GF_5!=-1)
		{
			print $OUT_5 $target."\t".$GF_5."\n";
		}
        if($GF_6!=-1)
		{
			print $OUT_6 $target."\t".$GF_6."\n";
		}
        if($GF_7!=-1)
		{
			print $OUT_7 $target."\t".$GF_7."\n";
		}
#    print "The features for model $target: $GF_1,$GF_2,$GF_3,$GF_4,$GF_5,$GF_6,$GF_7!\n";
#    print "The aligned real sequence is :\n$L_aligned_real_seq\nThe aligned model sequence is :\n$L_aligned_model_seq\n";
#	print "Check whether correct?\n";



        $model_feature=$tmp_features."/"."$target";
        generate_local_features($GF_1,$GF_2,$GF_3,$GF_4,$GF_5,$GF_6,$GF_7,$target,$path_target,$L_aligned_real_seq,$L_aligned_model_seq,$dssp_ss,$spi_ss,$dssp_sol,$sspro_sol,$dssp_value_sol,$sequence,$model_feature);
        ########## ADD script here to make alignment of dssp parsed and model sequence, make sure to make prediction for eachresidue !!!!!!!!!!!!!!!!!
        ######## check whether the sequence parsed by dssp from the model is the same as the seq
        #uence of the model######
        $seq_from_model = get_seq_from_atom($path_target);
        if($seq_from_model ne $dssp_aa)
        {# the sequence is not the same
              $path_fix_dssp = $dir_fix."/".$target;
			  $path_real = $dir_fix."/".$target.".seq_model";
			  $path_parse = $dir_fix."/".$target.".seq_dssp_parsed";
              $OUT_SS = new FileHandle ">$path_real";
			  print $OUT_SS "> sequence from the model $target\n";
			  print $OUT_SS "$seq_from_model";
			  $OUT_SS->close();
              $OUT_SS = new FileHandle ">$path_parse";
			  print $OUT_SS "> sequence which dssp parsed from the model $target\n";
			  print $OUT_SS "$dssp_aa";
			  $OUT_SS->close();

              $return_val=system("$addr_LCS $path_real $path_parse > $path_fix_dssp");
	          if(!-s $path_LCS)
	          {
		           print "$addr_LCS $path_real $path_parse > $path_fix_dssp fails!\n";
	          }
        }
        ########################################################################################        

	 }

     $OUT_1->close();
	 $OUT_2->close();
	 $OUT_3->close();
	 $OUT_4->close();
	 $OUT_5->close();
	 $OUT_6->close();
	 $OUT_7->close();

   system("rm $res");

   #we need to check the released sequence with most of the sequence of model, we use the most sequence of the model as the sequence. If they are the same, that's perfect. 
   #For the model, it should not filtered in the middle, should be continous, otherwise, we need to skip the part with not continous sequence,and treat as one residue is the rightest side, as the end, another as leftest, as the start of new amino acid!!!



   sub get_sequence_from_fasta($)
   {
	   my($path)=@_;
	   my($IN,$line);
	   my(@tem);
	   my($seq)="NULL";
	   $IN = new FileHandle "$path";
	   while(defined($line=<$IN>))
	   {
		   chomp($line);
		   if(substr($line,0,1) eq ">")
		   {# the head infor
			   next;
		   }
		   @tem=split(/\s+/,$line);
		   if(@tem<1 || @tem>1)
		   {
			   print "Warning, check the sequence fasta file:$line, at $path!\n";
			   next;
		   }
		   if($seq eq "NULL")
		   {
			   $seq=$line;
		   }
		   else
		   {
			   $seq.=$line;
		   }
	   }
	   $IN->close();
	   return $seq;
   }


	#read sequence from atom file
	sub get_seq_from_atom($)
	{
	        #assume the atom file exists
	        my $file = $_[0];
	        #my $chain = $_[1];
	        #print $chain."\n";
	        #sleep 5;
	        open(ATOM, $file) || die "can't read atom file: $file\n";
	        my @atoms = <ATOM>;
	        close ATOM;
	        my $prev = -1;
	        my $seq = "";
	        while (@atoms)
	        {
	                my $text = shift @atoms;
	                if ($text =~ /^ATOM/ )
	                {
	                        #get aa name
	                        #get position
	                        my $res = substr($text, 17, 3);
	                        $res = uc($res);
	                        $res =~ s/\s+//g;
	                        my $pos = substr($text, 22, 4);

	                        #if 3-letter, convert it to 1-letter.
	                        if (length($res) == 3)
	                        {
	                                if (exists($amino{$res}) )
	                                {
	                                        $res = $amino{$res};
	                                }
	                                else
	                                {
	                                        $res = "X";
	                                        print "$file: resudie is unknown, shouldn't happen. Skip this residue!\n";
											$pos = $prev;
	                                }
	                        }
	                        if ($pos != $prev)
	                        {
	                                $seq .= $res;
	                                $prev = $pos;
	                        }
	                }
	        }
	        return $seq;
	}




 sub read_spinex($)
 {
         my($input)=@_;
         my($IN,$line);
         my(@tem_split);
         my($seq,$ss);

         $IN=new FileHandle "$input";
         if(defined($line=<$IN>))
         {# skip the head information
         }
         if(defined($line=<$IN>))
         {
                 chomp($line);
                 $line=~s/\s+$//;
                 @tem_split=split(/\s+/,$line);
                 if(@tem_split<3)
                 {
                         next;
                 }
                 $ss=$tem_split[3];          # get the first ss
				 $seq=$tem_split[2];          # get the first amino acids
         }
         while(defined($line=<$IN>))
         {
                 chomp($line);
                 $line=~s/\s+$//;
                 @tem_split=split(/\s+/,$line);
                 if(@tem_split<3)
                 {
                         next;
                 }
                 $ss.=$tem_split[3];          # get the ss
				 $seq.=$tem_split[2];         # get the amino acid

     }
         $IN->close();
         return ($seq,$ss);
 }

 sub read_sspro_acc($)
 {
         my($input)=@_;
         my($IN,$line);
         my(@tem_split);
         my($seq,$sol);

         $IN=new FileHandle "$input";
         if(defined($line=<$IN>))
         {# skip the head information
         }
         if(defined($line=<$IN>))
         {
                 chomp($line);
                 $line=~s/\s+$//;
                 $seq=$line;                 # get the first amino acids        
         }
         while(defined($line=<$IN>))
         {
                 chomp($line);
                 $line=~s/\s+$//;
                 
				 $sol=$line;         # get the solvent accessbility

         }
         $IN->close();
		 my($test)=0;
		 for($test=0;$test<length($sol);$test++)
	     {
			 if((substr($sol,$test,1) ne "b") && (substr($sol,$test,1) ne "e"))
			 {
				 print "What happens??? check the sspro output $input, check the line : $line!\n";
				 exit(0);
			 }
		 }
         return ($seq,$sol);
 }


 sub convert_dssp_to_three_ss($)
 {
	 my($cha)=@_;
	 if($cha eq "G" || $cha eq "H" || $cha eq "I")
	 {# helix
		 return "H";
	 }
	 elsif($cha eq "E" || $cha eq "B")
	 {#strand
		 return "E";
	 }
	 else
	 {#coil
		 return "C";
	 }
 }

 sub read_dssp($)
 {
	 my($input)=@_;
	 my($IN,$line);
	 $IN=new FileHandle "$input";
	 my(@aa);
	 my($i);
	 my($dssp_aa)="NULL";
	 my($dssp_ss)="NULL";
	 if(defined($line=<$IN>))
	 {
		 # this is for chain ID
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for total number
	 }
	 if(defined($line=<$IN>))
	 {
		 chomp($line);
         @aa=split(/\s+/,$line);
		 if(@aa<1)
		 {# empty amino acid??? 
			 print "The amino acid is less than 1, check $input!\n";
			 return ($dssp_aa,$dssp_ss);
		 }
		 $dssp_aa=$aa[0];
		 for($i=1;$i<@aa;$i++)
		 {
			 $dssp_aa.=$aa[$i];
		 }
		 # this is for amino acid
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for index
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is secondary structure
		 chomp($line);
	 }

	 $IN->close();
	 my(@ss)=split(/\s+/,$line);
	 
	 if(@ss < 1)
	 {
		 return ($dssp_aa,$dssp_ss);
	 }
	 
	 $dssp_ss=convert_dssp_to_three_ss($ss[0]);
	 for($i=1;$i<@ss;$i++)
	 {
		 $dssp_ss.=convert_dssp_to_three_ss($ss[$i]);
	 }
	 return ($dssp_aa,$dssp_ss);
 }
 sub cal_difference($$)
 {
	 my($seq1,$seq2)=@_;
	 if(length($seq1) ne length($seq2))
	 {
		 print "Why the two sequence parsed by dssp and predicted by spinex is different? \n";
		 print "Sequence of dssp:\n$seq1\nSequence of spinex:\n$seq2\n";
		 return -1;
		 #exit(0);
	 }

	 my($i,$len,$count);
	 $count=0;
	 $len=length($seq1);
	 for($i=0;$i<$len;$i++)
	 {
		 if(substr($seq1,$i,1) eq substr($seq2,$i,1))
		 {
			 $count++;
		 }
	 }
	 if($len == 0)
	 {
		 return -1;
	 }
	 $count/=$len;
	 return $count;
 }

 sub cal_normalized_similarity($$$$$$)
 {
	 my($addr_LCS,$path_real,$path_parse,$path_LCS,$real_ss,$dssp_ss)=@_;
	 my($return_val)=system("$addr_LCS $path_real $path_parse > $path_LCS");
	 if(!-s $path_LCS)
	 {
		 print "$addr_LCS $path_real $path_parse > $path_LCS fails!\n";
		 return -1;
	 }
	 my($total_length)=length($real_ss);      # the total length of relased sequence 
	 if($total_length == 0)
	 {
		 print "Warning, check secondary structure $real_ss, 0?\n";
		 return -1;
	 }
     my($aligned_length);
     my($IN,$line);
	 my(@tem_split);
	 my(@sequences)=();
	 my($index)=0;
	 $IN = new FileHandle "$path_LCS";
	 while(defined($line=<$IN>))
	 {
		 chomp($line);
		 if(substr($line,0,1) eq "#")
		 {
			 next;
		 }
		 $sequences[$index++]=$line;
	 }
	 $IN->close();
     if($index<4)
	 {
		 print "The output of LCS is abnormal, check $addr_LCS $path_real $path_parse > $path_LCS\n";
		 return -1;
	 }
	 
	 my($aligned_real_ss)="NULL";
	 my($aligned_dssp_ss)="NULL";
	 my($i);
	 for($i=0;$i<length($real_ss);$i++)
	 {
		 if(substr($sequences[1],$i,1) eq "-")
		 {
			 next;
		 }
		 if($aligned_real_ss eq "NULL")
		 {
			 $aligned_real_ss = substr($real_ss,$i,1);
		 }
		 else
		 {
             $aligned_real_ss.=substr($real_ss,$i,1);
		 }
	 }
	 for($i=0;$i<length($dssp_ss);$i++)
	 {
		 if(substr($sequences[3],$i,1) eq "-")
		 {
			 next;
		 }
		 if($aligned_dssp_ss eq "NULL")
		 {
			 $aligned_dssp_ss = substr($dssp_ss,$i,1);
		 }
		 else
		 {
             $aligned_dssp_ss.=substr($dssp_ss,$i,1);
		 }
	 }


	 $aligned_length = length($aligned_dssp_ss);
	 my($aligned_number)=0;
	 my($all_number)=0;
	 for($i=0;$i<$aligned_length;$i++)
	 {
		 if(substr($aligned_real_ss,$i,1) eq substr($aligned_dssp_ss,$i,1))
		 {
			 $aligned_number++;
		 }
		 $all_number++;
	 }
	 if($all_number == 0)
	 {
		 return 0;
	 }
     my($simi_score)= ($aligned_number/$all_number) * ($aligned_length/$total_length);
	 
     return $simi_score;
 }


 sub convert_sol($$)
 {
        my($sol_value,$aa_type)=@_;
        if(not exists $accth2{$aa_type})
        {
                print "Check the amino acid type $aa_type, no threshold to get the solvent!\n";
                exit(0);
        }
        if($sol_value/$accth2{$aa_type} < 0.25)
        {
                return "b";
        }
        else
        {
                return "e";
        }

 }
 sub read_dssp_sol($)
 {
	 my($input)=@_;
	 my($IN,$line);
	 $IN=new FileHandle "$input";
	 my(@aa);
	 my($i);
	 my($dssp_aa)="NULL";
	 my($dssp_value_ss)="NULL"; 
	 my($dssp_ss)="NULL";
	 if(defined($line=<$IN>))
	 {
		 # this is for chain ID
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for total number
	 }
	 if(defined($line=<$IN>))
	 {
		 chomp($line);
         @aa=split(/\s+/,$line);
		 if(@aa<1)
		 {# empty amino acid??? 
			 print "The amino acid is less than 1, check $input!\n";
			 return ($dssp_aa,$dssp_value_ss,$dssp_ss);
		 }
		 $dssp_aa=$aa[0];
		 for($i=1;$i<@aa;$i++)
		 {
			 $dssp_aa.=$aa[$i];
		 }
		 # this is for amino acid
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for index
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is secondary structure
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is B1
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is B2
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is solvent accessbility
		 chomp($line);
	 }

	 $IN->close();
	 my(@ss)=split(/\s+/,$line);

	 if(@ss < 3)
	 {
		 return ($dssp_aa,$dssp_value_ss,$dssp_ss);
	 }
	 ### first save the real solvent value ###
	 $dssp_value_ss = $ss[0];
	 for($i=0;$i<@ss;$i++)
	 {
		 $dssp_value_ss.="_".$ss[$i];
	 }
	 
	 $dssp_ss=convert_sol($ss[0],$aa[0]);
	 for($i=1;$i<@ss;$i++)
	 {# get the solvent accessbility for each amino acid
		 $dssp_ss.=convert_sol($ss[$i],$aa[$i]);
	 }
	 return ($dssp_aa,$dssp_value_ss,$dssp_ss);
 }

 sub cal_penalty($$)
 {
	 my($seq1,$seq2)=@_;
	 my($i,$len,$penalty);
	 $penalty=0;

	 $len=length($seq1);
	 ###### 1. Check penalty for helix #######
	 for($i=0;$i<$len;$i++)
	 {
		 if((substr($seq1,$i,1) eq "H") && (substr($seq2,$i,1) ne "H"))
		 {
			 $penalty++;
		 }
		 elsif((substr($seq1,$i,1) ne "H") && (substr($seq2,$i,1) eq "H"))
		 {
			 $penalty++;
		 }
	 }
	 ###### 2. Check penalty for sheet #######
	 for($i=0;$i<$len;$i++)
	 {
		 if((substr($seq1,$i,1) eq "E") && (substr($seq2,$i,1) ne "E"))
		 {
			 $penalty++;
		 }
		 elsif((substr($seq1,$i,1) ne "E") && (substr($seq2,$i,1) eq "E"))
		 {
			 $penalty++;
		 }
	 }
	 ######## convert it into a score ########
	 if($len == 0)
	 {
		 $penalty = 0;
	 }
	 else
	 {
		 $penalty=(2*$len-$penalty)/(2*$len);
	 }
	 return $penalty;
 }
 sub cal_normalized_penalty($$$$$$)
 {
	 my($addr_LCS,$path_real,$path_parse,$path_LCS,$real_ss,$dssp_ss)=@_;
	 my($return_val)=system("$addr_LCS $path_real $path_parse > $path_LCS");
	 if(!-s $path_LCS)
	 {
		 print "$addr_LCS $path_real $path_parse > $path_LCS fails!\n";
		 return -1;
	 }
	 my($total_length)=length($real_ss);      # the total length of relased sequence 
	 if($total_length == 0)
	 {
		 print "Warning, check secondary structure $real_ss, 0?\n";
		 return -1;
	 }
     my($aligned_length);
     my($IN,$line);
	 my(@tem_split);
	 my(@sequences)=();
	 my($index)=0;
	 $IN = new FileHandle "$path_LCS";
	 while(defined($line=<$IN>))
	 {
		 chomp($line);
		 if(substr($line,0,1) eq "#")
		 {
			 next;
		 }
		 $sequences[$index++]=$line;
	 }
	 $IN->close();
     if($index<4)
	 {
		 print "The output of LCS is abnormal, check $addr_LCS $path_real $path_parse > $path_LCS\n";
		 return -1;
	 }
	 
	 my($aligned_real_ss)="NULL";
	 my($aligned_dssp_ss)="NULL";
	 my($i);
	 for($i=0;$i<length($real_ss);$i++)
	 {
		 if(substr($sequences[1],$i,1) eq "-")
		 {
			 next;
		 }
		 if($aligned_real_ss eq "NULL")
		 {
			 $aligned_real_ss = substr($real_ss,$i,1);
		 }
		 else
		 {
             $aligned_real_ss.=substr($real_ss,$i,1);
		 }
	 }
	 for($i=0;$i<length($dssp_ss);$i++)
	 {
		 if(substr($sequences[3],$i,1) eq "-")
		 {
			 next;
		 }
		 if($aligned_dssp_ss eq "NULL")
		 {
			 $aligned_dssp_ss = substr($dssp_ss,$i,1);
		 }
		 else
		 {
             $aligned_dssp_ss.=substr($dssp_ss,$i,1);
		 }
	 }


	 $aligned_length = length($aligned_dssp_ss);



     $i=cal_penalty($aligned_real_ss,$aligned_dssp_ss);        # get the penalty score for the aligned part
     my($simi_score)= $i * ($aligned_length/$total_length);
	 
     return ($simi_score,$sequences[1],$sequences[3]);
 }
sub cal_distance($)
{# calculate the pairwise distance between all atoms
	my($path_pdb)=@_;
	my($IN,$line,$j);
	my(@cor_X)=();
	my(@cor_Y)=();
	my(@cor_Z)=();
	my($index)=0;
      	my(@tem_cor)=();
        my(@aa)=();              # the amino acid for the input pdb
        my($res);


	my($i)=0;
	#### read pdb and calculate the radius of gyration ####
	 $IN=new FileHandle "$path_pdb";
	 while(defined($line=<$IN>))
	 {
		 chomp($line);
		 $line=~s/\s+$//;
	     if(substr($line,0,6) ne "ATOM  ")
		 {# this is not ATOM line
			 next;
		 }
         ###### check whether this is CA #########
		 if(substr($line,13,2) ne "CA" && substr($line,12,2) ne "CA")
		 {# the reason I put substr($line,12,2) is because some pdbs, the CA is not at the proper location.
			 next;
		 }
                 $res = substr($line,17,3);
                 $res=uc($res);
                 $res=~s/\s+//g;
                 if(not exists $amino{$res})
                 {
                     print "not exists residue $res, check the pdb!\n";
                     next;
                 }
                 $aa[$index]=$amino{$res};       # convert 3 to 1 amino acid
		 @tem_cor=get_coord($line);      # get the coordinate
		 $cor_X[$index]=$tem_cor[0];
		 $cor_Y[$index]=$tem_cor[1];
		 $cor_Z[$index]=$tem_cor[2];
		 $index++;

	 }
	 $IN->close();
	 if($index<=2)
	 {
		 print "There is no atoms in input pdb $path_pdb, check here !!!!\n";
		 return 0;
		 #exit(0);
		 #return 1;
	 }

     ###### calculate the pairwise distance between all unique pair atoms ######
         my(%pair_dis)=();               # the key is the unique amino acid pair, could be AA,AB, ... . The value is total distance and the frequency, finally get the average for each amino acid pair
         my(%straight_pair_dis)=();       # this is for calculating the dis for straight protein of the same sequence

         my($key,$value,$for_str);
         

	 my($radius)=0;
	 for($i=0;$i<$index-1;$i++)
	 {
		 for($j=$i+1;$j<$index;$j++)
		 {
                    $key=$aa[$i].$aa[$j];    # the key
		    $radius= sqrt( ($cor_X[$i]-$cor_X[$j])*($cor_X[$i]-$cor_X[$j]) + ($cor_Y[$i]-$cor_Y[$j])*($cor_Y[$i]-$cor_Y[$j]) + ($cor_Z[$i]-$cor_Z[$j])*($cor_Z[$i]-$cor_Z[$j]) );   # the euclidean distance for the aa pair
                    if(not exists $pair_dis{$key})
                    { # this is the first time we see this unique key
                        $pair_dis{$key} = $radius."|"."1"; 
                        $for_str=($j-$i)*3.8;
                        $straight_pair_dis{$key} = $for_str."|"."1";
                    }
                    else
                    {# already exists
                        @tem_split = split(/\|/,$pair_dis{$key});
                        $tem_split[0]+=$radius;
                        $tem_split[1]++; 
                        $value=$tem_split[0]."|".$tem_split[1]; 
                        $pair_dis{$key}=$value;        # update the value
                      
                        @tem_split = split(/\|/,$straight_pair_dis{$key}); 
                        $for_str=($j-$i)*3.8;
                        $tem_split[0]+=$for_str; 
                        $tem_split[1]++;
                        $for_str=$tem_split[0]."|".$tem_split[1];
                        $straight_pair_dis{$key} = $for_str;
                    }
		 }
	 }
     ######## calculate the avarage euclidean distance for each unique aa pair , and take the summation##########
     $radius=0;
     $for_str=0;      # this is for straight pdb
     foreach $key (keys %pair_dis)
     {
         @tem_split=split(/\|/,$pair_dis{$key});
         if(@tem_split<2)
         {
            next;
         }
         $value=$tem_split[0]/$tem_split[1];       # get the avarage value
         
         $radius+=$value;                  # get the summation of average

         @tem_split=split(/\|/,$straight_pair_dis{$key});
         $for_str+=$tem_split[0]/$tem_split[1];
 
     }
     if($for_str == 0)
     {
         return 0;
     }     
     $radius/=$for_str;
     

     return $radius;

}

 sub get_coord($)
 {
	 my($line)=@_;
	 my(@coor)=();
	 my($num);
	 $num=substr($line,30,8);
	 $coor[0]=sprintf("%.3f",$num);
	 $num=substr($line,38,8);
	 $coor[1]=sprintf("%.3f",$num);
	 $num=substr($line,46,8);
	 $coor[2]=sprintf("%.3f",$num);

	 return @coor;
     
 }
 sub cal_fractional_exposed($)
 {# read dssp processed result and parse the exposed area for each residue
	 my($input)=@_;
	 my($IN,$line);
     my(@tem_split);
	 my(@aa)=();                        # the amino acid
	 my(@exposed)=();                   # exposed area for each residue
	                
	 $IN=new FileHandle "$input";
	 if(defined($line=<$IN>))
	 {
		 # this is for chain ID
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for total number
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for amino acid
		 chomp($line);
		 @aa=split(/\s+/,$line);       # this is the amino acid
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for index
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is secondary structure
		
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is BP1
		
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is BP2
		
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is solvent
		 chomp($line);
		 @exposed=split(/\s+/,$line);  # this is the exposed area	
	 }
	 $IN->close();
     my($ex_non)=0;           # the total exposed area of nonpolar residue
	 my($ex_all)=0;           # the total exposed area of all residues
	 my($index)=scalar(@aa);
	 my($i);
	 for($i=0;$i<$index;$i++)
	 {
		 $ex_all+=$exposed[$i];          
		 if($aa_polar{$aa[$i]} == 0)
		 {# this is a nonpolar residue
			 $ex_non+=$exposed[$i];
		 }
	 }
	 if($ex_all == 0)
	 {
######### I only get few models which dssp cannot parse, because the pdb format is not correct! To make it simple, I give these model -1, it may influence a little bit about the final performance #####
		 print "Warning! Error, check $input, no residue inside! We set the score as 0\n";
		 return 0;
		 #exit(0);
	 }
	 my($quality)=$ex_non/$ex_all;    
	 return $quality;

 }
 sub cal_weighted_exposed($)
 {# read dssp processed result and parse the exposed area for each residue
	 my($input)=@_;
	 my($IN,$line);
     my(@tem_split);
	 my(@aa)=();                        # the amino acid
	 my(@exposed)=();                   # exposed area for each residue
	                
	 $IN=new FileHandle "$input";
	 if(defined($line=<$IN>))
	 {
		 # this is for chain ID
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for total number
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for amino acid
		 chomp($line);
		 @aa=split(/\s+/,$line);       # this is the amino acid
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for index
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is secondary structure
		
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is BP1
		
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is BP2
		
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is solvent
		 chomp($line);
		 @exposed=split(/\s+/,$line);  # this is the exposed area	
	 }
	 $IN->close();
     my($ex_non)=0;           # the total exposed area of residue times mass
	 my($ex_all)=0;           # the total area of residues time mass
	 my($index)=scalar(@aa);
	 my($i);
	 for($i=0;$i<$index;$i++)
	 {
		 if(not exists $aa_mass{$aa[$i]})
		 {
			 print "This residue $aa[$i] in $input is not a standard residue! Check here. \n";
			 next;
		 }

		 $ex_non+=$exposed[$i]*$aa_mass{$aa[$i]};          
		 $ex_all+=$accth2{$aa[$i]}*$aa_mass{$aa[$i]};     
	 }
	 if($ex_all == 0)
	 {
######### I only get few models which dssp cannot parse, because the pdb format is not correct! To make it simple, I give these model -1, it may influence a little bit about the final performance #####
		 print "Warning! Error, check $input, no residue inside!\n";
		 return -1;
		 #exit(0);
	 }
	 my($quality)=$ex_non/$ex_all;    
#     my($quality)=$ex_non;
	 return $quality;

 }

 sub cal_surface($)
 {# read dssp processed result and parse the exposed area for each residue
	 my($input)=@_;
	 my($IN,$line);
     my(@tem_split);
	 my(@aa)=();                        # the amino acid
	 my(@exposed)=();                   # exposed area for each residue
	                
	 $IN=new FileHandle "$input";
	 if(defined($line=<$IN>))
	 {
		 # this is for chain ID
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for total number
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for amino acid
		 chomp($line);
		 @aa=split(/\s+/,$line);       # this is the amino acid
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is for index
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is secondary structure
		
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is BP1
		
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is BP2
		
	 }
	 if(defined($line=<$IN>))
	 {
		 # this is solvent
		 chomp($line);
		 @exposed=split(/\s+/,$line);  # this is the exposed area	
	 }
	 $IN->close();
     my($ex_non)=0;           # the total exposed area of residue
	 my($ex_all)=0;           # the total area of residues
	 my($index)=scalar(@aa);
	 my($i);
	 for($i=0;$i<$index;$i++)
	 {
		 if(not exists $aa_mass{$aa[$i]})
		 {
			 print "This residue $aa[$i] in $input is not a standard residue! Check here. \n";
			 next;
		 }

		 $ex_non+=$exposed[$i];          
		 $ex_all+=$accth2{$aa[$i]};     
	 }
	 if($ex_all == 0)
	 {
######### I only get few models which dssp cannot parse, because the pdb format is not correct! To make it simple, I give these model -1, it may influence a little bit about the final performance #####
		 print "Warning! Error, check $input, no residue inside!\n";
		 return -1;
		 #exit(0);
	 }
	 my($quality)=$ex_non/$ex_all;    
#     my($quality)=$ex_non;
	 return $quality;

 }
 sub generate_local_features($$$$$$$$$$$$$$$$$$)
 {# use %hash_real_local_QA, %standard_aanames. 
	 my($f1,$f2,$f3,$f4,$f5,$f6,$f7,$model_name,$path_target,$L_aligned_real_seq,$L_aligned_model_seq,$dssp_ss,$spi_ss,$dssp_sol,$sspro_sol,$dssp_value_sol,$sequence,$output)=@_;
     
	 #print "For the local feature $path_target,(aligned real sequence, aligned model sequence, dssp parsed ss, spi predict ss, dssp solvent, sspro predict sol, released sequence:)\n";
	 #print "$L_aligned_real_seq\n";
	 #print "$L_aligned_model_seq\n";
	 #print "$dssp_ss\n";
	 #print "$spi_ss\n";
	 #print "$dssp_sol\n";
	 #print "$sspro_sol\n";
	 #print "$dssp_value_sol\n";
	 #print "$sequence\n";
     
	 #print $hash_real_local_QA{$model_name}."\n";
#	 my($local_QA_all_line)=$hash_real_local_QA{$model_name};           # the local QA for the whole released sequence
#	 my(@local_QA_all)=split(/\s+/,$local_QA_all_line);

#	 my(@local_QA)=();                           # this is the local QA score for the aligned model sequence, that's for the model
	 
 	 
#	 for($i_real=0;$i_real<length($L_aligned_real_seq);$i_real++)
#	 {
#		 $local_QA[$i_real] = -1;
#	 }
#	 $i_real=0;
#	 $i_model=0;

#print "@local_QA_all\n";

#	 for($i_real=0;$i_real<length($L_aligned_real_seq);$i_real++)
#	 {
#		 if(substr($L_aligned_real_seq,$i_real,1) ne "-")
#		 {# this is aligned part
#			 #print "Adding $local_QA_all[$i_real]\n";
#			 $local_QA[$i_model++]=convert_RMSD_to_score($local_QA_all[$i_real]);
#		 }
#	 }

     my($i_real,$i_model,$line);
	 my($S_left,$S_right,$S_i);

=pod
	 for($i_real=0;$i_real<length($L_aligned_real_seq);$i_real++)
	 {# check residue $i_real
		 $S_left = $i_real-7;
		 $S_right = $i_real+7;
		 if($S_left<0)
		 {
			 $S_left=0;
		 }
		 if($S_right>=length($L_aligned_real_seq))
		 {
			 $S_right=length($L_aligned_real_seq) - 1;
		 }

         for($S_i=$S_left;$S_i<=$S_right;$S_i++)
		 {
			 if(substr($L_aligned_real_seq,$S_i,1) eq "-")
			 {
				 $local_QA[$i_real] = -1;             # we don't use this kind of residues
			 }
		 }
	 }
=cut
     ###########################################################################################################################
#print "@local_QA\n";

     ####### load the coordinate of each atoms ########
	 my(@aa,@cor_X,@cor_Y,@cor_Z,@tem_cor);
	 my($res,$index,$index_coor,$j);
	 @aa=();
	 @cor_X=();
	 @cor_Y=();
	 @cor_Z=();
	 $index_coor=0;
	 my($IN)=new FileHandle "$path_target";
	 while(defined($line=<$IN>))
	 {
		 chomp($line);
		 $line=~s/\s+$//;
	     if(substr($line,0,6) ne "ATOM  ")
		 {# this is not ATOM line
			 next;
		 }
         ###### check whether this is CA #########
		 if(substr($line,13,2) ne "CA" && substr($line,12,2) ne "CA")
		 {# the reason I put substr($line,12,2) is because some pdbs, the CA is not at the proper location.
			 next;
		 }
        $res = substr($line,17,3);
        $res=uc($res);
        $res=~s/\s+//g;
        if(not exists $amino{$res})
        {
            print "not exists residue $res, check the pdb!\n";
            next;
        }
        $aa[$index_coor]=$amino{$res};       # convert 3 to 1 amino acid
		 @tem_cor=get_coord($line);      # get the coordinate
		 $cor_X[$index_coor]=$tem_cor[0];
		 $cor_Y[$index_coor]=$tem_cor[1];
		 $cor_Z[$index_coor]=$tem_cor[2];
		 $index_coor++;

	 }
	 $IN->close();

	 #print "@local_QA\n";
     ######### now use $L_aligned_model_seq as sequence (- should use as all 0 for amino feature), $dssp_ss,$spi_ss,$dssp_sol,$sspro_sol, and $path_target as the model to get coordinate, it's ready to calculate the local scores ####
     my($i,$k,$w_aa,$w_ss,$w_sol,$w_dssp_ss,$w_dssp_sol,$w_dssp_value_sol,$l_index,$r_index);
	 my($OUT);
	 my(@local_features)=();
	 my(@tem_sol)=split(/\_/,$dssp_value_sol);
	 my($index_local)=0;




	 $OUT=new FileHandle ">$output";
	 my($len_model)=length($L_aligned_model_seq);
	 for($index=$len_model-1;$index>=0;$index--)
	 {# we get the residue index, and the 15 sliding window for this residue
        $l_index=$index-7;
		$r_index=$index+7;
        $w_aa="";
		$w_ss="";
		$w_sol="";
		$w_dssp_ss="";
		$w_dssp_sol="";
		$w_dssp_value_sol="";
		$index_local=0;
		@local_features=();
		if(substr($L_aligned_model_seq,$index,1) eq "-")
		{# this part is not belong to the model sequence, however, the released sequence may have this part, we just skip it, no prediction
			next;
		}

        ######### first add the global features #####
        $local_features[$index_local++]=$f1;
		$local_features[$index_local++]=$f2;
		$local_features[$index_local++]=$f3;
		$local_features[$index_local++]=$f4;
		$local_features[$index_local++]=$f5;
		$local_features[$index_local++]=$f6;
		$local_features[$index_local++]=$f7;
        #############################################        
		
		for($i=$l_index;$i<=$r_index;$i++)
		{
			if($i<0 || $i>=$len_model)
			{
				$w_aa.="-";
				$w_ss.="-";
				$w_sol.="-";
				$w_dssp_ss.="-";
				$w_dssp_sol.="-";
				if($w_dssp_value_sol eq "")
				{
					$w_dssp_value_sol="-";
				}
				else
				{
					$w_dssp_value_sol.="_-";
				}
			}
			else
			{
				if($i >= length($L_aligned_model_seq))
				{
					$w_aa.="-";
				}
				else
				{
					$w_aa.=substr($L_aligned_model_seq,$i,1);
				}
				if($i >= length($spi_ss))
				{
					$w_ss.="-";
				}
				else
				{
					$w_ss.=substr($spi_ss,$i,1);
				}				
				if($i >= length($sspro_sol))
				{
					$w_sol.="-";
				}
				else
				{
					$w_sol.=substr($sspro_sol,$i,1);
				}			
				if($i >= length($dssp_ss))
				{
					$w_dssp_ss.="-";
				}
				else
				{
					$w_dssp_ss.=substr($dssp_ss,$i,1);
				}		
				if($i >= length($dssp_sol))
				{
					$w_dssp_sol.="-";
				}
				else
				{
					$w_dssp_sol.=substr($dssp_sol,$i,1);
				}								
				
				if($w_dssp_value_sol eq "")
				{
					$w_dssp_value_sol=$tem_sol[$i];
				}
				else
				{
					$w_dssp_value_sol.="_".$tem_sol[$i];
				}
			}
		}
		$local_features[$index_local++] = cal_difference($w_ss,$w_dssp_ss);
		$local_features[$index_local++] = cal_penalty($w_ss,$w_dssp_ss);
		############## now calculate the pairwise distance score ########################
	    if($index_coor<=2)
	    {
		  print "There is no atoms in input pdb $path_target, check here !!!!\n";
		  $local_features[$index_local++] = 0;
		  next;

		  #exit(0);
		  #return 1;
	    }
		else
		{
			     ###### calculate the pairwise distance between all unique pair atoms ######
			     my(%pair_dis)=();               # the key is the unique amino acid pair, could be AA,AB, ... . The value is total distance and the frequency, finally get the average for each amino acid pair
			     my(%straight_pair_dis)=();       # this is for calculating the dis for straight protein of the same sequence
			     my($key,$value,$for_str);
				 my($radius)=0;
				 if($l_index<0)
			     {
					 $l_index=0;
				 }
				 if($l_index>=$len_model)
			     {
					 $l_index=$len_model-1;
				 }
				 if($r_index<0)
			     {
					 $r_index=0;
				 }
				 if($r_index>=$len_model)
			     {
					 $r_index=$len_model-1;
				 }
				 for($i=$l_index;$i<$r_index;$i++)
				 {
					 for($j=$i+1;$j<$r_index+1;$j++)
					 {
                                 if($aa[$i] eq "-" || $aa[$j] eq "-")
                                 {
                                     next;
                                 }
			                    $key=$aa[$i].$aa[$j];    # the key
					            $radius= sqrt( ($cor_X[$i]-$cor_X[$j])*($cor_X[$i]-$cor_X[$j]) + ($cor_Y[$i]-$cor_Y[$j])*($cor_Y[$i]-$cor_Y[$j]) + ($cor_Z[$i]-$cor_Z[$j])*($cor_Z[$i]-$cor_Z[$j]) );   # the euclidean distance for the aa pair
			                    if(not exists $pair_dis{$key})
			                    { # this is the first time we see this unique key
			                        $pair_dis{$key} = $radius."|"."1"; 
			                        $for_str=($j-$i)*3.8;
			                        $straight_pair_dis{$key} = $for_str."|"."1";
			                    }
			                    else
			                    {# already exists
			                        @tem_split = split(/\|/,$pair_dis{$key});
			                        $tem_split[0]+=$radius;
			                        $tem_split[1]++; 
			                        $value=$tem_split[0]."|".$tem_split[1]; 
			                        $pair_dis{$key}=$value;        # update the value
			                      
			                        @tem_split = split(/\|/,$straight_pair_dis{$key}); 
			                        $for_str=($j-$i)*3.8;
			                        $tem_split[0]+=$for_str; 
			                        $tem_split[1]++;
			                        $for_str=$tem_split[0]."|".$tem_split[1];
			                        $straight_pair_dis{$key} = $for_str;
			                    }
					 }
				 }
			     ######## calculate the avarage euclidean distance for each unique aa pair , and take the summation##########
			     $radius=0;
			     $for_str=0;      # this is for straight pdb
			     foreach $key (keys %pair_dis)
			     {
			         @tem_split=split(/\|/,$pair_dis{$key});
			         if(@tem_split<2)
			         {
			            next;
			         }
			         $value=$tem_split[0]/$tem_split[1];       # get the avarage value
			         
			         $radius+=$value;                  # get the summation of average

			         @tem_split=split(/\|/,$straight_pair_dis{$key});
			         $for_str+=$tem_split[0]/$tem_split[1];
			 
			     }
			     if($for_str == 0)
			     {
			         $local_features[$index_local++] = 0;
			     }     
			     else
			     {
					 $radius/=$for_str;
					 

					 ######## write log file #########
					 if(1-$radius < 0)
					 {
						 print "******** found error,the radius is larger than 1, $radius!, and check @aa, from $l_index to $r_index, and the coordinate : \n@cor_X\n@cor_Y\n@cor_Z\n***********\n";
					 }
					 #################################
					 if($radius > 1)
					 {# we set the radius as maximum 1
						 $radius = 1;
					 }
					 $local_features[$index_local++] = 1-$radius;
				 }
		}
        $l_index=$index-7;
		$r_index=$index+7;
	    ##################################################################################

        ###### calculate surface polar, weighted, total score ########
        $local_features[$index_local++]=cal_local_surface_polor($w_aa,$w_dssp_value_sol);              # normalized surface polor score for 15 sliding windows
        $local_features[$index_local++]=cal_local_weighted_exposed($w_aa,$w_dssp_value_sol);           # normalized weighted exposed for 15 sliding windows
        $local_features[$index_local++]=cal_local_total_surface($w_aa,$w_dssp_value_sol);           # normalized total surface score for 15 sliding windows
        ###### calculate the feature of amino acids ##########
		#### for each amino acid, we use a 20 digit to represent them, based on the @standard_aanames ranks, if it's "-" or some other no recognized residue, we use twenty 0 to represent that residue.
        for($i=0;$i<length($w_aa);$i++)
		{
			for($j=0;$j<@standard_aanames;$j++)
			{
				if($standard_aanames[$j] eq substr($w_aa,$i,1))
				{
					last;
				}
			}
			for($k=0;$k<20;$k++)
			{
				if($k == $j)
				{
					$local_features[$index_local++]=1;
				}
				else
				{
					$local_features[$index_local++]=0;
				}
			}            
		}
        ####### output all features to the output file with the SVM format ######

        $k=0;
        for($i=0;$i<@local_features;$i++)
        {
           if($local_features[$i] == -1)
           {
              $k=1;
           }
        }
        if($k == 1)
        {
           print "Warning, check here. @local_features\n";
           print "Some local features is set to 0\n";
           #next;
        }


		#print "$local_QA[$index]\t@local_features\n";
		if($k == 1)
		{
		   print $OUT "-2 ";
		}
		else
		{
		   print $OUT "-1 ";
		}
		for($k=1;$k<@local_features+1;$k++)
		{
			$i=$k-1;
			if($local_features[$i] == -1)
			{# this local feature is not calculated, we set it to 0
				print "Warning, the local features $i, fails to calculate, we set it to 0 to solve the problem\n";
				$local_features[$i] = 0;
			}

			print $OUT $k.":".$local_features[$i]." ";
		}
		print $OUT "\n";

	 }

     
	 $OUT->close();

 }


 sub cal_local_surface_polor($$)
 {
	 my($aa,$sol)=@_;           # the amino acid and solvent accessibility
	 
	 my($IN,$line);
     my(@tem_split);
	 
	 my(@exposed)=split(/\_/,$sol);                   # exposed area for each residue
	                
     my($ex_non)=0;           # the total exposed area of residue
	 my($ex_all)=0;           # the total area of residues
	 my($index)=length($aa);
	 my($i);
	 my($num_skip)=0;
	 for($i=0;$i<$index;$i++)
	 {
		 if(not exists $aa_mass{substr($aa,$i,1)})
		 {
			 $num_skip++;
			 #print "This residue substr($aa,$i,1)  is not a standard residue! Check here. \n";
			 next;
		 }	 
		 $ex_all+=$exposed[$i];          
		 if($aa_polar{substr($aa,$i,1)} == 0)
		 {# this is a nonpolar residue
			 $ex_non+=$exposed[$i];
		 }
	 }
	 if($ex_all == 0)
	 {
######### I only get few models which dssp cannot parse, because the pdb format is not correct! To make it simple, I give these model -1, it may influence a little bit about the final performance #####
		 print "Warning! Error, check $aa and $sol, no residue inside!\n";
		 return -1;
		 #exit(0);
	 }
	 my($quality)=$ex_non/$ex_all;
	 $quality=$quality*($index-$num_skip)/$index;
	 return $quality;
 }

 sub cal_local_weighted_exposed($$) 
 {
	 my($aa,$sol)=@_;           # the amino acid and solvent accessibility
     my(@tem_split);
	 
	 my(@exposed)=split(/\_/,$sol);                   # exposed area for each residue
	                
     my($ex_non)=0;           # the total exposed area of residue
	 my($ex_all)=0;           # the total area of residues
	 my($index)=length($aa);
	 my($i);
	 my($num_skip)=0;


	 for($i=0;$i<$index;$i++)
	 {
		 if(not exists $aa_mass{substr($aa,$i,1)})
		 {
			 $num_skip++;
			 #print "This residue substr($aa,$i,1)  is not a standard residue! Check here. \n";
			 next;
		 }

		 $ex_non+=$exposed[$i]*$aa_mass{substr($aa,$i,1)};          
		 $ex_all+=$accth2{substr($aa,$i,1)}*$aa_mass{substr($aa,$i,1)};     
	 }
	 if($ex_all == 0)
	 {
######### I only get few models which dssp cannot parse, because the pdb format is not correct! To make it simple, I give these model -1, it may influence a little bit about the final performance #####
		 print "Warning! Error, check $aa,$sol, no residue inside!\n";
		 return -1;
		 #exit(0);
	 }
	 my($quality)=$ex_non/$ex_all;
	 $quality=$quality*($index-$num_skip)/$index;
	 $quality=1-$quality;
	 return $quality;
 }

 sub cal_local_total_surface($$)
 {
	 my($aa,$sol)=@_;           # the amino acid and solvent accessibility
	 
	 my($IN,$line);
     my(@tem_split);
	 
	 my(@exposed)=split(/\_/,$sol);                   # exposed area for each residue
	                
     my($ex_non)=0;           # the total exposed area of residue
	 my($ex_all)=0;           # the total area of residues
	 my($index)=length($aa);
	 my($i);
	 my($num_skip)=0;
	 for($i=0;$i<$index;$i++)
	 {
		 if(not exists $aa_mass{substr($aa,$i,1)})
		 {
			 $num_skip++;
			 #print "This residue substr($aa,$i,1)  is not a standard residue! Check here. \n";
			 next;
		 }

		 $ex_non+=$exposed[$i];          
		 $ex_all+=$accth2{substr($aa,$i,1)};     
	 }
	 if($ex_all == 0)
	 {
######### I only get few models which dssp cannot parse, because the pdb format is not correct! To make it simple, I give these model -1, it may influence a little bit about the final performance #####
		 print "Warning! Error, check $aa and $sol, no residue inside!\n";
		 return -1;
		 #exit(0);
	 }
	 my($quality)=$ex_non/$ex_all;
	 $quality=$quality*($index-$num_skip)/$index;
	 $quality=1-$quality;
	 return $quality;
 }

 sub convert_RMSD_to_score($)                     # convert the RMSD value of a residue to the score in the range [0,1].
 {# we use the S score, if RMSD > 15, we set as -1, otherwise, we use Si = 1/(1+(di/d0)*(di/d0)), d0 is set to sqrt(5)
	 my($value)=@_;
	 if($value > 15)
	 {
		 #$value = 15;
		 $value = -1;               # for the training, we don't use the one larger than 15. 
	 }
	 if($value < 0)
	 {
		 if($value == -1)
		 {
			 return -1;
		 }
		 print "Warning, the RMSD value should be larger than 0 !!! check $value\n";
		 $value=0;
	 }
	 my($d0)=sqrt(5);
	 my($score)=($value/$d0)*($value/$d0);
	 $score = 1/(1+$score);
	 return $score;
 }
 sub convert_score_to_RMSD($)                      # convert the score [0,1] to the RMSD value
 {
	 my($score)=@_;
	 if($score<0 || $score >1)
	 {
		 print "Severe warning, the score should be in the range [0,1], check $score!\n";
		 if($score<0) 
		 {
			 $score=0;
		 }
		 if($score>1) 
		 {
			 $score=1;
		 }		 
	 }
	 my($value);
	 my($d0)=sqrt(5);
	 if($score == 0)
	 {
         $value = 15;
	 }
	 else
	 {
		 $value = $d0*sqrt((1-$score)/$score);
	 }
         if($value > 15)
         {
            $value = 15;
         }
	 return $value;
 }
