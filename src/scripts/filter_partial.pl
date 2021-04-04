#!/usr/bin/perl -w
############################################################
#filter out partial models
#Author: Jianlin Cheng
#Revised by Renzhi at 12/21/2015
#Date: 5/15/2010
############################################################

if (@ARGV != 5)
{
        print "such as : perl $0 pdb2seq.pl /home/casp11_human/casp10_qa_pairwise/fasta/T0763.fasta ../all_scores/T0763_scores/ranking.txt /home/casp11_human/casp10_qa_pairwise/T0763/ren_filtered_model ../all_scores/T0763_scores/combined_ranking.txt\n";
	die "need four parameters: fasta file, model score file, model dir, output_filtered_score_file\n";
}

$pdb2seq = shift @ARGV;
$fasta_file = shift @ARGV;
$score_file = shift @ARGV;
$model_dir  = shift @ARGV;
$new_score = shift @ARGV;

open(FASTA, $fasta_file) || die "can't read $fasta_file.\n";
<FASTA>;
$seq = <FASTA>;
chomp $seq; 
close FASTA;

open(SCORE, $score_file) || die "can't read $score_file.\n";
@score = <SCORE>;
close SCORE;

open(OUT, ">$new_score");


while (@score)
{
	$line = shift @score;
	if ($line =~ /^END/)
	{
		print OUT $line; 
		last;
	}
	@fields = split(/\s+/, $line);
	$model = $fields[0]; 
	$model_file = "$model_dir/$model";
	if(!-s $model_file)
	{
		next;
	}
	$mseq = `perl $pdb2seq $model_file`; 	
	chomp $mseq; 
    
	if ($seq eq $mseq)
	{
		print OUT $line; 
	}
}

close OUT; 






