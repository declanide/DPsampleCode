# Does a single iteration of HERest training.
#
# This handles the parallel splitting and recombining
# of the accumulator files.  This is neccessary to 
# prevent inccuracies and eventual failure with large
# amounts of training data.
#
# According to Phil Woodland, one accumulator file 
# should be generated for about each hour of training
# data.
#
# Parameters:
#   $1 - root directory (where HMM directories are, tiedlist, wintri.mlf)
#   $2 - name of existing HMM directory
#   $3 - name of new output HMM directory
#   $4 - name of model list (tiedlist or monophones1)
#   $5 - training mlf (wintri.mlf or aligned2.mlf)
#   $6 - minimum examples -m switch for HERest
#   $7 - "text" if we want text output of HMM
#
# Environment variable $HEREST_SPLIT should be set to how 
# many chunks to split the training data into.
#
# This is a version that can split up the work amoung multiple
# processors/cores on the same machine.  The environment variable
# $HEREST_THREADS controls the number of threads.  
# Thanks to Mikel Penagarikano.
require "common_config.pl";
use File::Path 'mkpath';
use POSIX qw(:sys_wait_h);


my ($path, $org, $dst, $hmmlist, $mlf, $mini_examp, $bintext,$trainlist) = @ARGV;

my $tscp = "";
unless ($trainlist){
	$tscp 	 = $TRAINSCP_HOSTPATH;
}else{
	$tscp    = $trainlist;
}
#pause($tscp);

unless($bintext){
	$bintext = "bin";
}
print "begin training $tscp in $bintext\n$org \-\> $dst...\n";

my $inhmm  = $path."/".$org;
my $outhmm = $path."/".$dst;

# Delete any existing log file
#rm -f $1/$3.log

for (glob $outhmm."/*.log") {	
	unlink || die "can not delete ".$_.": ".$!;
}


# Make sure we have a place to put things
#mkdir -p $1/$3
unless (-e $outhmm){
	mkpath($outmm, 0777) || die("can not mkpath $outhmm in train_iter.pl: ".$!);
}
#rm -f $1/$3/HER*.acc
#goto TEST;

# opendir DIR, $outhmm or die "Cannot open $outhmm: $!";
# while (my $name = readdir DIR) {
	##next if $name =~ /^\./; 		   				#跳过点文件
	# next unless $name =~ /HER.*\.acc/; # 跳过非目标文件
	# $name = "$outhmm/$name"; 		#加上目录名
	# unlink($name)||die "can not delete file ".$name.": ".$!;
# }
# closedir DIR;

my $ifexclusivestr = "";
if($IFEXCLUSIVE){
	$ifexclusivestr = "\/exclusive:".$IFEXCLUSIVE;
}

my $trainsleeptime = 15;
if($TRAIN_SLEEP_TIM){
	$trainsleeptime = $TRAIN_SLEEP_TIM;
}


# Create all the accumulator files, parallaize over $HEREST_THREADS workers
for (my $I=1,my $J=0;$I<=$HEREST_SPLIT;){
	my $jobstr = `job new \/jobname:train_iter_host_$TRAINNAMESTR \/askednodes:$USENODE \/numprocessors:$COMMONPROCCESSORS $ifexclusivestr /scheduler:$HEADNODE`;
	#pause("job new \/jobname:train_iter_host_$TRAINNAMESTR $ifexclusivestr \/askednodes:$USENODE \/numprocessors:$COMMONPROCCESSORS /scheduler:$HEADNODE");
	my $jobid;
	if ($jobstr =~ /Job queued, ID: (\d+)/) {
		$jobid = $1;	
		print "$jobstr contains ID plus digits\n";	
	}else{
		print "Nothing\n";
		pause("job create error");
	}
	
    for (my $T=0;$T<$HEREST_THREADS&$I<=$HEREST_SPLIT;$T++,$I++,$J++){
		system $AUEXE."/OutputEvery.pl $tscp $HEREST_SPLIT $J > $outhmm/train_temp_split_$T.scp"; 		
		(my $inhmm_host = $inhmm) =~ s/$DISKROOT/$HOSTDISKROOT/gi;
		$inhmm_host =~ s/\//\\/gi;
		(my $outhmm_host= $outhmm)=~ s/$DISKROOT/$HOSTDISKROOT/gi;
		$outhmm_host =~ s/\//\\/gi;
		(my $mlf_host = $mlf) =~ s/$DISKROOT/$HOSTDISKROOT/gi;
		$mlf_host =~ s/\//\\/gi;
		(my $hmmlist_host = $hmmlist) =~ s/$DISKROOT/$HOSTDISKROOT/gi;
		$hmmlist_host =~ s/\//\\/gi;
		(my $hmmbats_host =$HMM_BATS) =~ s/$DISKROOT/$HOSTDISKROOT/gi;
		$hmmbats_host =~ s/\//\\/gi;
		
		#defined($procs[$T] = fork()) or die "can not fork $!";
		#pause($proc);
        #unless($procs[$T]) {		
		#print "$T: data chunk:$I\t";			
		my $cmd = "HERest -B -m $mini_examp -A -T 1 -p $I -s $outhmm_host/stats_$dst -C $HOSTCONFIG/config -I $mlf_host -t 250.0 150.0 2000.0 -S $outhmm_host/train_temp_split_$T.scp -H $inhmm_host/macros -H $inhmm_host/hmmdefs -M $outhmm_host $hmmlist_host>$outhmm_host/THREAD_$T.log";
		$hostcmd = $HOSTHTK."/".$cmd;
		$hostcmd =~ s/\//\\/gi;		
		open(OBAT,">".$HMM_BATS."/trainiter$T.bat")||die "can not open ".$HMM_BATS."/trainiter$T.bat for reading ".$!;
		print OBAT $hostcmd."\n";
		close OBAT;
		my $jobcmd = "job add $jobid \/numprocessors:1 \/workdir:$outhmm_host \/stderr:$hmmbats_host\\trainiter_taskerr.$T.log \/scheduler:$HEADNODE \"$hmmbats_host\\trainiter$T.bat\"";
		#pause($jobcmd);
		system $jobcmd;	
	}	
	
	system "job submit /id:$jobid /scheduler:$HEADNODE";
	
	while(1){
		my $str =`job view /scheduler:$HEADNODE $jobid`;
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
			for(1..$HEREST_THREADS){
				my $num = $_;
				my $taskstr = `task view \/scheduler:$HEADNODE $jobid\.$num`;
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
		sleep($trainsleeptime);
	}
	
	for (glob $HMM_BATS."/trainiter_taskerr.*.log") {	
		unlink;	
	}
	for (glob $HMM_BATS."/trainiter*.bat") {	
		unlink;	
	}
	for (glob $outhmm."/THREAD_*.log") {
		cat("\>\>", $outhmm."/".$dst.".log", $_);
		unlink;
	}
}

    # foreach my $td (@procs) {   
        # if(!defined($td)){   
            # print "not defined \$procs[0] next\n";
            # next;   
        # }
		# waitpid($td,0);
		##print "waitpid $td   ";
	# }






for (sort (glob ($outhmm."/HER*.acc"))){
	system "echo $_\>\>$outhmm/acc_files.txt";
}


#ls($outhmm, 'HER.*\.acc', ">",$outhmm."/acc_files.txt");

# for (my $t=0;$t<$HEREST_THREADS;$t++){
	# pause("cat");
	# cat("\>\>", $outhmm."/".$dst.".log", $outhmm."/THREAD_$t.log");
	# pause();		
	# if(-e $outhmm."/THREAD_$t.log"){
		# unlink($outhmm."/THREAD_".$t.".log")||die "can not delete ".$outhmm."/THREAD_".$t.".log"; 
	# }		
# }


# Create all the accumulator files, parallaize over $HEREST_THREADS workers
# for ((I=1,J=0;I<=$HEREST_SPLIT;)); do
    # for ((T=0;T<$HEREST_THREADS&I<=$HEREST_SPLIT;T++,I++,J++)); do
        # perl $TRAIN_SCRIPTS/OutputEvery.pl train.scp $HEREST_SPLIT $J > train_temp_split_$T.scp

        # HERest -B -m $6 -A -T 1 -p $I -s $1/$3/stats_$3 -C $TRAIN_COMMON/config -I $1/$5 -t 250.0 150.0 2000.0 -S train_temp_split_$T.scp -H $1/$2/macros -H $1/$2/hmmdefs -M $1/$3 $1/$4 > THREAD_$T.log &
    # done
    # wait
    # for ((t=0;t<$T;t++)); do cat THREAD_$t.log >> $1/$3.log; rm THREAD_$t.log ; done
# done

#ls -1 $1/$3/HER*.acc >acc_files.txt


# Now combine them all and create the new HMM definition
# if [[ $bintext eq "text" ]]
# then
# HERest -B -m $6 -A -T 1 -p 0 -s $1/$3/stats_$3 -C $TRAIN_COMMON/config -I $1/$5 -t 250.0 150.0 2000.0 -S acc_files.txt -H $1/$2/macros -H $1/$2/hmmdefs -M $1/$3 $1/$4 >>$1/$3.log
# else
# HERest -m $6 -A -T 1 -p 0 -s $1/$3/stats_$3 -C $TRAIN_COMMON/config -I $1/$5 -t 250.0 150.0 2000.0 -S acc_files.txt -H $1/$2/macros -H $1/$2/hmmdefs -M $1/$3 $1/$4 >>$1/$3.log
# fi
print "\nfinal HERest training ";
my $opstr = "";
unless ($bintext eq "text"){
	$opstr = "-B";
	print "in bin\n"
}else{
	print "in text\n"
}

my $traincmd = join (
	" ",
	"HERest ",
	$opstr,
	"-m ".$mini_examp,
	"-A -T 1 -p 0 -s ".$outhmm."/stats_".$dst,
	"-C ".$CONFIG."/config",
	"-I ".$mlf,
	"-t 250.0 150.0 2000.0",
	"-S ".$outhmm."/acc_files.txt",
	"-H ".$inhmm."/macros",
	"-H ".$inhmm."/hmmdefs",
	"-M ".$outhmm,
	$hmmlist,
	"\>\>".$outhmm."/".$dst."\.log");
system $traincmd;

#pause("final HERest");

#HERest -B -m $6 -A -T 1 -p 0 -s $1/$3/stats_$3 -C $TRAIN_COMMON/config -I $1/$5 -t 250.0 150.0 2000.0 -S acc_files.txt -H $1/$2/macros -H $1/$2/hmmdefs -M $1/$3 $1/$4 >>$1/$3.log
#}else {
#	HERest -m $6 -A -T 1 -p 0 -s $1/$3/stats_$3 -C $TRAIN_COMMON/config -I $1/$5 -t 250.0 150.0 2000.0 -S acc_files.txt -H $1/$2/macros -H $1/$2/hmmdefs -M $1/$3 $1/$4 >>$1/$3.log
#}


#rm -f train_temp_split.scp acc_files.txt
#rm -f $1/$3/HER*.acc
#goto ENDLAB;
if (-e $outhmm."/acc_files.txt"){	
	unlink($outhmm."/acc_files.txt")||die "can not delete file ".$outhmm."/acc_files.txt: ".$!;
	
}

for (glob ($outhmm."/HER*.acc")){	
	unlink;
}

for (glob ($outhmm."/train_temp_split_*.log")){
	unlink;
}
for (glob ($outhmm."/train_temp_split_*.scp")){
	unlink if /.*train_temp_split_\d+\.scp/gi;
}

#ENDLAB:
print "...finish training $org \-\> $dst\n";









