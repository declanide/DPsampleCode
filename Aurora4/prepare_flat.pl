require "common_config.pl";

if ((@ARGV != 3) || ! ($ARGV[-1] =~ /^clean|multi$/)) {
  print "prepare usage: training condition \[clean|multi\], testing set (1-14 sets), testing sent num \[166|330\]\n\n"; 
  exit (0);
}

my $sph2wav = $ARGV[0];   # whether the sph2wav will be runned or not
my $fea_yes = $ARGV[1];   #  whether the create_fea will be runed or not.
my $COND	= $ARGV[2];   # training condition


# prepare training waves list and testing waves list
if ($COND eq "clean"){
	$ORI_TRAINLIST_WAV = $ORI_CLEAN_TRAINING_WAV;
	$ORI_TRAINLIST	   = $ORI_CLEAN_TRAINING;
}
else{
	$ORI_TRAINLIST_WAV = $ORI_MULTI_TRAINING_WAV;
	$ORI_TRAINLIST	   = $ORI_MULTI_TRAINING;
}

if ($COND eq "clean"){
	$TRAINLIST_DUP_WAV = $CLEAN_TRAINING_DUP_WAV;
	$TRAINLIST_DUP	   = $CLEAN_TRAINING_DUP;
}
else{
	$TRAINLIST_DUP_WAV = $MULTI_TRAINING_DUP_WAV;
	$TRAINLIST_DUP	   = $MULTI_TRAINING_DUP;
}

if ($COND eq "clean"){
	$TRAINLIST_WAV = $CLEAN_TRAINING_WAV;
	$TRAINLIST	   = $CLEAN_TRAINING;
}
else{
	$TRAINLIST_WAV = $MULTI_TRAINING_WAV;
	$TRAINLIST	   = $MULTI_TRAINING;
}
unless(-e $LIB) {
	mkdir ($LIB, 0777) || die("unable to create dir $LIB: $!");
}
unless(-e $LOG) {
	mkdir ($LOG, 0777) || die("unable to create dir $LOG: $!");
}



mkconfig();
print "mkconfig finish\n";

#goto ENDLAB;

# the processing of dict and language model.
dict_lm_processing();
print("in dict and lm processing finish\n");

wav_ori_list2new_list();
print "wav_ori_list2new_list finish\n";

#这个程序需是要去除scp里面的重复行。待待待待待待待待待待
#将 DEVLIST_DUP_WAV  --> DEVLIST_WAV
#将 TRAINLIST_DUP_WAV ---> TRAINLIST_WAV
#将 TESTLIST_DUP_WAV ---> TESTLIST_WAV
#   ....  ---> TRAINLIST, TESTLIST, DEVLIST_FEA
##pause("delete duplicated lines:    $DEVLIST_DUP_WAV\t$DEVLIST_WAV\n");

del_dup($DEVLIST_DUP_WAV, $DEVLIST_WAV);
del_dup($TRAINLIST_DUP_WAV, $TRAINLIST_WAV);
del_dup($TESTLIST_DUP_WAV, $TESTLIST_WAV);
print "del_dup\(\) finished.. you can check if any line is deleted\n";

#my $devtemp_list = $DEVLIST_WAV;
if ($sph2wav == 1) {
	my $dev_oripath  = $WSJ0_DATA."/NIST-Speech-Disc-11-6.1/WSJ0/SI_DT_05";
	my $dev_tempath  = $LIB."/new_move_dev/si_dt_05";
	devsph2wav($DEVLIST_WAV,$dev_oripath, $DEVLIST_MOVE_WAV, $dev_tempath);
}

# wave lists are converted to feature lists.
wav_fea_list_folders();
print("wav_fea_list finish\n");

# merge several wave lists to a whole list(scp). The create_merged_files is used to create serveral scp.
my $traintest_wav_scp = $LIB."\/traintest_wav\.scp";
my $traintest_fea_scp = $LIB."\/traintest_fea\.scp";
my $coder		= $LIB."\/coder\.scp";
my $coder_dev	= $LIB."\/coder_dev\.scp";
files_merge($traintest_wav_scp, $traintest_fea_scp, $coder, $coder_dev);
print("files_merge finish \n");

# feature extraction
create_fea($coder,$coder_dev,0) if ($fea_yes == 1);
print("create_fea is enabled and finished\n");

#train:  
make_mlf("$DOC\\SI_TR_S",$TRAIN_DOT_FILES,"\.DOT",$TRAINLIST, $DICT,$WORDS,$LIB."/train_mlfmfc_check.scp",1,$TRAIN_MISSING, $LOG."/trainmlf.log");
#test:
make_mlf("$DOC\\SI_ET_05",$TEST_DOT_FILES,"\.DOT",$TESTLIST, $DICT,$TEST_WORDS,$LIB."/test_mlfmfc_check.scp",1,$TEST_MISSING, $LOG."/testmlf.log");
#dev:
make_mlf("$DOC\\SI_DT_05",$DEV_DOT_FILES,"\.DOT",$DEVLIST_FEA,$DICT, $DEV_WORDS,$LIB."/dev_mlfmfc_check.scp",1,$DEV_MISSING, $LOG."/devmlf.log");
#pause("mk_mlf is finished.\n");

#WAV_FEA:
# create phone mlf
train_phones_mlf();
#pause("make phone mlf\n");

#delete the duplicated lines.
# DEVLIST_DUP_WAV  --> DEVLIST_WAV
# TRAINLIST_DUP_WAV ---> TRAINLIST_WAV
# TESTLIST_DUP_WAV ---> TESTLIST_WAV
#   ....  ---> TRAINLIST, TESTLIST, DEVLIST_FEA

#ENDLAB:
#pause("in prepare");

sub devsph2wav {
	use File::Basename;
	use File::Path;
	use File::Copy;
	local ($orilist,$oripath, $newlist, $newpath) = @_;

	open(LI,"<$orilist") || die("unable to open file $orilist for reading: ".$!);
	#open(NF, ">$newfolder") || die("unable to open file $newfolder for writting: ".$!);
	open(NL,">$newlist") || die("unable to open file $newlist for writting ".$!);
	$oripath=~ s/\//\\/gi;
	$newpath=~ s/\//\\/gi;	
	#pause($oripath."\n".$newpath);
	while(<LI>){
		s/[\n\r]//gi;
		s/\//\\/gi;	
		my $name = basename $_;
		my $dir  = dirname $_;
		my $dirname  = basename $dir;				
		my $newdir  = $newpath."\\".$dirname;	
		#print $newdir."\n";
		unless (-e $newdir) {
			mkpath($newdir);
		}
		unless (-e $newdir) {
			die("unable to mkpath $newdir: $!");
		}
		$name =~ s/\.WV(\d)/\.wa$1/gi;				
		my $newname = $newdir."\\".$name;		
		my $cmd = join (
			" ",
			$AUEXE."/sph_convert\.exe",
			$_						
		);
		system($cmd);
		move ($name, $newname) || die("unable to move file $genname to file $newname: ".$!);
		$newname =~ s/\\/\//gi;
		print NL $newname."\n";		
	}	
	close(LI);
	close(NL);
	
}


sub del_dup {
	if (@_ != 2)  {
		  print "del_up usage: input file name, output file name";
		  exit (0);
	}
	local ($inf, $outf) = @_;
	open (IN,"<$inf") || die ("unable to open file $inf for reading\n");
	open (OUT,">$outf") || die("unable to open file $outf for writting\n");
	
	local (%infs, $count);
	$count = 0;
	while(<IN>) {
		$count++;
		s/[\n\r]//gi;
		$infs{$_}=1;		
	}
	local @infs = keys %infs;
	foreach(@infs) {
		print OUT "$_\n";
	}
	
	local $dup_num = $count - scalar @infs;
	print "The num of duplicated files \($inf\) is $dup_num.\n" ;	
	
	close(IN);
	close(OUT);

}


sub add_path {
	if (@_ != 3) {
		print ("add_path\(\) usage: headpath, ORI_TESTLIST_WAV, TESTLIST_DUP_WAV\n");
		exit(0);
	}
	
	my ($path, $in_file, $out_file) = @_;
	open (IN, "<$in_file") || die ("can not open input file $in_file for reading: ".$!);
	open (OUT, ">$out_file") || die ("can not open output file $out_file for writting: ".$!);	
	local @in_arr = <IN>;
	foreach (@in_arr){
		s/(.+)/$path\/$1/gi;
		print OUT;		
	}
	close IN;
    close OUT;
	return scalar @in_arr;
}


sub radom_select {
	my ($num_per, @in_arr) = @_;

	local @out_arr;
	local $run_count = 1;
	while (1) {	
		local $line_ind = int(rand scalar @in_arr);
		local $line = $in_arr[$line_ind];
		push (@out_arr, $line);
       	splice (@in_arr, $line_ind, 1);
		last if ($run_count == $num_per);

		++$run_count;
	}
	return @out_arr;
}

# sub devlist_wav {
		# if (@_ != 2)  {
		  # print "usage: head dev path, selecting num";		  
		  # exit (0);
		# }
		# my ($extra_path, $num_per)	= @_;
		
		# open (ALL, "<$ALL_DEVLIST_WAV")|| die("unable to open file $ALL_DEVLIST_WAV for reading");
		# open (DEV, ">$DEVLIST_DUP_WAV") || die ("unable to open file $DEVLIST_DUP_WAV for writting");
		# $extra_path =~ s/\\/\//gi;		
		# my (%persons, %per_lines);
		# while(<ALL>){
			# s/[\n\r]//gi;			
			# if (/.*si_dt_05\/.+\/.*\.wv.*/gi){
				# my $line = $_;
				# $line =~ s/\.\/(.*)/$extra_path\/$1/gi;				
				# s/.*si_dt_05\/(.+)\/.*\.wv.*/$1/gi;							
				# $persons{$1}=1;			
				# $per_lines{$line}=$1;
			# }	
		# }		
		# my @person_keys	= keys %persons;		
		# foreach (@person_keys) {			
				# my (@temp1, @temp2);
				# while (($sent_key, $id_value) = each %per_lines){			
					# push (@temp1, $sent_key) if ($_ eq $id_value);
				# }				
				# @temp2 = radom_select($num_per,@temp1);
				
				# foreach (@temp2){
					# print DEV "$_\n";
				# }	
			
		# }
		# close (ALL);
		# close (DEV);
# }

sub devlist_wav2 {
	use File::Basename;
	use File::Spec;
	if (@_ != 3)  {
		print "usage: head dev path, selecting num";		  
			exit (0);
		}
	my ($extra_path, $ref_list, $out_list)	= @_;
	open (ALL, "<$ALL_DEVLIST_WAV")|| die("unable to open file $ALL_DEVLIST_WAV for reading: ".$!);
	open (REF, "<$ref_list") || due ("unable to open fiel $ref_list for reading: ".$!);
	open (OUT, ">$out_list") || die ("unable to open file $out_list for writting: ".$! );
	$extra_path =~ s/\\/\//gi;				
	my %ref;
	while(<ALL>) {
		s/^\./$1/gi;
		s/\//\\/gi;
		s/[\n\r]//gi;		
		if (/.*si_dt_05.*\.wv\d+/gi){ 
			$name	   = basename $_;
			$name 	   =~ s/\..*//gi;
			$perdir	   = dirname $_;
			$per 	   = basename $perdir;			
			my $key    = $per."\/".$name;
			my $line   = $extra_path.$_;
			$line      =~ s/\\/\//gi;
			#pause($line);
			$ref{$key} = $line;
		}	
	}
	while(<REF>){
		my @arr = split /\s+/;
		my $key = $arr[0];		
		my $line = $ref{$key};
		print OUT "$line\n";
	}
	close REF;
	close OUT;
	close ALL;
}
	
	


sub testlist_wav {
	if (@_ != 2)  {
		print "testlist_wav usage: added extral head path for the training wav files, out list file\n\n"; 
		exit (0);
	}
	local ($head_path, $out_list) = @_;

	add_path($head_path, $ORI_TESTLIST_WAV, $out_list);	
	
}


sub trainlist_wav {
	if (@_ != 2)  {
		print "trainlist_wav usage: added extral head path for the training wav files, out list file\n\n"; 
		exit (0);
	}
	local ($head_path, $out_list) = @_;

	add_path($head_path, $ORI_TRAINLIST_WAV, $out_list);	

	
}

# sub trainlist_wav2 {
	# use File::Find;
	# if (@_ != 3)  {
		# print "trainlist_wav usage: input path, pattern str, out list file\n\n"; 
		# exit (0);
	# }
	# local ($head_path, $str, $out_list)	= @_;	
	# open (OUT, ">$out_list") || die("unable to open file $out_list for writting: ".$!);
	
	# sub wanted {
		# $found = $File::Find::name;
		# if ($found =~ /$str/gi) {
			# $found =~ s/\\/\//gi;
			# print OUT "$found\n";
		# }
		
	# }
	# find(\&wanted, $head_path);
	# pause("stop in trainlist_wav");
# }


sub files2one {
	unless (@_ > 1)  {
		print "files2one() usage: first para is the final one and the others are the serveral input files\n\n"; 
		exit (0);
	}
	local (@files, $whole_file);
	foreach (@_){
		push (@files, $_);
	}
	$whole_file = shift @files;
	
	open (WH,">$whole_file") || die("unable to open file $whole_file for writting in files2one(): $!");
	
	foreach $file(@files) {
		open (FI, "<$file") || die ("unable to open file $file for reading in files2one() $!");
		while(<FI>){
			print WH; 
		}
		close(FI);
	}
	close (WH);
}

sub wav_ori_list2new_list{
	#prepare all wave list files
	$head_devwav_path = $WSJ0_DATA."/NIST-Speech-Disc-11-6.1";	
#	devlist_wav($head_devwav_path, $DEV_NUMPER);	
	devlist_wav2($head_devwav_path, $DEV_FILES,$DEVLIST_DUP_WAV);	

	$head_testwav_path	= $SPEECH_DATA."/disk11\/CLE_WV1";
	testlist_wav($head_testwav_path, $TESTLIST_DUP_WAV);
	
	$head_trainwav_path	= $SPEECH_DATA."/train_clean_${FREQ}k_all";	
	trainlist_wav($head_trainwav_path, $TRAINLIST_DUP_WAV);	
}

sub devwav_list2fea_list {   
	use File::Basename;
	use File::Spec;
	if (@_ != 3){
		print "usage: devwav_list2fea_list, input wav list, output feature list, output dir.\n";
	}
	local ($wav_list, $fea_list, $head_fea_path) = @_;
	open (WAV, "<$wav_list") || die ("unable to open file $wav_list for reading.\n");
	open (FEA, ">$fea_list") || die ("unable to open fiel $fea_list for writting.\n");
	$head_fea_path =~ s/\//\\/gi;	
	
	while (<WAV>){
		s/[\n\r]//gi;		
		s/\//\\/gi;	# converted to windows style 		
		s/^[\.\s]+//gi;	
		
		local ($name, $tmp1, $tmp2) = fileparse($_, qr{\.[^.]+});			
		$name 					= $name."\.fe";			
		local $fulldir			= dirname($_);
		local $person			= basename($fulldir);
		local $head_wav_path	= dirname($fulldir);		
		local $new_fullname		= File::Spec->catfile($head_fea_path, $person, $name);	
		$new_fullname 			=~ s/\\/\//gi;		
		print FEA "$new_fullname\n";				
	}	
	close(WAV);
	close(FEA);	
}
	

sub wav_list2fea_list {
	use File::Basename;
	use File::Spec;
	if (@_ != 3){
		print "usage: wav_list2fea_list, input wav list, output feature list, out dir.\n";
	}
	local ($wav_list, $fea_list, $head_fea_path) = @_;
	open (WAV, "<$wav_list") || die ("unable to open input file $wav_list for reading in wav_list2fealist\n");
	open (FEA, ">$fea_list") || die ("unable to open output file $fea_list for writting in wav_list2fealist\n");
	$head_fea_path =~ s/\\/\//gi;	
	while (<WAV>){
		s/[\n\r]//gi;		
		s/\//\\/gi;	# converted to windows style 		
		s/^[\.\s]+//gi;	
		local ($name, $tmp1, $tmp2) = fileparse($_, qr{\.[^.]+});
		# temp1 and tmp2 are just used as temp variable;
		$name 					= $name."\.fe";		
		local $fulldir			= dirname($_);
		local $person			= basename($fulldir);
		local $head_wav_path	= dirname($fulldir);		
		local $new_fullname		= File::Spec->catfile($head_fea_path, $person, $name);	
		$new_fullname 			=~ s/\\/\//gi;	
		print FEA "$new_fullname\n";		
	}	
	close(WAV);
	close(FEA);	
}	


sub wav_fea_list_folders {
	
	#transform wav list to fea list.
	unless (-e $FEA_ROOT){
		mkdir ($FEA_ROOT, 0777) || die("can not mkdir $FEA_ROOT: ".$!);
	}
	unless (-e $FEA_PAR_DIR){
		mkdir ($FEA_PAR_DIR, 0777) || dier("can not mkdir $FEA_PAR_DIR: ".$!);
	}	
	
	unless (-e $DEV_FEA_DIR) {
		mkdir ($DEV_FEA_DIR, 0777) || die ("can not mkdir $DEV_FEA_DIR: ".$!);
	}
	wav_list2fea_list($DEVLIST_MOVE_WAV, $DEVLIST_FEA, $DEV_FEA_DIR);
	
	unless (-e $TEST_FEA_DIR) {
		mkdir ($TEST_FEA_DIR, 0777) || die ("can not mkdir $TEST_FEA_DIR: ".$!); 
	}
	wav_list2fea_list($TESTLIST_WAV, $TESTLIST, $TEST_FEA_DIR);

	unless (-e $TRAIN_FEA_DIR) {
		mkdir ($TRAIN_FEA_DIR, 0777) || die ("can not mkdir $TRAIN_FEA_DIR: ".$!);
	}
	wav_list2fea_list($TRAINLIST_WAV, $TRAINLIST, $TRAIN_FEA_DIR);

	list2folders($DEVLIST_FEA, $TESTLIST, $TRAINLIST);	

}

sub list2folders{	
	use File::Basename;
	use File::Path;
	my @lists	= @_;
	foreach(@lists) {
		open (LI,"<$_") || die("unable to open fiel $_ for reading in list2folders func\n");
		while(<LI>){
			s/^[\.\s]+//gi;
			s/[\n\r]//gi;
			s/\//\\/gi; # convered to linux style;
			my $basename    = basename $_;
			my $dirname		= dirname $_;
			#$dirname    	=~ s/\\/\//gi;  #converted to unix style
			mkpath($dirname, {verbose => 0, mode => 0777, error => \my $err});			
			pause("mkpath may have problems") unless (scalar @$err == 0);
		}
		close LI;
	}
}

sub files_merge{
	use File::Basename;
	if (@_ != 4){
		print "files_merge usage: traintest_wav_list, traintest_fea_list, coder, coder_dev\n";
		exit(0);
	}
	my ($wav_scp, $fea_scp, $coder, $coder_dev) = @_;
	files2one($wav_scp, $TRAINLIST_WAV, $TESTLIST_WAV);
	files2one($fea_scp, $TRAINLIST, $TESTLIST);	

	open (COD, ">$coder") || die ("unable to open file $coder for writting in files_merge(): $!.");
	open (DEVCOD, ">$coder_dev") || die ("unable to open file $coder_dev for writting in files_merge(): $!.");
	open (WAV, "<$wav_scp") || die ("unable to open file $wav_scp for reading in files_merge(): $!.");
	open (FEA, "<$fea_scp") || die ("unable to open file $fea_scp for reading in files_merge(): $!.");
	open (DEVW, "<$DEVLIST_MOVE_WAV") || die ("unable to open file $DEVLIST_MOVE_WAV for reading in files_merge(): $!.");
	open (DEVF, "<$DEVLIST_FEA") || die ("unable to open file $DEVLIST_FEA for reading in files_merge(): $!.");
	@wav_arr = <WAV>; #@wav_arr2 = sort(@wav_arr);
	@fea_arr = <FEA>; #@fea_arr2 = sort(@fea_arr);	
	
	foreach $pre_lin(@wav_arr) {		
		$pre_lin		=~ s/[\n\r]//gi;
		$pre_lin 		=~ s/\\/\//gi;
		local $bac_lin	= shift @fea_arr;
		$bac_lin        =~ s/[\n\r]//gi;
		$bac_line		=~ s/\\/\//gi;
		local $line 	= "$pre_lin\t$bac_lin" ;
		print COD "$line\n";
		my @prews = split /[\/\.]/, $pre_lin;
		my @bacws = split /[\/\.]/, $bac_lin;
		unless (($prews[-2] eq $bacws[-2]) && ($prews[-3] eq $bacws[-3])) {
			print "there error when produce coder.scp in files_merge\n";
			exit(0);
		}		
	}	
	close(COD);
	close(WAV);
	close(FEA);
	
	@wav_arr = <DEVW>; #@wav_arr2 = sort(@wav_arr);
	@fea_arr = <DEVF>; #@fea_arr2 = sort(@fea_arr);	
	
	foreach $pre_lin(@wav_arr) {		
		$pre_lin		=~ s/[\n\r]//gi;
		$pre_lin 		=~ s/\\/\//gi;
		local $bac_lin	= shift @fea_arr;
		$bac_lin        =~ s/[\n\r]//gi;
		$bac_line		=~ s/\\/\//gi;
		local $line 	= "$pre_lin\t$bac_lin" ;
		print DEVCOD "$line\n";
		my @prews = split /[\/\.]/, $pre_lin;
		my @bacws = split /[\/\.]/, $bac_lin;
		unless (($prews[-2] eq $bacws[-2]) && ($prews[-3] eq $bacws[-3])) {
			print "there error when produce coder.scp in files_merge\n";
			exit(0);
		}		
	}
	close(DEVW);
	close(DEVF);
}

# sub codtime {	
	# if (@_ != 3) {
		# print("codtime usage: coder config log \%all");
	# }
	# my ($coder, $config, $hlog) = @_;
	
	# open(COD,"<$coder") || ("unable to open file $coder for reading: ".$!);	
	# while(<COD>){
		# s/[\r\n]//gi;
		# s/\//\\/gi;
		# my @files = split /\s+/;
		# my $in    = $files[0];
		# my $id    = basename $in;
		# my $dir   = dirname $in;
		# my $per   = basename $dir;
		# $id       = $per."/".$id;
	
		# my $cmd = join (
			# " ",
			# "HCOPY",
			# "-T 2 -C $config",
			# $all{$id},
			# $_,
			# ">>".$hlog);
		# print $cmd."\n";

		# system ($cmd);
	# }
	# close COD;
# }
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
	
	if ($posf == 1){
		# if the postfix is needed or the line has no postfix.
		$out = join ($SPLIT, reverse @outs); 	

	}else{
		# if the postfix is not needed when the line has postfix
		$out = join ($SPLIT, reverse @outs);		
		my $pos = rindex ($out, "\.");
		$out = substr($out, 0, $pos);
	}
	
	# the first one is a path with certain mutiple layers. The second is a array containing these layers seperately.
	return $out;

}

sub create_fea {
	use File::Basename;
	if( scalar @_ != 3) {
		print ("create_fea usage: coder of train and eval test, coder of dev, [1|0]for cut\n");
		exit(0);
	}
	my ($coder, $coder_dev,$cut) = @_;
	my $cmd, %all;
	open (LOG, ">".$LOG."\/HCopy.log") || ("unable to open file $LOG/HCopy.log for writting: ".$!);
	close(LOG);
	if ($cut) {
		my $all_files = $LIB."\\AllTrainDevEval.txt";
		open (ALL,">".$all_files) || die("unable to open file $all_files for writting: ".$!);
		open (TRF,"<$TRAIN_FILES") || ("unable to open file $TRAIN_FILES for reading: ".$!);
		open (TEF,"<$TEST_FILES") || ("unable to open file $TEST_FILES for reading: ".$!);
		open (DEF,"<$DEV_FILES") || ("unable to open file $DEV_FILES for reading: ".$!);	
		print ALL while(<TRF>);	
		print ALL while(<TEF>);
		print ALL while(<DEF>);	
		close TRF;
		close TEF;
		close DEF;
		close ALL;
		#my %all;
		open(ALL, "<$all_files") || ("unable to open file $all_files for reading: ".$!);
		while(<ALL>){
			s/[\r\n]//gi;
			s/[\\\/]/$SPLIT/gi;
			my @filetimes = split /\s+/;
			my $id = lc($filetimes[0]);				
			my $start = $filetimes[1];
			$start    = $start*10000000;
			$start    =~ s/$/$1\.0/gi  unless($start =~ /\.\d+$/);		
			my $end   = $filetimes[2];
			$end      = $end*10000000;
			$end      =~ s/$/$1\.0/gi  unless($end =~ /\.\d+$/);
		
			$all{$id} = "-s ".$start." -e ".$end;
		}
		close(ALL);
	}
	
	my $len_all = scalar (keys %all);	
	
	if ($len_all) {
		$cmd = join (
			" ",
			"HCopy",
			"-T 2 -C $CONFIG_PAR_DEV",
			"-S ".$coder_dev,
			">".$LOG."\/HCopy.log");
		system $cmd;
	}else{
		open(COD,"<$coder_dev") || ("unable to open file $coder_dev for reading: ".$!);	
		while(<COD>){
			s/[\r\n]//gi;
			s/\//\\/gi;
			my @files = split /\s+/;
			my $in    = $files[0];
			my $id 	  = name($in, 2, 0);	
			#print($id." ");
			my $cmd;
			my $times = "";
			$times = $all{lc($id)};					
			$cmd = join (
				" ",
				"HCopy -T 2 -C $CONFIG_PAR_DEV",
				$times,
				$_,
				">>".$LOG."\/HCopy.log");
			system ($cmd);
		}				
		close COD;		
	}
	
	if ($len_all) {
		$cmd = join (
			" ",
			"HCopy",
			"-T 2 -C $CONFIG_PAR",
			"-S ".$coder,
			">".$LOG."\/HCopy.log");
		system $cmd;
	}else {
		open(CO,"<$coder") || ("unable to open file $coder for reading: ".$!);
		while (<CO>) {
			s/[\r\n]//gi;
			s/\\/\//gi;
			my @files = split /\s+/;
			my $in    = $files[0];
			my $id    = name($in, 2, 0);
		
			$id       =~ s/(.*)_\d+k/$1/gi;
			#print($id."\t");	
		
			my $times = $all{lc($id)};				
			my $cmd = join (
				" ",
				"HCOPY -T 2 -C $CONFIG_PAR",
				$times,
				$_,
				">>".$LOG."\/HCopy.log");
			system ($cmd);		
		}
		close CO;
	}
	
}

sub mkconfig{
	open (CPDEV,">".$CONFIG_PAR_DEV) || die ("unable to open file $CONFIG_PAR_DEV for writting.");
	open (CP,">".$CONFIG_PAR) || die ("unable to open file $CONFIG_PAR for writting.");
	open (CO, ">".$CONFIG) || die ("unable to open file $CONFIG for writting.");
	open (CRC,">".$CONFIG_REC_C) || die ("unable to open file $CONFIG_REC_C for writting.");
	open (CRW,">".$CONFIG_REC_W)|| die("unable to open file $CONFIG_REC_W for writting.");
	open (CLM,">".$CONFIGRAWMIT) || die("unable to open file $CONFIGRAWMIT for writting.");
	open (CRESC,">".$CONFIG_RESC)|| die("unable to open file $CONFIG_RESC for writting.");
		
	# 待，参考 htk reciept 里面的一些设置！
	local $config_str = join (
		"\n",
		"USEPOWER=T",	
		"SOURCEFORMAT=WAV",
		"SOURCEKIND=WAVEFORM",
		"TARGETKIND=PLP_D_A_Z_0",
		"TARGETRATE=100000.0",
	#	"HWAVEFILTER = \'sph2pipe -f sph \$\'",
		"ZMEANSOURCE = T",		
		"SAVECOMPRESSED=T",
		"SAVEWITHCRC=T",
		"WINDOWSIZE=250000.0",
		"USEHAMMING=T",
		"PREEMCOEF=0.97",
		"NUMCHANS=26",
		"CEPLIFTER=22",
		"NUMCEPS=12",
		"ENORMALISE=T",
		"DELTAWINDOW=2",
		"ACCWINDOW=2",
		#"BYTEORDER=VAX",
		""
	);	
	print CPDEV $config_str;
	$config_str =~ s/HWAVEFILTER.*\n//gi;
	$config_str =~ s/BYTEORDER.*\n//gi;
		
	$config_str2 =$config_str;
	$config_str2 =~ s/SOURCEFORMAT.*\n/SOURCEFORMAT=NOHEAD\n/gi;#\nTARGETFORMAT=HTK/gi;
	if ($FREQ =~ /08/) {
		$config_str2 = $config_str2."SOURCERATE=1250.0\n";	
	}elsif($FREQ =~ /16/) {
		$config_str2 = $config_str2."SOURCERATE=625.0\n";	
	}
	print CP $config_str2;
	
	$config_str3 = $config_str; 
	$config_str3 =~ s/SOURCEFORMAT.*\n//gi;
	$config_str3 =~ s/SOURCEKIND.*\n//gi;	
	print CO $config_str3;
	
	my $config_str4 = $config_str3;		
	$config_str4 = $config_str4."FORCECXTEXP=T\nALLOWXWRDEXP=T\n";
	print CRC $config_str4;
	$config_str4 =~ s/FORCECXTEXP=T\nALLOWXWRDEXP=T\n/FORCECXTEXP=T\nALLOWXWRDEXP=F\n/gi;
	print CRW $config_str4;
	
	print CLM "RAWMITFORMAT = T\n";	
	
	print CRESC "STARTWORD=".$START."\n"."ENDWORD=".$END;
		
	close(CP);
	close(CO);
	close(CR);
	close(CLM);
	close(CRESC);
}


sub dict_lm_processing {	
	use File::Copy;
	#fix the original cmu dict to htk style	
	my $fix_cmd = join (
			" ",
			"perl",
			$PERL_EXE."/FixCMUDict07.pl",
			$CMUDICT.">".$LIB."/cmudict_temp"
	);
	system ($fix_cmd);
	
	#merge cmudict.0.7a and local additions to form a new dic $DICT. $DICT is corresponding to the dict "cmu6" in file  prep_cmu_dict.sh of htk_recipe.
	my $merge_cmd = join (
				" ",
				$PERL_EXE."/MergeDict.pl",
				$LIB."/cmudict_temp",
				$CMUDICT_ADD.">$DICT"
			);	
	system("$merge_cmd");
	
	# split the origianal one line to sp line and sil line. $DICTSP is corresponding to the file cmu6sp in the folder htk_recipe.
	my $ad_spsil_cmd = join (
		" ",
		$PERL_EXE."\/AddSp.pl",
		$DICT,
		"1>".$DICTSP);
	system($ad_spsil_cmd);	
	
	my $dict_tmp = $DICT."_temp";	
	copy($DICTSP,$dict_tmp) or die ("Copy $DICTSP to $dict_tmp failed $!\n");	
	system("echo silence sil>>$dict_tmp");
	
	open (DIT,"<$dict_tmp") || die("unable to open file $dict_tmp for reading: ".$!);
	open (DISPSI, ">$DICTSPSIL") || die ("unable to open file $DICTSPSIL for reading ".$!);	
	# add "silence sil" to  cmu6sp to from cmu6spsil. The file $DICTSPSIL is corresponding to the file cmu6spsil in the folder htk_recipe.
	my @dit = <DIT>;	
	print DISPSI for (sort @dit);		
	close(DIT);	
	close(DISPSI);
	unlink($dict_tmp);	
	
	# create 5k dic
	my @sent_arr = ($START."\n", $END."\n");
	open (D5,">$DICT5K") || die ("unable to open file $DICT5K for writting");	
	print D5 for sort @sent_arr;
	close(D5);	
	
	#use  5k words list to generate corresponding dict without words that is not in the 5k list.
	my $wd_lt = $LIB."\/word_list";
	#copy($WLIST,$ltemp) or die "copy $WLIST to $ltemp failed $!\n";	
	open (WI, "<$WLIST") || die ("unable to open file $WLIST for reading: ".$!);
	open (LO, ">$wd_lt") || die("unable to open file $wd_lt for writting: ".$!);
	print LO for (grep !/^#/, <WI>);
	close(WI);
	close(LO);

	my $dict_tmp2	= $LIB."\/dict_temp2";	
	my $lis_dict_cmd	= join (
		" ",		
		$PERL_EXE."\/WordsToDictionary.pl",
		$wd_lt,
		$DICTSP,
		$dict_tmp2		
	);
	system($lis_dict_cmd);
	
	# my $ltmp2 = $wd_lt."2";
	# open (LO,">".$ltmp2) || die("unable to open file $ltmp2 for writting: ".$!);
	# open (LI,"<".$wd_lt) || die("unable to open file $wd_lt for reading: ".$!);

	# print LO for sort @sent_arr;	
	# print LO while <LI>;	
	# close LO;
	# close LI;
	# the 5k dict is finished. 
	open(DITMP,"<$dict_tmp2") || die("unable to open file $dict_temp2 for reading: ".$!);
	open (D5,">>$DICT5K") || die ("unable to open file $DICT5K for writting: ".$!);
	print D5 while <DITMP>;
	close(D5);
	close(DITMP);
	
	# copy language model. This model is produced before with UNIX style (windows) style will let the HBuild fail.
	copy ($ORI_LM_WSJ,$LM_WSJ) || die("unable to open file $ORI_LM_WSJ to file $LM_WSJ: $!");
	
	# use the 5k list and the original bigram to build word network.	
	#my $templog = $LOG;
	#$templog =~ s/\//\\/gi;k
	my $lmb_cmd = "HBuild -A -T 1 -C ".$CONFIGRAWMIT." -z -n ".$LM_WSJ." -u ".$UNK." -s ".$START." ".$END." ".$DICT5K." ".$WDNET."\>".$LOG."/hbuild_bi.log";
	system $lmb_cmd;
	
	$lmb_cmd  = "HBuild -A -T 1 -C ".$CONFIGRAWMIT." -t ".$START." ".$END." ".$wd_lt." ".$WDLOOP."\>".$LOG."/hbuild_wdloop.log";
	system $lmb_cmd;

	#unlink($LIB."\/lm_temp");
}



sub prep_dot_file { 
	use File::Find;
	if ((@_ < 2) || (@_ > 3)){
		print "perp_dot_file usage: the partical string that filename should contain, input path of dot files, output file (optional)\n";
		exit(0);
	}	
	my($pth, $out,$str)=@_;
	open(OUT,">$out") || die("unable to open file $out for writting: $!");
	sub wanted {			
		my $found_file = $File::Find::name;
		if ($str) {
			if ($found_file =~ /$str/gi){
				$found_file =~ s/\\/\//gi;
				print OUT $found_file."\n";			
			}
		}else {
			$found_file =~ s/\\/\//gi;
			print OUT $found_file."\n";	
		}
	}
	
	my @pth = ($pth);
	find(\&wanted, @pth);
	close OUT;
}

# sub train_mlf {
	# local $dot_path = "$DOC\\SI_TR_S";
	# prep_dot_file($dot_path, $TRAIN_DOT_FILES,"\.DOT");
	# my $mlf_cmd = join (
			# " ",
			# "perl",
			# $PERL_EXE."/CreateWSJMLF.pl",
			# $TRAINLIST,
			# $TRAIN_DOT_FILES,
			# $DICT,
			# $WORDS,
			# $LIB."/train_mlfmfc_check.scp",
			# 1,
			# $TRAIN_MISSING,
			# ">".$LIB."\/train_missing.log"
	# );
	# system($mlf_cmd);	
# }


sub make_mlf {
	my ($path, $dot_list, $str, $mfc_list, $dictFile, $outputMLF, $outputScript, $ignoreNoises, $includeOOVs, $makelog) = @_;
	if (@_ < 9){
		print "make_mlf usage: ....\n";
		exit(0);
	}
#	local $dot_path = "$DOC\\SI_ET_05";
	prep_dot_file($path, $dot_list,$str);
	# create mlf file
	my $mlf_cmd;
	if ($makelog) {
			$mlf_cmd = join (
			" ",			
			$PERL_EXE."/CreateWSJMLF.pl",
			$mfc_list,
			$dot_list,
			$dictFile,
			$outputMLF,
			$outputScript,
			$ignoreNoises,
			$includeOOVs,
			">".$makelog
			);
	}else{
			$mlf_cmd = join (
			" ",			
			$PERL_EXE."/CreateWSJMLF.pl",
			$mfc_list,
			$dot_list,
			$DICT,
			$outputMLF,
			$outputScript,
			$ignoreNoises,
			$includeOOVs
			);
		
	}
	
	print $mlf_cmd."\n";
	system($mlf_cmd);
}

#the func below was moved into the func forced_alignment in train.pl for convenience of debug.
sub train_phones_mlf {
	use File::Copy;
	copy ($DOC."/mkphones0.led", $LIB."/mkphones0.led") || die("unable to open file mkphones0.led from $DOC to $LIB: $!");
	copy ($DOC."/mkphones1.led", $LIB."/mkphones1.led") || die("unable to open file mkphones1.led from $DOC to $LIB: $!");
	my $cmd = join (
		" ",
		"HLEd",
		"-l \* -d ".$DICTSPSIL,
		"-i $MONOPHONE_LAB",
		$LIB."\/mkphones0.led",
		$WORDS		
	);
	system ($cmd);
	$cmd =~ s/$MONOPHONE_LAB/$MONOPHONE_LAB_SP/gi;
	$cmd =~ s/mkphones0\.led/mkphones1\.led/gi;
	system($cmd);
	print "....train_phones_mlf\n";
}


