#!/usr/bin/perl -w
 use FileHandle; # use FileHandles instead of open(),close()
 use Cwd;
 use Cwd 'abs_path';

######################## !!! customize settings here !!! ############################
#																					#
# Set directory of DeepRank databases and tools								        #

$DeepRank_db_tools_dir = "/home/jianliu/DeepRank3/DeepRank_db_tools/";							        

######################## !!! End of customize settings !!! ##########################

######################## !!! Don't Change the code below##############


$install_dir = getcwd;
$install_dir=abs_path($install_dir);


if(!-s $install_dir)
{
	die "The DeepRank directory ($install_dir) is not existing, please revise the customize settings part inside the configure.pl, set the path as  your unzipped DeepRank directory\n";
}

if(!-d $DeepRank_db_tools_dir)
{
	die "The DeepRank databases/tools folder ($DeepRank_db_tools_dir) is not existing\n";
}

if ( substr($install_dir, length($install_dir) - 1, 1) ne "/" )
{
        $install_dir .= "/";
}

if ( substr($DeepRank_db_tools_dir, length($DeepRank_db_tools_dir) - 1, 1) ne "/" )
{
        $DeepRank_db_tools_dir .= "/";
}



print "checking whether the configuration file run in the installation folder ...";
$cur_dir = `pwd`;
chomp $cur_dir;
$configure_file = "$cur_dir/configure.pl";
if (! -f $configure_file || $install_dir ne "$cur_dir/")
{
        die "\nPlease check the installation directory setting and run the configure program under the main directory of DeepRank.\n";
}
print " OK!\n";



if (! -d $install_dir)
{
	die "can't find installation directory.\n";
}
if ( substr($install_dir, length($install_dir) - 1, 1) ne "/" )
{
	$install_dir .= "/"; 
}


######### check the DeepRank database and tools

$database_dir = "$DeepRank_db_tools_dir/databases";
$tools_dir = "$DeepRank_db_tools_dir/tools";

if(!(-d $database_dir) or !(-d $tools_dir))
{
	die "Failed to find databases and tools under $DeepRank_db_tools_dir/\n";
}

if($DeepRank_db_tools_dir eq "$cur_dir/")
{
	die "Same directory as DeepRank main folder. Differnt path for original databases/tools folder $DeepRank_db_tools_dir is recommended.\n";
}
#create link for databases and tools
`rm ${install_dir}databases`; 
`rm ${install_dir}tools`; 
`ln -s $database_dir ${install_dir}databases`;
`ln -s $tools_dir ${install_dir}tools`;


if (prompt_yn("DeepRank will be installed into <$install_dir> ")){

}else{
	die "The installation is cancelled!\n";
}
print "Start install DeepRank into <$install_dir>\n"; 

print "\n#########Configuring tools\n";
-d "${install_dir}tools/DistRank"  || `mv ${install_dir}installation/DistRank ${install_dir}tools`;

print "\n#########Configuring scripts\n";

$option_list = "$install_dir/installation/DeepRank_configure_files/DeepRank_scripts_list";

if (! -f $option_list)
{
        die "\nOption file $option_list not exists.\n";
}
configure_file2($option_list,'src');
print "#########  Configuring scripts, done\n\n";


system("cp $install_dir/src/DeepRank3*.sh $install_dir/bin");
system("chmod +x $install_dir/bin/DeepRank3*.sh");


sub prompt_yn {
  my ($query) = @_;
  my $answer = prompt("$query (Y/N): ");
  return lc($answer) eq 'y';
}
sub prompt {
  my ($query) = @_; # take a prompt string as argument
  local $| = 1; # activate autoflush to immediately show the prompt
  print $query;
  chomp(my $answer = <STDIN>);
  return $answer;
}


sub configure_file{
	my ($option_list,$prefix) = @_;
	open(IN,$option_list) || die "Failed to open file $option_list\n";
	$file_indx=0;
	while(<IN>)
	{
		$file = $_;
		chomp $file;
		if ($file =~ /^$prefix/)
		{
			$option_default = $install_dir.$file.'.default';
			$option_new = $install_dir.$file;
			$file_indx++;
			print "$file_indx: Configuring $option_new\n";
			if (! -f $option_default)
			{
					die "\nOption file $option_default not exists.\n";
			}	
			
			open(IN1,$option_default) || die "Failed to open file $option_default\n";
			open(OUT1,">$option_new") || die "Failed to open file $option_new\n";
			while(<IN1>)
			{
				$line = $_;
				chomp $line;

				if(index($line,'SOFTWARE_PATH')>=0)
				{
					$line =~ s/SOFTWARE_PATH/$install_dir/g;
					$line =~ s/\/\//\//g;
					print OUT1 $line."\n";
				}else{
					print OUT1 $line."\n";
				}
			}
			close IN1;
			close OUT1;
		}
	}
	close IN;
}


sub configure_tools{
	my ($option_list,$prefix,$DBtool_path) = @_;
	open(IN,$option_list) || die "Failed to open file $option_list\n";
	$file_indx=0;
	while(<IN>)
	{
		$file = $_;
		chomp $file;
		if ($file =~ /^$prefix/)
		{
			$option_default = $DBtool_path.$file.'.default';
			$option_new = $DBtool_path.$file;
			$file_indx++;
			print "$file_indx: Configuring $option_new\n";
			if (! -f $option_default)
			{
					next;
					#die "\nOption file $option_default not exists.\n";
			}	
			
			open(IN1,$option_default) || die "Failed to open file $option_default\n";
			open(OUT1,">$option_new") || die "Failed to open file $option_new\n";
			while(<IN1>)
			{
				$line = $_;
				chomp $line;

				if(index($line,'SOFTWARE_PATH')>=0)
				{
					$line =~ s/SOFTWARE_PATH/$DBtool_path/g;
					$line =~ s/\/\//\//g;
					print OUT1 $line."\n";
				}else{
					print OUT1 $line."\n";
				}
			}
			close IN1;
			close OUT1;
		}
	}
	close IN;
}



sub configure_file2{
	my ($option_list,$prefix) = @_;
	open(IN,$option_list) || die "Failed to open file $option_list\n";
	$file_indx=0;
	while(<IN>)
	{
		$file = $_;
		chomp $file;
		if ($file =~ /^$prefix/)
		{
			@tmparr = split('/',$file);
			$filename = pop @tmparr;
			chomp $filename;
			$filepath = join('/',@tmparr);
			$option_default = $install_dir.$filepath.'/.'.$filename.'.default';
			$option_new = $install_dir.$file;
			$file_indx++;
			print "$file_indx: Configuring $option_new\n";
			if (! -f $option_default)
			{
					die "\nOption file $option_default not exists.\n";
			}	
			
			open(IN1,$option_default) || die "Failed to open file $option_default\n";
			open(OUT1,">$option_new") || die "Failed to open file $option_new\n";
			while(<IN1>)
			{
				$line = $_;
				chomp $line;

				if(index($line,'SOFTWARE_PATH')>=0)
				{
					$line =~ s/SOFTWARE_PATH/$install_dir/g;
					$line =~ s/\/\//\//g;
					print OUT1 $line."\n";
				}else{
					print OUT1 $line."\n";
				}
			}
			close IN1;
			close OUT1;
		}
	}
	close IN;
}





=pod
database downloading 


/home/casp13/DeepRank_package/software/prosys_database/cm_lib/chain_stx_info
/home/casp13/DeepRank_package/software/prosys_database/cm_lib/pdb_cm
/home/casp13/DeepRank_package/software/prosys_database/cm_lib/pdb_cm.phr
/home/casp13/DeepRank_package/software/prosys_database/cm_lib/pdb_cm.pin
/home/casp13/DeepRank_package/software/prosys_database/cm_lib/pdb_cm.psq
/home/casp13/DeepRank_package/software/prosys_database/cm_lib/pdb_cm_all_sel.fasta 


/home/casp13/DeepRank_package/software/prosys_database/atom.tar.gz

/home/casp13/DeepRank_package/software/prosys_database/nr_latest/



=cut
