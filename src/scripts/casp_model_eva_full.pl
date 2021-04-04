#!/usr/bin/perl -w
##########################################################################
#Evaluate CASP models using model_evalutor                               #
#Inputs (6): betacon dir, model_eva dir,                                 #
#Target FASTA sequence, 1D and 2D feature dir,                           # 
#CASP model dir, and output file.                                        #
#Output: CASP QA format                                                  #
#Author: Jianlin Cheng                                                   #
#Date: 10/10/2007                                                        #
##########################################################################

if (@ARGV != 6)
{
	die "need six parameters: betacon dir, model_eva dir, target FASA sequence, 1D and 2D feature dir, CASP model dir, output file name.\n";
}

$betacon_dir = shift @ARGV;
-d $betacon_dir || die "$betacon_dir does not exist.\n";
$model_eva_dir = shift @ARGV;
-d $model_eva_dir || die "$model_eva_dir does not exist.\n";

$fasta_file = shift @ARGV;
-f $fasta_file || die "$fasta_file does not exist.\n";
open(FASTA, $fasta_file);
$target_name = <FASTA>;
chomp $target_name;
$target_name = substr($target_name, 1);
close FASTA;

$feature_dir = shift @ARGV;
-d $feature_dir || die "$feature_dir does not exist.\n";

$model_dir = shift @ARGV;
-d $model_dir || die "$model_dir does not exist.\n";

$output_file = shift @ARGV;

opendir(MODEL, $model_dir) || die "can't open $model_dir.\n";
@models = readdir(MODEL);
close MODEL;

open(CASP, ">$output_file") || die "can't create $output_file.\n";


print CASP "PFRMAT QA\n";
print CASP "TARGET $target_name\n"; 
print CASP "MODEL 1\n";
print CASP "QMODE 1\n";

@to_do_models = ();
@to_do_files = ();

@eva_models = ();
@eva_scores = ();

while (@models)
{
	$model = shift @models;
	if ($model eq "." || $model eq "..")
	{
		next; 
	}

	$model_file = "$model_dir/$model";
       
        $model_name = $model;

=pod
	if ($model !~ /\.pdb$/)
	{
		$model_name = $model;
	}
	else
	{
		$model_name = substr($model, 0, length($model) - 4);		
	}
=cut

	#run model evaluator on each model
	$out = `$model_eva_dir/bin/model_eval.sh $fasta_file $feature_dir  $model_file 2>/dev/null`; 

	if ($out !~ /\n/)
	{
		$out .= "\n";
	}

	#check if the scores are generated
	$new_out = $out;
	chomp $new_out;

	@fields = split(/:/, $new_out);
	if ($fields[1] !~ /\d+/)
	{
		print "no score is generated for $model_name.\n";		
		push @to_do_models, $model_name;
		push @to_do_files, $model_file;
		`rm $model_file.dssp $model_file.set`; 
	}
	else
	{
		push @eva_models, $model_name;
		push @eva_scores, $fields[1];  
#		print CASP "$model_name $fields[1]\n";
	}

	print "$model_name $out";

}

#sort models by scores
$num = @eva_scores;
for ($i = $num - 1; $i > 0; $i--)
{
	for ($j = 0; $j < $i; $j++)
	{
		if ($eva_scores[$j] < $eva_scores[$j+1])
		{
			$tmp = $eva_scores[$j];
			$eva_scores[$j] = $eva_scores[$j+1];
			$eva_scores[$j+1] = $tmp;

			$tmp = $eva_models[$j];
			$eva_models[$j] = $eva_models[$j+1];
			$eva_models[$j+1] = $tmp;
		}
	}
}

for ($i = 0; $i < $num; $i++)
{
	print CASP "$eva_models[$i] $eva_scores[$i]\n";
}

print CASP "END\n";
close CASP;

