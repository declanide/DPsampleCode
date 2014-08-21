 #require "common_config.pl";
 
 sub pause {
	print "\nPAUSE: ";
	unless (@_ == 0) {print $_[0];}
	print "\n";
	
	while ($cmd = <STDIN>){	
		if ($cmd) {
			print "CONTINUE\n";	
			last;
		}
	}
	
}


sub cat {
	my (@files) = @_;
	open (OUT,$wstyle.$dstf)||die("can not open file $dstf for writting: ".$!);
	foreach(@files){
		my $filestr ="";
		open (IN,"<".$_)||die("can not open file $dstf for reading: ".$!);
		$filestr = join "",<IN>;
		close(IN);
		print $filestr;
	}
	close(OUT);
}

sub ls {
	my ($dir,$pattern,$wstyle,$scpfile,$errinfo) = @_;
	if (@_<4){
		print "ls usage: dir, pattern, writte style [>|\>\>], output scp file,[error information]\n";
		exit(0);
	}
	open (SCP,">".$scpfile)||die("can not open file ".$scpfile." for writting: ".$!);
	opendir DIR, $dir or die "Cannot open ".$dir." and ".$errinfo.": ".$!;
	while (my $name = readdir DIR) {
		#next if $name =~ /^\./; 		   				#跳过点文件
		next unless $name =~ /$pattern/; # 跳过非目标文件
		$name = $dir."/".$name; 		#加上目录名
		print SCP $name;		
	}
	close SCP;
	closedir DIR;	
}



sub single_training {
	if (@_ < 4){
		print "$0 usage: dst_folder, org_folder, train_label, hmmlist, [minimum examples of each models], bintxt[bin|text], [trainlist]\n";
	}
	my($dst_fold, $org_fold, $label, $hmmlist, $mini_examp, $bintxt, $trainlist) = @_;	

	my $extra_op = "-B ";
	$extra_op = "" if ($bintxt eq "text");
	$extra_op = $extra_op."-m ".$mini_examp." " if ($mini_examp);
	
	my $cmd;	
	$cmd = join(
		" ",
		"HERest -T 1 -D",
		"-C ".$CONFIG,			
		"-I ".$label,
		"-S ".$TRAINLIST_FEA,
		$extra_op,
		"-t 250.0 150.0 1000.0",			
		"-H ".$org_fold."/macros",
		"-H ".$org_fold."/hmmdefs",
		"-M ".$dst_fold,
		#"-s ".$org_fold."/stats",
		$hmmlist.">".$dst_fold."/HERest.log");	
	if ($trainlist){
		$cmd =~ s/$TRAINLIST_FEA/$trainlist/gi;
	}	
	system($cmd);		
}

sub create_fold {
	use File::Path 'mkpath';
	my ($fold,$style, $extra_str) = @_;
	
	#my $inhmm_fold = $HMM_ROOT."/hmm0024_".$wi_cro;
	#my $outhmm_fold = $HMM_ROOT."/hmm0100_".$wi_cro; 
	if ($style eq "tree"){
		unless(-e $fold) {
			mkpath($fold, {verbose => 1, mode => 0777})or die ("error:$extra_str\nCannot mkpath ".$fold.": ".$!);
			#mkpath($fold)|| die "Func $extra_str: Cannot mkpath ".$fold.": ".$!;
		}	 
	}else{
		unless(-e $fold) {
			mkdir($fold, 0777)|| die("Func $extra_str: Cannot mkdir ".$fold.": ".$!);
		}
	}		
	print "...has created fold: ".$fold."\n";
}

sub muti_mkdir {
	use File::Path;
	my ($style, $errinfo, @folds) = @_;
	
	#my $inhmm_fold = $HMM_ROOT."/hmm0024_".$wi_cro;
	#my $outhmm_fold = $HMM_ROOT."/hmm0100_".$wi_cro; 
	foreach my $fold(@folds){
		if ($style eq "tree"){
			unless(-e $fold) {
				mkpath($fold, 0777)||die "muti_mkdir cannot mkpath ".$fold.": ".$!;
				print "problem may be $errinfo\n";
			}	 
		}else{
			unless(-e $fold) {
				mkdir($fold, 0777)||die "muti_mkdir cannot mkdir ".$fold.": ".$!;
				print "problem may be $errinfo\n";
			}
		}		
		print "...has created fold: ".$fold."\n";
	}
}


sub movecopy_dir {
	use File::Copy;
	use File::Basename;
	my ($op, $org, $dst,$ifmkdir) = @_;
	my $orifold = basename $org;
	if ($ifmkdir eq "mkdir"){		
		$org = $org."/".$orifold;
		create_fold($org);
	}else{		
		print "move files in $org to $dst and do not make dir $orifold in the $dst\n";
	}
	opendir DIR, $org or die "Cannot open $org: $!";
		while (my $name = readdir DIR) {
		next if $name =~ /^\./; #跳过点文件
		$name = "$org/$name"; #加上目录名
		if ($op eq "move"){
			move($name,$dst)||die("can not move $name to $dst: ".$!);
		}elsif ($op eq "copy"){
			copy($name,$dst)||die("can not move $name to $dst: ".$!);
		}
	}
}

1;





