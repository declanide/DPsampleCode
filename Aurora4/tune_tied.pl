require "common_config.pl";

use File::Copy 'mv';
use File::Copy 'copy';
use File::Path 'rmtree';
use File::Path 'mkpath';

if (@ARGV < 5){
	print $0.'usage:, $prune,$wi_cro,$type,$latfold,$wordlist_type,[$down_beam_col,$up_beam_col]\n';
	exit 0;
}

my ($prune,$wi_cro,$type,$latfold,$wordlist_type,$down_beam_col,$up_beam_col)=@ARGV;



unless($prune =~ /\./){
	$prune =~ s/(.+)/$1\.0/gi;
}
#my $prune   = 350.0;
my $addstr  =  "p".$LATP."s".$LATS."prune".$prune.$wi_cro;
my $recdict;

my $bestmodelnum = 0;
my $iflat   = "nolat";


#goto ALL;
#pause($TUNE_MAIN);
create_fold($TUNE_MAIN,"tree");
create_fold($TUNE_RECOUT,"tree");
create_fold($TUNE_WORK, "tree");
create_fold($TUNE_LAT, "tree");

#goto ALL;
#system "prep_tied_tune.pl $addstr $firstRO $firstTB $wi_cro lat";
#system "train_tied_tune.pl $addstr $firstRO $firstTB $wi_cro lat";
#system "eval_tied_tune_muti.pl"." ".$addstr." ".$firstRO." ".$firstTB." hmm37 $p $s $prune $wi_cro $DEVSCP lat";


ALL:
my $resfold = $TUNE_RECOUT."/".$addstr."_tune_tied";
create_fold($resfold, "tree");
my $resbak  = $TUNE_BAK."/recout/".$addstr."_tune_tied";
create_fold($resbak, "tree");

#my $allmlf   = $resfold."/recout\.mlf";
my $allresult   = $resfold."/hresult";
my $allhvitelog = $resfold."/hvite_dev92_tune";
my $alldevlog   = $resfold."/dev92_tune";
my $allhhedlog  = $resfold."/allhhed";
my $bestf 		= $resfold."/allresultsort";
my $rotbmod_acc_sort  = $resfold."/rotbmod_acc_sort";
my $bestmodelnum_file = $resfold."/bestmodelnum_to_rotb";

#print "snow here\n";
#goto ALL2;
foreach my $file($allresult,$allhvitelog,$alldevlog, $bestf,$rotbmod_acc_sort){
	foreach my $filenum(1,2){
		my $postfix = $filenum."\.log";
		#$file = $file.$postfix;
		#pause($file);
		if (-e $file.$postfix){
			mv($file.$postfix, $resbak)||die "can not move file ".$file.$postfix." to ".$resbak.": ".$!;
			#unlink($file.$postfix)||die "can not unlink file ".$file.$postfix.": ".$!;
		}
	}
}

for($TUNE_LOG, $allhhedlog,$bestmodelnum_file){
	if (-e $_){
		#unlink($_)||die "can not unlink file ".$_.": ".$!;
		mv($_,$resbak)||die "can not move file ".$_." to ".$resbak.": ".$!;
	}
}

#ALL2:
#pause();
open(MISS,">".$LOG."/miss_tune_rotb.log")||die "can not open file ".$LOG."/miss_tune_rotb.log: ".$!;

for my $rotb_file("rotb1","rotb2","rotb3","rotb4","rotb5"){
	my $rotbf = $DOC."/ro_tb_tied/".$rotb_file;
	unless((-e $rotbf)&(-f $rotbf)){
		next;
	}
	unless($rotb_file eq "rotb1"){
		if(-e $bestmodelnum_file){
			$bestmodelnum = onevalfromfile($bestmodelnum_file);	
		}
		unless($bestmodelnum){
			pause("bestmodelnum in tune tied");
		}
	}
	
	open(ROTB,"<".$rotbf)||die ("can not open file ".$rotb." for reading: ".$!);

	my $count = 0;

	while  ( $line = <ROTB>) {
		
		next if ($line =~ /^#/);
		next if ($line =~ /^\s+$/);
		next if ($line =~ /^\n$/);
		print $line;
		$line =~ s/[\r\n]//gi;
		++$count;
		
		my ($ro,$tb) = split /\s+/,$line;		
		my $tunefold  = $TUNE_WORK."/".$addstr;
		my $ro_tb   = "ro".$ro."tb".$tb;
		$tunefold     = $tunefold."/".$ro_tb;
		#pause($tunefold);
		my $hmmfold  = $tunefold;		
		my $recfold = $resfold;
		my $recbak  = $resbak;
						
		my $endfile1 = "train_tied_tune_endhmm1.log";
		my $endfile2 = "train_tied_tune_endhmm2.log";
			
		#goto NEXT if ($count == 1);
		system $AUEXE."/prep_tied_tune.pl $tunefold $ro $tb $wi_cro $iflat ".$allhhedlog;		
	
		#如果有bestmodelnum，表示要对状态数进行筛选，当状态数(modelnum) 不符合特定条件时，不运行这个括号后面的内容。
		if($bestmodelnum){
			my $modelnum = modelnum($tunefold,"modelnum.log",$iflat);
			if(($down_beam_col)&&($up_beam_col)){
				my $downbeam = $bestmodelnum * $down_beam_col;
				my $upbeam = $bestmodelnum * $up_beam_col;				
				if(($modelnum < $bestmodelnum - $downbeam)||($modelnum > $bestmodelnum + $upbeam)){
					print $ro_tb." is not processed because of the model num $modelnum is out of the range $bestmodelnum - $downbeam \<\-\-\-\> $bestmodelnum + $upbeam\.\n";
					print MISS $ro_tb." is not processed (modelnum\: $modelnum).\n";
					next;
				}				
			}elsif($down_beam_col){
				my $step_modelnum = $bestmodelnum * $up_beam_col;
				if($modelnum < $bestmodelnum - $step_modelnum){
					print $ro_tb." is not processed because of the model num ".$modelnum." is less than ".$bestmodelnum." \- ".$step_modelnum."\n";
					print MISS $ro_tb." is not processed (modelnum\: $modelnum).\n";
					next;
				}
			}elsif($up_beam_col){
				my $step_modelnum = $bestmodelnum * $up_beam_col;
				if($modelnum > $bestmodelnum + $step_modelnum){
					print $ro_tb." is not processed because of the model num ".$modelnum." is greater than ".$bestmodelnum." \+ ".$step_modelnum."\n";
					print MISS $ro_tb." is not processed (modelnum\: $modelnum).\n";
					next;
				}
			}else{		
				my $step_modelnum = $bestmodelnum * $MODEL_STEP_PEN;
				if(($modelnum < $bestmodelnum - $step_modelnum)||($modelnum > $bestmodelnum + $step_modelnum)){
					print $ro_tb." is not processed because of the model num $modelnum is out of the range $bestmodelnum - $step_modelnum \<\-\-\-\> $bestmodelnum + $step_modelnum\.\n";
					print MISS $ro_tb." is not processed (modelnum\: $modelnum).\n";
					next;
				}					
			}
		}
		
		print "snow here\n";
		#pause();
		# train type 是 2 不是 1 ， 这里指定了
		system $AUEXE."/train_tied_tune.pl $tunefold $ro $tb $wi_cro $iflat $type 4 del $endfile1 $endfile2";		
				print "snow2 here\n";
		system $AUEXE."/tune_tied_rec.pl $recfold $hmmfold $wi_cro $ro $tb $DEVSCP $recbak $iflat ".$endfile1." ".$latfold." ".$wordlist_type;	
		   print "snow3 here\n";
		system $AUEXE."/tune_tied_rec.pl $recfold $hmmfold $wi_cro $ro $tb $DEVSCP $recbak $iflat ".$endfile2." ".$latfold." ".$wordlist_type;
			print "snow4 here\n";
		#NEXT:
		#pause("allhhed") if ($count == 1);

		my $filenum = 0;

		for my $tempendfile($endfile1,$endfile2){
			++$filenum;			
			my $opfold="";
			if($iflat eq "lat"){
				$opfold = "\/withlat";
			}elsif($iflat eq "nolat"){
				$opfold = "\/nolat";
			}
		
			my $hmmid = lasthmm($tunefold.$opfold."/".$tempendfile);		
			my $recmlf   = $recfold.$opfold."/recout".$ro_tb.$hmmid."\.mlf";
			my $result   = $recfold.$opfold."/hresult".$ro_tb.$hmmid."\.log";
			my $hvitelog = $recfold.$opfold."/hvite_dev92_tune\_".$ro_tb.$hmmid.".log";
			my $devlog   = $recfold.$opfold."/dev92_tune\_".$ro_tb.$hmmid.".log";			
			my $postfix = $filenum."\.log";
			
			cat("\>\>",$allresult.$postfix,$result);		
			cat("\>\>",$allhvitelog.$postfix,$hvitelog);
			cat("\>\>",$alldevlog.$postfix, $devlog);
		
			for($result,$hvitelog,$devlog){
				if (-e $tempendfile){
					unlink($tempendfile)||die "can not unlink $tempendfile: $!";
				}
			}
		}
		
		
	}
	close ROTB;
	
	#if($rotb_file eq "rotb1"){
	# 这里 排序会不断递增，虽然附加了rotbX, 但是rotb2的结果也是包含rotb1的结果的。所以这里rotb3 或者 rotb4等有更大数字的rotb文件，  会得到全部的排序
	system $AUEXE."/findbestrotb.pl ".$alldevlog."2.log\>".$bestf.$rotb_file;	
	system $AUEXE."/rotbmod_acc.pl ".$allhhedlog." ".$bestf.$rotb_file." ".$bestmodelnum_file."\>".$rotbmod_acc_sort."_".$rotb_file; 
	
	#pause($rotbf);
}

close MISS;


movecopy_dir("copy",$resfold,$resbak."/alllog","tree");


for my $filenum(1,2){
	my $postfix = $filenum."\.log";
	system $AUEXE."/findbestrotb.pl ".$alldevlog.$postfix."\>".$bestf.$postfix;
	
	system $AUEXE."/rotbmod_acc.pl ".$allhhedlog." ".$bestf.$postfix."\>".$rotbmod_acc_sort.$postfix;
}

my $thebestsort = $bestf."2.log";
my $bestnum = 0;

open(IN,"<".$thebestsort)||die "can not open file ".$thebestsort." for reading: ".$!;
open(OUT, ">".$TUNE_LOG)||die "can not open file ".$TUNE_LOG." for writting: ".$!;
while(<IN>){	
	chomp;
	if (/best\:\s*(\d+)\s+(\d+)/){
		++$bestnum;
		print OUT $bestnum.": ".$1."\t".$2."\n";
	}
}
close IN;
close OUT;


sub modelnum{
	my ($fold,$name,$iflat) = @_;
	if($iflat eq "lat"){
		$fold = $fold."/withlat";
	}elsif($iflat eq "nolat"){
		$fold = $fold."/nolat"; 
	}elsif($iflat eq ""){
		$fold = $fold."/nolat"; 
	}
	my $modelnum = onevalfromfile($fold."/".$name);
	return $modelnum;
}







