#!/usr/bin/perl -w

$numArgs = @ARGV;
if($numArgs != 4)
{   
	print "the number of parameters is not correct!\n";
	exit(1);
}

$rrfile		= "$ARGV[0]"; 
$pdbdir	= "$ARGV[1]"; 
$target	= "$ARGV[2]";
$output_folder	= "$ARGV[3]"; 

if(!(-d $output_folder))
{
  `mkdir $output_folder`;
}


if(!(-e $rrfile))
{
  die "!!! Failed to find $rrfile\n\n";
}

opendir(DIR,$pdbdir) || die "Failed to open directory $pdbdir\n";
@pdbfiles = readdir(DIR);
closedir(DIR);

$workdir = "$output_folder/${target}_contact_energy";
if(!(-d $workdir))
{
  `mkdir $workdir`;
}
chdir($workdir);
`cp $rrfile $workdir/$target.dncon2.rr`;
`rm -f $workdir/$target.EVA` if (-f "$workdir/$target.EVA");
foreach $pdb  (@pdbfiles)
{
  chomp $pdb;
  if($pdb eq '.' or $pdb eq '..')
  {
    next;
  }
  $pdb_file = "$pdbdir/$pdb";
  
  `cp $pdb_file $workdir/$pdb`;
  
  `perl /home/jianliu/DeepRank3/src/scripts/get_dncon2_3_levels_info.pl -rr $target.dncon2.rr -pdb $pdb -smin 6 -smax 11`;
  `perl /home/jianliu/DeepRank3/src/scripts/get_dncon2_3_levels_info.pl -rr $target.dncon2.rr -pdb $pdb -smin 12 -smax 23`;
  `perl /home/jianliu/DeepRank3/src/scripts/get_dncon2_3_levels_info.pl -rr $target.dncon2.rr -pdb $pdb -smin 24 -smax 10000`;
  
  `rm $workdir/$pdb`;
}


$eva_file = "$workdir/$target.EVA";
open(IN,$eva_file) || die "Failed to find $eva_file\n";
%rr_short_score =();
%rr_medium_score =();
%rr_long_score =();
while(<IN>)
{
$line= $_;
chomp $line;
@tmp = split(':',$line);
$mod = $tmp[0];
$type = $tmp[1];
$score = $tmp[2];

if($type eq 'Short-range')
{
  $rr_short_score{$mod} = $score/100
}

if($type eq 'Long-range')
{
  $rr_long_score{$mod} = $score/100
}

if($type eq 'Medium-range')
{
  $rr_medium_score{$mod} = $score/100
}

}
close IN;


open(SHORT,">$workdir/$target.short-range") || die "Failed to find $workdir/$target.short-range\n";
open(MEDIUM,">$workdir/$target.medium-range") || die "Failed to find $workdir/$target.medium-range\n";
open(LONG,">$workdir/$target.long-range") || die "Failed to find $workdir/$target.long-range\n";

opendir(DIR,$pdbdir) || die "Failed to open directory $pdbdir\n";
@pdbfiles = readdir(DIR);
closedir(DIR);
foreach $pdbmod  (@pdbfiles)
{
	chomp $pdbmod;
	if($pdbmod eq '.' or $pdbmod eq '..')
	{
	  next;
	}
	 if(!exists($rr_short_score{$pdbmod}))
	 {
	   print "Failed to find $pdbmod in short range <$eva_file>, set to 0\n";
	   print SHORT "$pdbmod\t0\n";
	 }else{
	   print SHORT "$pdbmod\t".$rr_short_score{$pdbmod}."\n";
	 }
	 
	 if(!exists($rr_medium_score{$pdbmod}))
	 {
	   print "Failed to find $pdbmod in medium range <$eva_file>, set to 0\n";
	   print MEDIUM "$pdbmod\t0\n";
	 }else{
	   print MEDIUM "$pdbmod\t".$rr_medium_score{$pdbmod}."\n";
	 }
	 
	 
	 if(!exists($rr_long_score{$pdbmod}))
	 {
	   print "Failed to find $pdbmod in long range <$eva_file>, set to 0\n";
	   print LONG "$pdbmod\t0\n";
	 }else{
	   print LONG "$pdbmod\t".$rr_long_score{$pdbmod}."\n";
	 }
 
}

close SHORT;
close MEDIUM;
close LONG;
