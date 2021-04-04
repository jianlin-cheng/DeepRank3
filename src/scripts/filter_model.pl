#!/usr/bin/perl -w
#########################################################
#Preprocess the models for q_score.cpp. This program
#remove all the illegal lines besides PDB format needed
#ones.
#
#Zheng Wang, Feb 9th, 2010.
#Modified by Jianlin Cheng, 4/21/2010
#########################################################


use strict;

my $list_file = $ARGV[0];    #model list file
my $output_dir = $ARGV[1];

open(LIST, "<$list_file");
while(<LIST>){
	my $line = $_;
	if($line =~ /#/){
		next;
	}
	$line =~ s/\n//;
	my $index = rindex($line, "/");
	my $name = substr($line, ($index + 1));
	#print $name."\n";
	open(OUT, ">$output_dir/$name");
	#print OUT "PFRMAT TS\nTARGET TXXXX\nMODEL X\nPARENT XXXX\n";
	open(IN, "<$line");
	my $count = 0; 
	while(<IN>){
		my $line_model = $_;
		$count++; 
		if ($count <= 4)
		{
			if ($line_model =~ /^PFRMAT/ || $line_model =~ /^TARGET/ || $line_model =~ /^MODEL/ || $line_model =~ /^PARENT/)
			{
				print OUT $line_model;	
			}
		}
		if(substr($line_model, 0, 3) eq "END" ){
			last;
		}
		if(substr($line_model, 0, 4) ne "ATOM"){
			next;
		}
		print OUT $line_model;	
	}
	close(IN);
	print OUT "TER\nEND\n";
	close(OUT);
}
close(LIST);
