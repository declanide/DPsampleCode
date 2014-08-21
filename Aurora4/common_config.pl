#$SYS			= "WIN";
#$SPLIT          = "\\";
#$RUNNUM         = 2;
#$ROOT 			= "D:/work/AuroraRun/myrun/experiments/go_flat_cross".$RUNNUM ;
#$COND 			= "clean";
#$EXEDOC 		= $ROOT."/exe_and_doc";
#$AUEXE    		= $EXEDOC."/AuroraExe";
##$EXE    		= $EXEDOC."/AuroraExe";
#$DOC    		= $EXEDOC."/doc";
#$CONFIG      	= $DOC."/config";

require "common.pl";

#$LIB    		= $ROOT."/lib";
$COND_FOLDER  	= $LIB."\/".$COND."\_mode";
$LOG    		= $LIB."/log";
$HMM_ROOT       = $COND_FOLDER."/HMM";
$RUNBAK    		= $LOG."/run_backup";
$RECOUT_FOLD   	= $LIB."/rec_out_fold";
$LATFOLD       	= $LIB."/lats";
$TIMELOG        = $LIB."/runtime.log";

$FEA_TRAIN_PATH = $FEAPATH."/train";
$FEA_TEST_PATH  = $FEAPATH."/test";
$FEA_DEV_PATH   = $FEAPATH."/dev";


#hmmlist lm mlf dict and so on

#type: cvp  --> WDNETCVP, DICTCVP; 
#type: cnvp --> WDNET, DICT;

#$WDNET     		= $LIB."/wdnet_bigram";
$WDNET     		= $LIB."/wdnet_dp3n";
$WDNETCVP       = $LIB."/wdnet_bigram_cvp";
#$WDNETCVP       = $LIB."/wdnet_dp3n";
$DICT           = $LIB."/dict_5k";
$DICTCVP        = $LIB."/dict5k_cvp";
$WORDS     		= $LIB."/words.mlf";
$PHONES0		= $LIB."/phones0\.mlf";
$PHONES1        = $LIB."/phones1\.mlf";

# 含有了fea的路径
$TESTWORDS1 	= $LIB."/nov92_words.mlf";
#去掉了fea的路径，其它和1都一样。
$TESTWORDS2		= $LIB."/nov92_words2.mlf";
# 去掉了fea的路径，不过是用 hled去掉的，所以，有些前面带斜杠的词，可能会被去掉。不过这种情况在test中没有，在这里设置，只是为了
$TESTWORDS3		= $LIB."/nov92_words3.mlf";

#dev 的情况和test的情况类似
# 普通的devwords1, mlf中的每个lab带有相应fea文件的完整路径
$DEVWORDS1		= $LIB."/dev92_words1.mlf";
# 去掉了fea的完整路径，其它和 dev  1 一样
$DEVWORDS2		= $LIB."/dev92_words2.mlf";
#用 hled去掉 fea的完整路径，这时一些以斜杠开头的单词可能会失去它们开头的斜杠
$DEVWORDS3		= $LIB."/dev92_words3.mlf";
#用perl编程的办法去掉了fea的路径，同时将以斜杠开头的单词变成表示“未知单词”的“单词”，这个“未知单词”是自定义的，比如<UNK>
$DEVWORDS4      = $LIB."/dev92_words4.mlf";

$MONOLIST1		= $LIB."/monophones1";
$MONOLIST0		= $LIB."/monophones0";
$ALIGNED        = $LIB."/aligned.mlf";
$ALIGNED2		= $LIB."/aligned2.mlf";
$TRIWORDS		= $LIB."/wintri.mlf";
$TRILIST1       = $LIB."/triphones1";
$FULLLIST       = $LIB."/fulllist";
$TIEDLIST		= $LIB."/tiedlist";

#scp and so on
$TRAINLIST_FEA 	= $LIB."/trainfea.scp";
$TRAINSCP       = $LIB."/train.scp";
$TESTSCP 		= $LIB."/nov92_test.scp";
$DEVSCP         = $LIB."/dev92_dev.scp";

#parametere and folders of training and evalulation 
$HEREST_SPLIT 	= 50;
$HEREST_THREADS = 4;
$HVITE_SPLIT    = 66;
$HVITE_THREADS  = 2;




#sph conver to wav
$LDC           	    = "D:/ldcsphtools";
$TRAIN_SPH2WAV_LOG  = $LOG."/sph2wav.log";
$TEST_SPH2WAV_LOG   = $LOG."/nov92_sph2wav.log";
$DEV_SPH2WAV_LOG	= $LOG."/dev92_sph2wav.log";


# tune  
$TUNE_SPLIT     = 12;
$TUNE_THREADS   = 4;

# tuen insertion penalty and lm scale. 
$TUNE_REC    = $LIB."/dev_tune_rec";
$TUNE_BESTPS_LOG= $LIB."/thebestps.log";
$TUNE_PS_LOOP   = 3;

#tune the tied top down 
$TUNE_MAIN  = $LIB."/dev_tune_tied";
$TUNE_RECOUT  = $TUNE_MAIN."/recout";
$TUNE_WORK    = $TUNE_MAIN."/work";
$TUNE_BAK     = $RUNBAK."/dev_tune_tied";
$TUNE_LAT     = $LATFOLD."/tune_tied_lats";
$TUNE_LOG     = $LIB."/thebestrotb.log";
$MODEL_STEP_PEN = 0.15;
#some previous recognition parameter values

$DEVLAT_FIRST_FOLD1 = $TUNE_LAT."/DevFirstLatFlatCross/R".$LATRO."T".$LATTB."P".$LATP."S".$LATS."PRU".$PRUNE1;
$DEVLAT_FIRST_FOLD2 = $TUNE_LAT."/DevFirstLatFlatCross/R".$LATRO."T".$LATTB."P".$LATP."S".$LATS."PRU".$PRUNE2;


#conf tune and 。。。
$CONF_MAIN    = $LIB."/confmain";
$CONF_TUNE	  = $CONF."/tune";









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
	my ($wstyle,$dstf,@files) = @_;
	open (OUT,$wstyle.$dstf)||die("can not open file $dstf for writting: ".$!);
	
	foreach(@files){	
		my $filestr ="";
		open (IN,"<".$_)||die("can not open file $_ for reading: ".$!);
		$filestr = join "",<IN>;
		close(IN);
		print OUT $filestr;
	}
	close(OUT);
}

sub ls {
	my ($dir,$pattern,$wstyle,$scpfile,$errinfo) = @_;
	if (@_<4){
		print "ls usage: dir, pattern, writte style [>|\>\>], output scp file,[error information]\n";
		exit(0);
	}
	#print $pattern."\n";
	open (SCP,$wstyle.$scpfile)||die("can not open file ".$scpfile." for writting: ".$!);
	opendir DIR, $dir or die "Cannot open ".$dir." and ".$errinfo.": ".$!;
	while (my $name = readdir DIR) {
		#next if $name =~ /^\./; 			#跳过点文件
		#print $name." ";
		next unless $name =~ /$pattern/; # 跳过非目标文件
		$name = $dir."/".$name."\n"; 		#加上目录名
		print SCP $name;		
	}
	close SCP;
	closedir DIR;	
}





sub create_fold {
	use File::Path 'mkpath';
	my ($fold,$style, $extra_str, $log) = @_;
	
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
	if ($log){
		open (LOG,$log)||die "unable to open file $log for writting\n";		
		print LOG "...has created fold: ".$fold."\n";
		close LOG;
	}else{
		print "...has created fold: ".$fold."\n";
	}
}

sub muti_mkdir {
	use File::Path;
	my ($style, $errinfo, @folds) = @_;
	
	#my $inhmm_fold = $HMM_ROOT."/hmm0024_".$wi_cro;
	#my $outhmm_fold = $HMM_ROOT."/hmm0100_".$wi_cro; 
	foreach my $fold(@folds){
		if ($style eq "tree"){
			unless(-e $fold) {
				mkpath($fold,{verbose=>1,mode=>0777,error=>\my $errlist })||die ($errinfo."\: muti_mkdir cannot mkpath ".$fold.": ".$!);
				if(scalar @errlist > 0){
					print "mkpath error $_\nadditional: $errinfo\n" for (@errlist);
				}
				
			}	 
		}else{
			unless(-e $fold) {
				mkdir($fold, 0777)||die ($errinfo."\: muti_mkdir cannot mkdir ".$fold.": ".$!);
				#print "problem may be $errinfo\n";
			}
		}		
		print "...has created fold: ".$fold."\n";
	}
}


sub movecopy_dir {
	use File::Copy;
	use File::Path;
	use File::Basename;
	my ($op, $org, $dst,$ifmkdir) = @_;

	if (-e $org){
		my $subfold = basename $org;
		if ($ifmkdir eq "mkdir"){		
			$dst = $dst."/".$subfold;
			mkdir($dst);# unless(-e $dst);
		}elsif($ifmkdir eq "tree"){
			$dst = $dst."/".$subfold;
			mkpath($dst, {mode => 0777});# unless(-e $dst);
			
		}else{		
			#print "succeed: move files in $org to $dst and do not make dir $subfold in the $dst\n";
		}
		opendir DIR, $org or die "Cannot open $org: $!";
			while (my $name = readdir DIR) {
			next if $name =~ /^\./; #跳过点文件
		
			$fullname 	 = $org."/".$name; #加上目录名
			$newfullname = $dst."/".$name;
	
			if (-f $fullname){
				print $fullname."\n";
				if ($op eq "move"){
					if(-e $newfullname){
						unlink($newfullname)||die "can not delete ".$newfullname.": ".$!;
					}
					
					move($fullname,$dst)||die("can not move $fullname to $dst: ".$!);
				}elsif ($op eq "copy"){
					if(-e $newfullname){
						unlink($newfullname)||die "can not delete ".$newfullname.": ".$!;
					}
					copy($fullname,$dst)||die("can not move $fullname to $dst: ".$!);
				}
			}elsif(-d $fullname){
				print "dir: ".$fullname." is not processed\n";
				next;
			}else{
				die "$fullname can not be recognize as dir or file.";
			}
		}
	}else{
		print $org." does not exist\n";
	}

}

sub movecopy_dir2 {
	use File::Find 'find';
	use File::Copy 'mv';
	use File::Copy 'cp';
	use File::Basename;
	use File::Spec;
	
	my($op, $oridir, $newdir) = @_;
	if (@_ != 3){
		print "movecopy_dir2: ".'$op, $oridir, $newdir'."\n";
		exit(0);
	}
	my @files; 
	$oridir =~ s/\\/\//gi;	
	

	find(\&wanted_movcopydir2, $oridir);	


	foreach (@files){			
	
			my $dstdir;
			my $dstname;
			my $oriname = $_;
			my $filename = basename $_;			
			(my $dir      = dirname $_) =~ s/\\/\//gi;
		
			if ($dir eq $oridir){
				$dstdir = $newdir;
				$dstname = $newdir."/".$filename;
				unless(-e $dstdir){
					mkpath($dstdir,{mode => 0777})||die "can not mkpath $dstdir:　$!";
				}
			}else{
				(my $subdir = $dir)=~s/$oridir\/(.+)/$1/;;			
				$dstdir  = $newdir."\/".$subdir;
		
				$dstname = $dstdir."\/".$filename;
								
				unless(-e $dstdir){
					mkpath($dstdir,{mode => 0777})||die "can not mkpath $dstdir:　$!";
				}
			}
			
			if (-e $dstname){
				unlink($dstname)||die "can not unlink $dstname: $!";
			}
		
			if ($op eq "move"){
				mv($oriname, $dstname)||die "can not ".$op." file ".$oriname." to ".$dstdir.": ".$!;
			}elsif($op eq "copy"){
				cp($oriname, $dstname)||die "can not ".$op." file ".$oriname." to ".$dstdir.": ".$!;
			}
				
							
	}
	
	sub wanted_movcopydir2 {
			my $file = $File::Find::name;
			
			#print $found_file."\n";
			unless(-d $file){				
				unless($file =~  /.*(\/|\\)\.{1,2}$/){				
					unless($file=~/^\s+$/){	
						
						push(@files, $file);
					}
				}
			}
	}
	return 1;

	
}



#require "common_config.pl";
sub find_files {
	use File::Find 'find';
	
	my ($findpath, $findpattern,$scp,$wstyle) = @_;
	my $write = ">";  
	$write = $wstyle if($wstyle);
	
	if (@_ < 3){
		print "find_files uaage: findpath, find pattern, $scp\n";
		exi(0);
	}
	
	open(SCP,$write.$scp)||die "unable to open file ".$scp." for reading: ".$!;	

	find(\&wanted_findfiles, $findpath);
	
	sub wanted_findfiles {			
		my $found_file = $File::Find::name;		
		if ($found_file =~ /$findpattern/gi){
			next if (index($found_file,"NIST-Speech-Disc-11-4.1-maybecopy")>=0);
			print SCP $found_file."\n";			
		}

	}
	close SCP;
}




sub name {
	use File::Spec;
	use File::Basename;
	
	if (@_!=3) {
		print "name usuage: path name, number of layer, if with postfix\n";
		exit(0);
	}
	my ($line, $num, $posf) = @_;
	my @outs;
	my $out;
	
	$line =~ s/[\/\\]/$SPLIT/gi;
	my $dir = dirname $line;
	
	my $name = basename($line);
	push @outs, $name;
	for(2..$num){
		$name =  basename $dir;
		$dir  =  dirname $dir;
		push @outs, $name;		
	}	

	# if the postfix is needed or the line has no postfix.
	if (scalar(@outs) >= 2){		
		$out = join "\\", reverse @outs; 		
	}else{		
		$out = $outs[0];
	}
	
	unless($posf){	
		my $pos = rindex ($out, "\.");
		$out = substr($out, 0, $pos);
	}
	
	# the first one is a path with certain mutiple layers. The second is a array containing these layers seperately.
	$out =~ s/\\/\//gi;
	return $out;
}

sub difftxt {
	my($txt1,$txt2,$log, $wtype) = @_;
	open(LOG,$wtype.$log)||die "can not open file ".$log." for writting: ".$!;
	open(IN1,"<".$txt1)||die "can not open file ".$txt1." for reading: ".$!;
	open(IN2,"<".$txt2)||die "can not open file ".$txt2." for reading: ".$!;	
	my (@arr1, @arr2);
	while(<IN1>){
		chomp;
		unless(/^\s$/){
			push(@arr1, $_);
		}
	}
	
	while(<IN2>){
		chomp;
		unless(/^\s$/){
			push(@arr2, $_);
		}
	}

	close IN1;
	close IN2;
	
	for(@arr1){
		my $arrwrd1 = $_;
		my $tab = 0; 
		for(@arr2){
			my $arrwrd2 = $_;
			if ($arrwrd1 eq $arrwrd2){
				$tab = 1;
			}
			
		}
		if ($tab == 0){
			print LOG "diff $arrwrd1 \t\t\:in txt1 not in txt2\n";			
		}		
	}
	
	for(@arr2){
		my $arrwrd2 = $_;
		my $tab = 0; 
		for(@arr1){
			my $arrwrd1 = $_;
			if ($arrwrd2 eq $arrwrd1){
				$tab = 1;
			}
			
		}
		if ($tab == 0){
			print LOG "diff $arrwrd2 \t\t\:in txt2 not in txt1\n";			
		}		
	}
	
	close LOG;
	
	
	
}

#提取最优的一个或者多个 ro tb 或者 penalty scal 
sub bestpara{
	my ($log, $num) = @_;
	my $fnum = 1;
	$fnum = $num if($num);
	
	
	my $count = 0;
	my %ab;
	open(IN, "<".$log)||die "can not open file ".$log."for reading".$!;
	while(<IN>){
		++$count;
		
		next if /^\s+$/;
		next if /^#/;
		chomp;
		
		my ($a,$b)=/\S*\s*([\.\-\d]+)\s+([\.\-\d]+)/;
		$ab{$a." ".$b} = 1;	
		
		unless ($fnum <= 0){
			if($count >= $fnum){
				#pause($count." ".$fnum);
				#pause($a." ".$b);
				last;
			}
		}
	}
	close IN;
	my @abs = keys %ab;
	if ($fnum == 1)	{
		my $str = $abs[0];		
		my ($rr,$tt) =($str =~ /([\-\.\d]+)\s+([[\-\.\d]+)/);		
		return($rr,$tt);
	}else{
		return(@abs);
	}
}

# set for the best ro tb extraction from the  log generated in tun_tied.pl   (ro tb)   or tune_muti.pl  (penalty scal)
sub bestlog {
	my ($file, $log, $num) = @_;
	my $fnum = 1;
	$fnum = $num if($num);

	open(OUT, ">".$log)||die "can not open file ".$log." for writting: ".$!;
	open(IN,"<".$file)||die "can not open file ".$file." for reading: ".$!;
	my $count = 0;
	while(<IN>){
		
		chomp;
		#pause($_);
		
		if (/\d+\:\s+[\.\d]+\s+[\.\d]+\s+.+:\s+(\([\-\.\d]+\s+[\-\.\d]+\).*)/){
			++$count;
			#pause($_);
			my $rotb = $1;
			#pause($rotb);
			my @rotbs= ($rotb =~ /\(([\-\.\d]+\s+[\.\-\d]+)\)/gi);
			#pause(scalar @rotbs);
			foreach my $rt(@rotbs){
				$rt=$count.": ".$rt."\n" 
			}
			my $rotbline = join '',@rotbs;
			print OUT $rotbline;
		}
		last if ($count >= $fnum);
	}
	close IN;
	close OUT;
	
}

sub stepadd {
	my ($beg, $step, $end) = @_;
	my $ind = $beg;
	my @res;
	my $count = 0;
	while(1) {
		last while($ind > $end);
		$ind = $ind."\.0" unless($ind =~ /[\d\-]+\.\d+/);
		#pause($ind);
		$res[$count] = $ind;
		++$count;		
		$ind = $ind + $step;
	}

	return @res;
}


sub lasthmm{
	my ($log) = @_;
	my $endhmm;
	open(IN,"<".$log)||die "can not open file $log for reading: ".$!;
	while(<IN>){
		chomp;
	    next if (/^\s$/);
		$endhmm = $_;
	}
	close IN;
	return $endhmm;
}


sub onevalfromfile {
	my ($log) = @_;
	my $one_val = lasthmm($log);
	return $one_val;
}

sub wtime {
	my $wtype = "\>\>";	
	my($str, $wtype) = @_;
	if ($str){
		$str = "\t".$str."\n";
	}else{
		$str = "\n";
	}
	my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = localtime;
	++$mon;
	
	open(OUT,$wtype.$TIMELOG)||die "can not open file ".$TIMELOG." for writting: ".$!;
	print OUT " m".$mon."-d".$day."  ".$hour.":".$min.":".$sec.$str;
	close OUT;
}


1;



