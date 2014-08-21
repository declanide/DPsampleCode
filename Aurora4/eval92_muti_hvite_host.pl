# Evaluate on the November 92 ARPA test set.
#
# During the recognition, we'll output lattices
# for each of the test utterances, this will alow
# us to tune the LM scale factor and insertion 
# penalty much quicker than recognizing.
#
# The recognition is set with mutilple processes based
# on the number of cpus and size of memory in computer.
#
# Parameters:
#  1 - Directory name of model to test
#  2 - Distinguishing name for this test run.
#  3 - HVite pruning value
#  4 - Insertion penalty
#  5 - Language model scale factor
#  6 - "cross" if we are doing cross word triphones

require ("common_config.pl");

use File::Copy 'cp';
use File::Copy 'mv';
use File::Path 'rmtree';
use File::Basename;
use POSIX qw(:sys_wait_h);

if (@ARGV < 7){
	print $0.' usage: $inhmm,$addstr,$prune,$p,$s,$wi_cro,$scp, $outlat, $latout_fortune,$inmlf,$del_previous_lat'."\n";
	exit(0);
}

my ($inhmm,$addstr,$prune, $p, $s, $wi_cro,$scp,$wordlist_type, $outlat, $latout_fortune,$inmlf,$del_previous_lat,$iflocal)=@ARGV; 



#pause(" usage: $inhmm,$addstr,$prune,$p,$s,$wi_cro,$scp, $outlat, $inmlf");
#pause($outlat);
#hmm42 _ro200_tb750_prune250_flat_cross 250.0 -4.0 15.0 cross
#cd $WSJ0_DIR
my $inwdnet;
my $recdict;
if ($wordlist_type eq "cvp"){
	$inwdnet = $WDNETCVP; 
	$recdict = $DICTCVP;
}elsif($wordlist_type eq "cnvp"){
	$inwdnet = $WDNET;
	$recdict = $DICT;
}

my $p_s     = "p".$p."s".$s;
my $outfold = $RECOUT_FOLD."/".$addstr."_muti";
my $bak 	= $RUNBAK."/".$addstr."_muti";

if ($outlat eq "lat"){	
	$outfold = $outfold."/withlat";
	$bak     = $bak."/withlat";
}elsif(($outlat eq "nolat")||($outlat eq '')){
	if($latout_fortune){
		$outfold = $outfold."/nolat";
		$bak     = $bak."/nolat";
	}else{
		$outfold = $outfold."/nolatres";
		$bak     = $bak."/nolatres";
		
	}
}else{
	die "the eval_nov92_muti should have the input parameter \$outlat be selected in [lat|nolat|]";
}
$outfold    = $outfold."/".$p_s;
$bak        = $bak."/".$p_s;

# my $latout  = $LATFOLD."/".$addstr."_muti";
# my $latout  = $latout."/".$p_s;
# if($latout_fortune){
	# $latout = $latout_fortune;
# }
my $latout = $latout_fortune;

my $mlf = $TESTWORDS3;
if ($inmlf){
	$mlf = $inmlf;
}

#goto DEBUG;


if($del_previous_lat eq "dellat"){
	if(-e $latout){
		rmtree($latout)||die "can not rmtree ".$latout.": ".$!;
	}
}

# begin delet and mkdir;
if(-e $outfold){
	movecopy_dir2("move",$outfold,$bak."/eval_nov92");	
}
if (-e $outfold){
	(my $fold = $outfold) =~ s/\//\\/gi;	
	system ("RMDIR /Q /S ".$fold);

	#pause("RMDIR /Q /S ".$fold);
	#rmdir($outfold)||die "can not rmdir $outfold: ".$!;		
}

#pause("rm");
#pause($latout);

unless(-e $outfold){
	mkpath($outfold,{mode => 0777})||die "can not mkpath $outfold: ".$!;
}

if ($outlat eq "lat"){
	unless(-e $latout){
		mkpath($latout,{mode=>0777})||die "can not mkpath folder ".$latout.": ".$!;
	}
}

my $configrec ="";
unless ($wi_cro eq "cross"){
	$configrec = $CONFIG."/configwi";	
}else{
	$configrec = $CONFIG."/configcross";	
}
my $latop = "";
if($outlat eq "lat"){
	$latop = "-z lat -l $latout -n 4";
}elsif(($outlat eq "nolat")||($outlat eq '')){
	$latop ="";
}else{
	die "the eval_nov92_muti should have the input parameter \$outlat be selected in [lat|nolat|]";
}

my $prerecstr = "hvite_nov92".$addstr;

unless($iflocal){

	# it is necessary to use muti mode and sub processes. 这里没有必要用子进程，原来用了进程写程序，目前懒得改成非子进程的普通程序了。

	for (my $I=1,my $J=0;$I<=$HVITE_SPLIT;){
		my @procs;
		my $jobstr = `job new \/jobname:eval92_muti_hd \/askednodes:EEE-SEL-DELLCN3 \/numprocessors:4 /scheduler:EEE-SEL-DCS1`;
		my $jobid;
		if ($jobstr =~ /Job queued, ID: (\d+)/) {
			$jobid = $1;	
			print "$jobstr contains ID plus digits\n";	
		}else{
			print "Nothing\n";
			pause("job create error");
		}
		
		for (my $T=0;$T<$HVITE_THREADS&$I<=$HVITE_SPLIT;$T++,$I++,$J++){	
			system $AUEXE."/OutputEvery.pl $scp_hostpath $HVITE_SPLIT $J > $outfold/eval_temp_split_$T.scp"; 		
			$procs[$T]=1;			
			print "HD:$T-$I ";
			(my $host_configrec = $configrec) =  s/$DISKROOT/$HOSTDISKROOT/gi;		
			(my $host_outfold = $outfold) =~ s/$DISKROOT/$HOSTDISKROOT/gi;
			(my $host_hmmroot = $HMM_ROOT) =~ s/$DISKROOT/$HOSTDISKROOT/gi;
			(my $host_config   = $CONFIG)  =~ s/$DISKROOT/$HOSTDISKROOT/gi;
			(my $host_inwdnet = $inwdnet) =~ s/$DISKROOT/$HOSTDISKROOT/gi;
			(my $host_recdict = $recdict) =~ s/$DISKROOT/$HOSTDISKROOT/gi;
			(my $host_tlist = $TIEDLIST) =~ s/$DISKROOT/$HOSTDISKROOT/gi;
			(my $host_hmmbats = $HMM_BATS) =~ s/$DISKROOT/$HOSTDISKROOT/gi;
					
			my $hostcmd = join (
					" ",
					"HVite -A -T 1 -t ".$prune,
					"-C ".$host_configrec,
					"-H $host_hmmroot/$inhmm/macros -H $host_hmmroot/$inhmm/hmmdefs",
					"-S ".$host_outfold."/eval_temp_split_".$T.".scp",
					"-i ".$host_outfold."/recout_nov92".$addstr."_".$T."\.mlf",
					"-w ".$host_inwdnet,
					"-p ".$p." -s ".$s,
					$latop,
					$host_recdict,
					$host_tlist,
					">".$host_outfold."/hvite_nov92".$addstr."_".$T.".log");
					
			$cmd = $cmd."\>".$host_outfold."/".$prerecstr."_".$T.".log";					
			my $hostcmd = $HOSTHTK."/".$cmd;
			$hostcmd =~ s/\//\\/gi;
			open(OBAT,">".$DISLIB."/eval92_muti_$T.bat")||die "can not open ".$host_hmmbats."/eval92_muti_$T.bat for writting: ".$!;	
			print OBAT $hostcmd."\n";
			close OBAT;
		
			(my $dislib_host = $DISLIB) =~ s/$DISKROOT/$HOSTDISKROOT/gi;		
			 $dislib_host =~ s/\//\\/gi;
			
			my $jobcmd = "job add $jobid \/numprocessors:1 \/stderr:$dislib_host\\taskerr.$T.log \/scheduler:EEE-SEL-DCS1 \"$dislib_host\\eval92_muti_$T.bat\"";
			system $jobcmd;		
			#pause($jobcmd);
		}
		system "job submit /id:$jobid /scheduler:EEE-SEL-DCS1";


		while(1){
			my $str =`job view /scheduler:EEE-SEL-DCS1 $jobid`;
			if ($str =~ /\nStatus\s+\:\s+Finished\n/gi){
				print $str."\n";
				print "the job ".$jobid." is finished\n";
				last;
			}elsif($str =~ /\nStatus\s+\:\s+Failed\n/gi){
				print $str."\n";
				pause("the job ".$jobid." is failed");
				last;
			}elsif($str =~ /\nStatus\s+\:\s+Running\n/gi){
				my @errs;
				for(1..$HVITE_THREADS){
					my $num = $_;
					my $taskstr = `task view \/scheduler:EEE-SEL-DCS1 $jobid\.$num`;
					if ($taskstr =~ /\nStatus\s+\:\s+Running\n/){					
						print $jobid."\.".$num." Running  ";	
						next;
					}elsif($taskstr =~ /\nStatus\s+\:\s+Failed\n/){
						print $taskstr."\n";
						$errs[$num] = "err:".$jobid."\.".$num;
						pause("the task ".$jobid."\.".$num." is failed");
						next;
					}
				}
				last if (scalar @errs);
				
			}
			sleep(60);
		}
		
		for(0..$#procs){
			if(-e $DISLIB."/eval92_muti_".$_.".bat"){
				unlink($DISLIB."/eval92_muti_".$_.".bat")||die "can not unlink ".$DISLIB."/eval92_muti_".$_.".bat ".$!;
			}
			cat("\>\>", $outfold."/".$prerecstr.".log", $outfold."/".$prerecstr."_".$_.".log");		
			cat("\>\>", $outfold."/recout_nov92".$addstr."_tempall\.mlf", $outfold."/recout_nov92".$addstr."_".$_."\.mlf");  
		}
	
		
	}
		

}else{

	for (my $I=1,my $J=0;$I<=$HVITE_SPLIT;){
		my @procs;

		for (my $T=0;$T<$HVITE_THREADS&$I<=$HVITE_SPLIT;$T++,$I++,$J++){
		
			system $AUEXE."/OutputEvery.pl $scp $HVITE_SPLIT $J > $outfold/eval_temp_split_$T.scp"; 		
			defined($procs[$T] = fork()) or die "can not fork $!";
			#pause($proc);
			
			unless($procs[$T]) {			
				print "HVite:$T data chunk:$I\t";	
				my $cmd = join (
					" ",
					"HVite -A -T 1 -t ".$prune,
					"-C ".$configrec,
					"-H $HMM_ROOT/$inhmm/macros -H $HMM_ROOT/$inhmm/hmmdefs",
					"-S ".$outfold."/eval_temp_split_".$T.".scp",
					"-i ".$outfold."/recout_nov92".$addstr."_".$T."\.mlf",
					"-w ".$inwdnet,
					"-p ".$p." -s ".$s,
					$latop,
					$recdict,
					$TIEDLIST,
					">".$outfold."/hvite_nov92".$addstr."_".$T.".log");
				
				exec $cmd;
				die "can not exec HVite: ".$!;						
				exit 0;
			}		
		}

		foreach my $td (@procs){   
		
			if(!defined($td)){   
				print "not defined \$procs[0] next\n";
				next;   
			}
			waitpid($td,0);
			my $procsnum = scalar @procs;
			print "waitpid $td in scalar $procsnum processes\n";
		}
		for(0..$#procs){
			cat("\>\>", $outfold."/hvite_nov92".$addstr.".log", $outfold."/hvite_nov92".$addstr."_".$_.".log");
			
			cat("\>\>", $outfold."/recout_nov92".$addstr."_tempall\.mlf", $outfold."/recout_nov92".$addstr."_".$_."\.mlf");	
		}	
		
	}

}

for(<$outfold/*.mlf $outfold/*.log>){
	#print $_."\n";
	if (/.*\/(hvite|recout)\_nov92$addstr\_\d+\.(mlf|log)/g){
		#pause($addstr."\n".$_);
		if(-e $_){
			unlink($_)||die "can not unlink file ".$_.": ".$!;
			print "unlink $_\n";
		}
	}
}

for(<$outfold/*.scp>){
	if($_ =~ /.*\/eval_temp_split_\d+.scp/g){
		if(-e $_){
			unlink($_)||die "can not unlink file ".$_.": ".$!;
			print "unlink $_\n";
		}
	}
}


DEBUG:
my $tempoutallmlf = $outfold."/recout_nov92".$addstr."_tempall\.mlf";
my $outallmlf     = $outfold."/recout_nov92".$addstr."\.mlf";
open (ALL,"<".$tempoutallmlf)||die "can not open file".$tempoutallmlf." for reading: ".$!;
open (MLF,">".$outallmlf)||die "can not open file".$outallmlf." for writting: ".$!;
(my $hostroottemp = $HOSTROOT) =~ s/\\/\//gi;
(my $diskroottemp = $DISKROOT) =~ s/\\/\//gi;
print MLF "\#\!MLF\!\#\n";
while(<ALL>){
	chomp;
	if (/\#\!MLF\!\#/){
		next;
	}
	if (/^\"${hostroottemp}.+\"$/){
		s/$hostroottemp/$diskroottemp/gi;
	}	
	print MLF $_."\n";
}

close ALL;
close MLF;



# Now lets see how we did!  
#cd $TRAIN_WSJ0
# $tempwords     = $LIB."/temp_nov92_words.mlf";
# system "hled -A -T 1 -l * -i ".$tempwords." nul ".$TESTWORDS.">".$LOG."/hled_testwords2.log";
system "HResults -n -A -T 1 -L \* -I $mlf $TIEDLIST ".$outallmlf."\>".$outfold."/hresults_nov92".$addstr.".log";
#pause("HResults -n -A -T 1 -L \* -I $tempwords $TIEDLIST ".$outfold."/recout_nov92".$addstr."\.mlf\>".$outfold."/hresults_nov92".$addstr.".log");

# Add on a NIST style output result for good measure
system "HResults -n -h -A -T 1 -L \* -I $mlf $TIEDLIST ".$outallmlf."\>\>".$outfold."/hresults_nov92".$addstr.".log";

#pause("end");

movecopy_dir2("copy",$outfold,$bak);


print "...eval92_muti.pl finished\n";


