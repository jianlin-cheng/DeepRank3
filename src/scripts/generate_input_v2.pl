#!/usr/bin/perl -w
################################################################################
#Generate input files for ModelEvaluator2
#Inputs: betacon dir, pspro2 dir, dispro dir, query fasta sequence, output dir  
################################################################################

if (@ARGV != 5)
{
	die "need five parameters: betacon dir, pspro2 dir, dispro dir, query fasta sequence, and output dir.\n";
}

$betacon_dir = shift @ARGV;
-d $betacon_dir || die "can't read $betacon_dir.\n";

$pspro2_dir = shift @ARGV;
-d $pspro2_dir || die "can't read $pspro2_dir.\n";

$dispro_dir = shift @ARGV;
-d $dispro_dir || die "can't read $dispro_dir.\n";

$fasta_file = shift @ARGV;
-f $fasta_file || die "can't read $fasta_file.\n";
open(FASTA, $fasta_file) || die "can't read $fasta_file.\n";
$name = <FASTA>;
close FASTA;
chomp $name;
$name = substr($name, 1); 

$output_dir = shift @ARGV;
-d $output_dir || die "can't read $output_dir.\n";

#generate secondary structure, solvent accessibility, contact map, betasheet topology first
print "Generate predictions of secondary structure, solvent accessibility, contacts and beta sheet topology...\n";
system("$betacon_dir/bin/beta_contact_map.sh $fasta_file $output_dir"); 

#generate 20-threshold solvent accessibility and alignment file
system("$pspro2_dir/bin/predict_sa_multi.sh $fasta_file $output_dir"); 

#extract sequence file name
$slash_pos = rindex($fasta_file, "/");
if ($slash_pos != -1)
{
        $output_filename = substr($fasta_file, $slash_pos + 1, length($fasta_file) - $slash_pos - 1);
}
else
{
        $output_filename = $fasta_file;
}
if (length($output_filename) <= 0)
{
        die "sequence file name shouldn't be less or equal 0.\n";
}

#non-char and . is not allowed for ouput file name 
$output_filename =~ s/\s/_/g;
$output_filename =~ s/\./_/g;
#generate disorder predictions
print "Generate disorder predictions...\n";
system("$dispro_dir/bin/predict_diso.sh $fasta_file $output_filename.diso");
`mv $output_filename.diso $output_dir`; 
`rm $output_filename.diso.*`; 



