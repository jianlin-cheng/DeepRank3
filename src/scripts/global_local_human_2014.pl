#!/usr/bin/perl -w

#same as global_local_human_coarse_new.pl except that scwrl is used
#to refine side chains.

if (@ARGV != 6)
{
        print "perl $0 /home/casp11/casp12/tools/HUMAN/scripts /home/casp11/casp12/tools/HUMAN/tools ../data/filtered-T0759 ../fasta/T0759.fasta ../final_ranking/T0759.ranking ../result/T0759_selected\n";
	die "need six parameters: HUMAN server script folder, HUMAN server tool folder, casp model dir, fasta file, model scoring file (ave by eva and energy), output dir.\n";
}

use Cwd 'abs_path';

$H_script = shift @ARGV;
$H_tool = shift @ARGV;

$casp_model_dir = shift @ARGV;
-d $casp_model_dir || die "can't find $casp_model_dir";
$casp_model_dir = abs_path($casp_model_dir);

$fasta_file = shift @ARGV;
-f $fasta_file || die "can't find $fasta_file.\n";
$model_score = shift @ARGV;
-f $model_score || die "can't find $model_score.\n";
$output_dir = shift @ARGV;
-d $output_dir || die "can't find $output_dir.\n";

open(FASTA, $fasta_file) || die "can't read $fasta_file.\n";
$name = <FASTA>;
close FASTA;
chomp $name;
$name = substr($name, 1);

$count = 1;
while ($count <= 9)
{
	print "generate model $count...\n";
	`cp $model_score $name.score`;
	if ($count > 1)
	{
		open(SCORE, $model_score);	
		@score = <SCORE>;
		close SCORE;
		
		for ($i = 0; $i < @score; $i++)
		{
			$line = $score[$i];
			if ($line =~ /^PFRMAT / || $line =~ /^TARGET / || $line =~ /^MODEL / || $line =~ /^QMODE / || $line =~ /^END/ || $line =~ /^AUTHOR / || $line =~ /^METHOD /)
			{
				;
			}
			else
			{
				last;
			}
		}
	
		#exchange models
		$cur = $i;
		$tar = $i + $count - 1;
		$tmp = $score[$cur];
		$score[$i] = $score[$tar];
		$score[$tar] = $tmp;
		
		open(SCORE, ">$name.score");
		print SCORE join("", @score);
		close SCORE;
	}

	print "do model combination...\n";

#print "$H_script/stx_model_comb_global.pl $H_tool/TMscore_32 $casp_model_dir $name.score $fasta_file $output_dir/$name.pir 4 0.8 0.7\n";
	#system("/home/chengji/casp8/model_cluster/script/stx_model_comb_global.pl /home/chengji/software/tm_score/TMscore_32 $casp_model_dir $name.score $fasta_file $output_dir/$name.pir 3.5 0.8 0.5");
	#system("/home/chengji/casp8/model_cluster/script/stx_model_comb_global.pl /home/chengji/software/tm_score/TMscore_32 $casp_model_dir $name.score $fasta_file $output_dir/$name.pir 4 0.8 0.5");
	system("$H_script/stx_model_comb_global.pl $H_tool/TMscore_32 $casp_model_dir $name.score $fasta_file $output_dir/$name.pir 4 0.8 0.7");


	open(PIR, "$output_dir/$name.pir") || die "can't read $output_dir/$name.pir\n";
	@pir = <PIR>;
	close PIR;
	$length = 80;

	#$gdt = 0.5;
	$gdt = 0.6;
	
	while (@pir < 10)
	{
		print "Less than two templates, do local model combination...\n";
		#system("/home/chengji/casp8/model_cluster/script/stx_model_comb.pl /home/chengji/software/tm_score/TMscore_32 $casp_model_dir $name.score $fasta_file $output_dir/$name.pir 2.5 $length $gdt");
		system("$H_script/stx_model_comb.pl $H_tool/TMscore_32 $casp_model_dir $name.score $fasta_file $output_dir/$name.pir 3 $length $gdt");

		open(PIR, "$output_dir/$name.pir") || die "can't read $output_dir/$name.pir\n";
		@pir = <PIR>;
		close PIR;

		$length -= 5;
		$gdt -= 0.02;
		if ($length <= 0 || $gdt <= 0)
		{
			print "not able to get a local alignment.\n";
			last;
		}
	}

	print "generate model...\n";
#	print "$H_script/pir2ts_energy_9v7.pl $H_tool/modeller-9.15/ $casp_model_dir $output_dir $output_dir/$name.pir 8\n";

	#system("/home/chengji/casp8/model_cluster/script/pir2ts_energy.pl /home/chengji/software/prosys/modeller7v7/ $casp_model_dir $output_dir $output_dir/$name.pir 3");
	#system("/home/chengji/casp8/model_cluster/script/pir2ts_energy_9v7.pl /home/chengji/software/modeller9v7/ $casp_model_dir $output_dir $output_dir/$name.pir 5");
	system("$H_script/pir2ts_energy_9v7.pl $H_tool/modeller-9.15/ $casp_model_dir $output_dir $output_dir/$name.pir 8");
    
		

	`mv $output_dir/$name.pir $output_dir/$name-$count.pir`;
	`mv $output_dir/$name.pdb $output_dir/$name-$count.pdb`;
	
	#using scwrl
	#disable scwrl
#	system("/home/chengji/software/scwrl4/Scwrl4 -i $output_dir/$name-$count.pdb -o $output_dir/$name-$count-s.pdb >/dev/null");
        system("cp $output_dir/$name-$count.pdb $output_dir/$name-$count-s.pdb");       # copy the model

	#clash check
	if (-f "$output_dir/$name-$count-s.pdb")
	{
		system("$H_script/clash_check.pl $fasta_file $output_dir/$name-$count-s.pdb > $output_dir/clash$count.txt"); 
		system("$H_script/pdb2casp.pl $output_dir/$name-$count-s.pdb $count $name $output_dir/casp$count.pdb");
	}
	else
	{
		system("$H_script/clash_check.pl $fasta_file $output_dir/$name-$count.pdb > $output_dir/clash$count.txt"); 
		system("$H_script/pdb2casp.pl $output_dir/$name-$count.pdb $count $name $output_dir/casp$count.pdb");
	}

	$count++;

	`rm $name.score`;
}




