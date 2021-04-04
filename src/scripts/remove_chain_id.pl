#!/usr/bin/perl -w
#Remove chain id from casp models

if (@ARGV != 1)
{
	die "need one parameter: model dir.\n";
}

$model_dir = shift @ARGV;
opendir(DIR, $model_dir) || die "can't read $model_dir.\n"; 
@files = readdir DIR;
closedir DIR;

while (@files)
{
	$file = shift @files;
	if ($file eq "." || $file eq "..")
	{
		next;
	}

	$model_file = $model_dir . "/$file";	
	open(PDB, $model_file) || die "can't read $model_file.\n";
	@pdb = <PDB>;
	close PDB; 	
	
	open(PDB, ">$model_file");
	foreach $line (@pdb)
	{
		if ($line =~ /^ATOM/)
		{
			if (substr($line, 21, 1) ne " ")
			{
				$line = substr($line, 0, 21) . " " . substr($line, 22); 
			}	
			print PDB $line;
		}
		else
		{
			print PDB $line;
		}
	}	
	close PDB; 
}



