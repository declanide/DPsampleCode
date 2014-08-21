require ("common_config.pl");


use File::Copy 'cp';
use File::Path 'rmtree';
use File::Path 'mkpath';
use POSIX qw(:sys_wait_h);

my($wi_cro, $addstr, $devortest,$rough_or_precise,$latfold, $co_n_vp)=@ARGV;

my $ifrough = "rough";
if ($rough_or_precise){
	$ifrough = $rough_or_precise;
}

my $rechmm = lasthmm($HMM_ROOT."/train_mixup_endhmm.log");

$rechmm    = "hmm".$rechmm;

my $latin  = $DEVLAT_FIRST_FOLD1;
if($latfold){
	$latin = $latfold;
}
#my $latin    = $LATFOLD."/".$addstr."_muti/p".$LATP."s".$LATS; 
# $latin 这个文件夹绝对不能有删除动作。
my $tunefold = $TUNE_REC."/".$devortest.$addstr."_".$ifrough;
my $bak = $RUNBAK."/tune_ins_scal/".$devortest.$ifrough.$addstr."tunemuti";

#goto DEBUG;

if(-e $bak){
	rmtree($bak)||die "can not rmtree ".$bak." ".$!;
}
unless(-e $bak){
	mkpath($bak)||die "can not mkpath ".$bak." ".$!;
}

if(-e $tunefold){	
	movecopy_dir2("move",$tunefold,$bak);
}
unless(-e $tunefold){
	mkpath($tunefold,{mode => 0777})||die "can not rmtree ".$tunefold;	
}

DEBUG:

my $runlog           = $tunefold."/runlog_ins_scal";


open(RUNLOG,">".$runlog)||die "can not open file ".$runlog." for reading \n";

#my $template_file    = "template_tune".$devortest."92_".$wi_cro."_muti";

my $fcount      = 0;
my $first_doc   = $tunefold."/ins_scal1";


open(OUT, ">".$first_doc)||die "can not open file ".$first_doc." for writting: ".$!;
for(my $i = 5.0; $i <=25.0; $i= $i + 0.5){
	$i = $i."\.0" unless($i =~ /[\d\-]+\.\d+/);
	print OUT "0.0 ".$i."\n";
}
close OUT; 
print RUNLOG "1: p 0.0\ts 3.0 0.5 21.0\n";


while(1){
	my $ins_scal;
	my $next_ins_scal;
	my $temp_count;
    ++$fcount;
	last if ($fcount > $TUNE_PS_LOOP);
	$ins_scal = $tunefold."/ins_scal".$fcount;

	$next_count = $fcount + 1;
	$next_ins_scal = $tunefold."/ins_scal".$next_count;
	
	next unless(-e $ins_scal);
	
	#goto MUTI if ($fcount == 1);	
	
	for (my $I=1,my $J=0;$I<=$TUNE_SPLIT;){
		my @procs;	my $cout = 0;
	    for (my $T=0;$T<$TUNE_THREADS&$I<=$TUNE_SPLIT;$T++,$I++,$J++){
			system $AUEXE."/OutputEvery.pl $ins_scal $TUNE_SPLIT $J > $tunefold/ins_scal_temp_split_$T"; 
	
			
			defined($procs[$T] = fork()) or die "can not fork $!";

	        unless($procs[$T]) {			
				print "exec tune process:$T data chunk:$I \n";	
				my $cmd = join (
						" ",
						$AUEXE."/ProcessNums_muti_me.pl",
						$tunefold."/ins_scal_temp_split_".$T,				
						$devortest,
						$latin,
						$tunefold,
						$T,
						$rechmm,
						$co_n_vp,
						"del");	
      
				exec $cmd;
				die "can not exec ProcessNums_muti_me.pl: ".$!;						
				exit 0;
			}		
		}

	    foreach my $td(@procs){   
			#my $td = $procs[$i];
	        if(!defined($td)){   
	            print "not defined \$procs[0] next\n";
	            next;   
	        }
			waitpid($td,0);			
			
			print "waitpid $td in process: $cout\n";
			++$cout;
		}
	 
	}	

	
	
	cat("\>\>", $tunefold."/".$devortest."92_tune_all.log", $tunefold."/".$devortest."92_tune.log");
	

	system $AUEXE."/findbestpara.pl $tunefold/".$devortest."92_tune.log\>$tunefold/findbestpara_loop$fcount.log";

	rename ($tunefold."/".$devortest."92_tune.log", $tunefold."/".$devortest."92_tune_loop$fcount.log")||die "can not rename $tunefold/$devortest92_tune.log to $tunefold/$devortest92_tune_loop$fcount.log";
   
	
	# get the serveral best paras. the num is bestnum;
	my $bestnum  = 0;
	if ($ifrough eq  "rough"){
		if ($fcount == 1){
			$bestnum = 5;	
		}elsif($fcount >= 2){	
		}
	}elsif($ifrough eq "precise"){	
		if ($fcount == 1){
			$bestnum = 15;			
		}elsif($fcount == 2){
			$bestnum = 3;
		}elsif($fcount == 3){
			$bestnum = 18;
		}
	}	
	
	
	
	bestlog($tunefold."/findbestpara_loop$fcount.log", $tunefold."/best_loop$fcount.log",$bestnum);
	
	if($ifrough eq "precise"){
		last if ($fcount == 4);
	}elsif($ifrough eq "rough"){
		last if ($fcount == 2);
	}
	
	
	my @paras = bestpara($tunefold."/best_loop$fcount.log",-1);
	
	# max and min of  paras.
	my @scas;my @inps, @inps, @inps; 
	for(@paras){
		print $_."\n";
		my ($tp,$ts)=split /\s+/,$_;		
		push(@inps, $tp);
		push(@scas,$ts);
	}
	
	@scas = sort {$a<=>$b} @scas;
	@inps = sort {$a<=>$b} @inps;
   
	my $max = $scas[-1]; my $min = $scas[0];

	my $ns = $min;	

	my $maxp = $inps[-1]; my $minp = $inps[0];					
	if ($ifrough eq "rough"){
		$nstep = 0.5;
	}elsif($ifrough eq "precise"){
		$nstep = 0.1;
	}
	
	open(NEXT, ">".$next_ins_scal)||die "can not open file $next_ins_scal for writting: ".$!;
	while(1){			
		$ns = $ns."\.0" unless ($ns =~ /[\-\d]+\.\d+/);			
		last if ($ns > $max);			
		#if ($fcount == 1){
		#	@nps = stepadd(-18.0,2.0,18.0);			
		if($fcount == 1){
			if($ifrough eq "precise"){
				print NEXT "0.0 ".$ns."\n";
			}elsif ($ifrough eq "rough"){
				my @nps = stepadd(-18.0, 2.0, 18.0);
				foreach my $np(@nps){						
					print NEXT $np." ".$ns."\n";
				}			
			}
		}elsif($fcount == 2){			
			my @nps = stepadd(-18.0, 3.0, 18.0);
			foreach my $np(@nps){						
				print NEXT $np." ".$ns."\n";
			}
		}elsif($fcount == 3){
			my @nps = stepadd($minp, 1.0, $maxp);
			foreach my $np(@nps){						
				print NEXT $np." ".$ns."\n";
			}			
		}elsif($fcount == 4){			
			pause("4 should quit before");
		}		
		$ns = $ns + $nstep;		
	}
	close NEXT;	
	if ($fcount == 1){
		print RUNLOG $next_count.": p 0.0\ts $min 0.1 $max\n" if($ifrough eq "preciese");
		print RUNLOG $next_count.": p -18.0 2 18.0\ts $min 0.1 $max\n" if($ifrough eq "rough");
	}elsif($fcount == 2){
		print RUNLOG $next_count.": p -18.0 3.0 18.0\ts $min 0.1 $max\n";
	}elsif($fcount == 3){
		print RUNLOG $next_count." p $minp 1.0 $maxp\ts $min 0.1 $max\n";
	}
	#close RUNLOG;
	#;	
}
close(RUNLOG);

#precise
# 第一遍，按照doc里面的数据来进行调试，运算 39次 （s 按照0.5递增，从2.0 到21.0 。
#		提取前10个scal， 提取最大和最小，生成第二遍的调试文件，接着s按照0.1 递增，p固定为0.0.
# 第二遍，按照第一遍得到的调试文件，进行调试。这时s按照0.1 递增，p固定为0.0. 最多运算100次，但是通常没有那么多次，因此估计为50次。
#  		提取前2个 scal,   这时s 是这2个数据， p固定为按照1.0递增, 从 -18.0到 18.0，生成第三遍的调试文件。
# 第三遍，按照第二遍所得到的调试文件，包括2个 scal,   这时s 是这2个数据， p固定为按照3.0递增, 从 -18.0到 18.0，这样总共要运算 11 * 3   33次。然后取出排在前面的18个,找最小最大，并按1.0递增，生成第四遍的调试数据。
#第四遍，利用第三遍的数据来调试，

#rough
# 第一遍，按照doc里面的数据来进行调试，运算 39次 （s 按照0.5递增，从2.0 到21.0 。
#		提取前3个scal， 提取最大和最小，接着s按照1 递增，p(-18.0 2.0 18.0) 
# 第二遍，按照第一遍得到的调试文件，进行调试。这时s按照0.1 递增，p固定为0.0. 最多运算100次，但是通常没有那么多次，因此估计为50次。
#  		提取前2个 scal,   这时s 是这2个数据， p固定为按照1.0递增, 从 -18.0到 18.0，生成第三遍的调试文件。
# 第三遍，按照第二遍所得到的调试文件，包括2个 scal,   这时s 是这2个数据， p固定为按照3.0递增, 从 -18.0到 18.0，这样总共要运算 11 * 3   33次。然后取出排在前面的18个,找最小最大，并按1.0递增，生成第四遍的调试数据。
#第四遍，利用第三遍的数据来调试，

#找到合适的那个


MIDEND:
movecopy_dir2("copy",$tunefold,$bak);

system $AUEXE."/findbestpara.pl ".$tunefold."/".$devortest."92_tune_all.log\>$tunefold/findbestpara_all.log";

bestlog($tunefold."/findbestpara_all.log",$TUNE_BESTPS_LOG,1);

# my $num = 0 ;
# open(IN,"<".$tunefold."/findbestpara_all.log")||die "can not open file ".$tunefold."/findbestpara_all.log"." for reading: ".$!;
# open(OUT, ">".$TUNE_BESTPS_LOG)||die "can not open file ".$TUNE_BESTPS_LOG." for writting: ".$!;
# while(<IN>){
   # ++$num;
	# chomp;
	# pause($_);
	# if (/best\:\s*([\-\.\d+])\s+([\-\.\d+])/){
		# print OUT $num."\: ".$1."\t".$2."\n";
		# pause($num."\: ".$1."\t".$2."\n");
	# }
# }
# close IN;
# close OUT;

#pause("in tune muti .pl ");

print "...tune has been finished\n";








