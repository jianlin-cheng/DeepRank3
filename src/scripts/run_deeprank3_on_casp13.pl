$infolder = "$ARGV[0]";
$outfolder = "$ARGV[1]";

opendir(DIR,"$infolder") || die "Failed to open dir $infolder";
@files = readdir(DIR);
closedir(DIR);

chdir($outfolder);
$cur_run = 0;
foreach $file (@files)
{
	if($file eq '.' or $file eq '..' or index($file ,'.pdb')<0)
	{
		next;
	}
	$name = substr($file,0,index($file,'.pdb'));
	print "Running $name\n\n";

	$distmap = "/home/casp14/casp14_qa/CASP8-13_Contact_Dist/deepdist/${name}.txt";
	$rrfile = "/home/casp14/casp14_qa/CASP8-13_Contact_Dist/contact/${name}.rr";
	$seqfile = "/home/casp14/casp14_qa/data/casp13_seq/$name.fasta";
	if(!(-e $distmap) or !($rrfile) or !($seqfile))
	{
		next;
	}
   	if(-e "/home/casp14/casp14_qa/test/${name}_out/DeepRank3_SingleQA_lite.txt")	
	{
		print "/home/casp14/casp14_qa/test/${name}_out/DeepRank3_SingleQA_lite.txt already generated, pass\n";
		next;
	}
	print "sh /home/casp14/casp14_qa/bin/DeepRank3_SingleQA_lite.sh $name /home/casp14/casp14_qa/data/casp13_seq/$name.fasta /home/casp14/casp14_qa/data/CASP_models/casp13_server_models/$name /home/casp14/casp14_qa/test/${name}_out /home/casp14/casp14_qa/CASP8-13_Contact_Dist/contact/${name}.rr  /home/casp14/casp14_qa/CASP8-13_Contact_Dist/deepdist/${name}.txt &> ${name}.log\n\n";
	`sh /home/casp14/casp14_qa/bin/DeepRank3_SingleQA_lite.sh $name /home/casp14/casp14_qa/data/casp13_seq/$name.fasta /home/casp14/casp14_qa/data/CASP_models/casp13_server_models/$name /home/casp14/casp14_qa/test/${name}_out /home/casp14/casp14_qa/CASP8-13_Contact_Dist/contact/${name}.rr  /home/casp14/casp14_qa/CASP8-13_Contact_Dist/deepdist/${name}.txt &> ${name}.log &`;
	$cur_run++;
	if($cur_run>6)
	{
		last;
	}
}
