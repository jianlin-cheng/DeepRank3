#!/usr/bin/perl
###############################################
#Detect for scientific notation and convert it
#into decimal.
#
#Zheng Wang, May 17th, 2010.
###############################################

use strict;

my $in_file = $ARGV[0];

open(IN, "<$in_file");
my @lines = <IN>;
my @outs;
foreach my $line (@lines){
	if($line =~ /PFRMAT/ || $line =~ /TARGET/ || $line =~ /QMODE/ || $line =~ /END/){
		push(@outs, $line);
		next;
	}
	my @items = split(/\s+/, $line);
	if($items[1] =~ /e/){
		$items[1] =~ s/\n//;
		my $temp = sprintf("%.8f", $items[1]);
		my $new_line = $items[0].'  '.$temp."\n";
		push(@outs, $new_line);
	}
	else{
		push(@outs, $line);
	}
}
close(IN);

`rm $in_file`;
open(OUT, ">$in_file");
foreach my $line (@outs){
	print OUT $line;
}
close(OUT);
