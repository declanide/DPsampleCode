
# Mixup the number of Gaussians per state, from 1 up to 8.
# We do this in 4 steps, with 4 rounds of reestimation 
# each time.  We mix to 8 to match paper "Large Vocabulary
# Continuous Speech Recognition Using HTK"
#
# Also per Phil Woodland's comment in the mailing list, we
# will let the sp/sil model have double the number of 
# Gaussians.
#
# This version does sil mixup to 2 first, then from 2->4->6->8 for
# normal and double for sil.
require ("common_config.pl");


use File::Copy 'cp';
use File::Path 'rmtree';

#cd $TRAIN_WSJ0

# Prepare new directories for all our model files
#rm -f -r hmm18 hmm19 hmm20 hmm21 hmm22 hmm23 hmm24 hmm25 hmm26 hmm27 hmm28 hmm29 hmm30 hmm31 hmm32 hmm33 hmm34 hmm35 hmm36 hmm37 hmm38 hmm39 hmm40 hmm41 hmm42
#mkdir hmm18 hmm19 hmm20 hmm21 hmm22 hmm23 hmm24 hmm25 hmm26 hmm27 hmm28 hmm29 hmm30 hmm31 hmm32 hmm33 hmm34 hmm35 hmm36 hmm37 hmm38 hmm39 hmm40 hmm41 hmm42
#rm -f hmm18.log hmm19.log hmm20.log hmm21.log hmm22.log hmm23.log hmm24.log hmm25.log hmm26.log hmm27.log hmm28.log hmm29.log hmm30.log hmm31.log hmm32.log hmm33.log hmm34.log hmm35.log hmm36.log hmm37.log hmm38.log hmm39.log hmm40.log hmm41.log hmm42.log hhed_mixup2.log hhed_mixup3.log hhed_mixup4.log hhed_mixup5.log hhed_mixup8.log hhed_mixup12.log hhed_mixup16.log

my($type) = @ARGV;

my $lasthmm = lasthmm($HMM_ROOT."/train_tied_endhmm.log");

my $beghmm = $lasthmm;
my $tohmm  = $beghmm+1;

# 1. 原来， 2 aurora
my $trainCount;
if(($type == 1)||($type == 0)){
	$trainCount = 5*5;	
}elsif($type == 2){
	$trainCount = 4*5; 
} 
#pause($trainCount);
--$trainCount;

$trainCount2 = $trainCount - 1;
#18... 42;
for(0..$trainCount2){
	my $num = $tohmm + $_;
	if (-e $HMM_ROOT."/hmm".$num){
		#if(/42/){
			#movecopy_dir("move",$HMM_ROOT."/hmm".$num,$RUNBAK,"tree") if (-e $HMM_ROOT."/hmm".$num);
		#}else{
			rmtree($HMM_ROOT."/hmm".$num)||die "can not rmtree hmm$num: ".$!;
		#}	
	}
}


for(0..$trainCount){
	my $num = $tohmm + $_;
	unless (-e $HMM_ROOT."/hmm".$num){
		mkdir($HMM_ROOT."/hmm".$num)||die "can not mkdir hmm".$num.": ".$!;
	}	
}
for(0..$trainCount){
	my $num = $tohmm + $_;
	if (-e $HMM_ROOT."/hmm".$num."/hmm".$num."\.log"){
		unlink($HMM_ROOT."/hmm".$num."/hmm".$num."\.log")||die "can not rmtree hmm".$num."\.log: ".$!;
	}
}
for(1..16){
	#type 1
	#mix1, 2, 4, 6, 8
	if (-e $LOG."/hhed_mixup".$_."\.log"){
		unlink($LOG."/hhed_mixup".$_."\.log");
	}
	# type 2
	#mix2, 4, 8, 16
	if (-e $LOG."/hhed_mixup".$_."_new\.log"){
		unlink($LOG."/hhed_mixup".$_."_new\.log");
	}

}

#my $beghmm = 17;
#my $tohmm  = $beghmm+1;
#1 原来， aurora 2
if(($type == 1)||($type == 0)){
	print "mixture 1\n";
	system "HHEd -B -H $HMM_ROOT/hmm".$beghmm."/macros -H $HMM_ROOT/hmm".$n."/hmmdefs -M $HMM_ROOT/hmm".$tohmm." ".$DOC."\/mix1.hed ".$TIEDLIST."\>$LOG/hhed_mix1.log";
	++$beghmm; ++$tohmm;
	system $AUEXE."/train_iter.pl $HMM_ROOT hmm$beghmm hmm$tohmm $TIEDLIST $TRIWORDS 0 bin $TRAINSCP";
	++$beghmm; ++$tohmm;
	system $AUEXE."/train_iter.pl $HMM_ROOT hmm$beghmm hmm$tohmm $TIEDLIST $TRIWORDS 0 bin $TRAINSCP";
	++$beghmm; ++$tohmm;
	system $AUEXE."/train_iter.pl $HMM_ROOT hmm$beghmm hmm$tohmm $TIEDLIST $TRIWORDS 0 bin $TRAINSCP";
	++$beghmm; ++$tohmm;
	system $AUEXE."/train_iter.pl $HMM_ROOT hmm$beghmm hmm$tohmm $TIEDLIST $TRIWORDS 0 bin $TRAINSCP";
	++$beghmm; ++$tohmm;
}

#pause();
my $count = 1;
my $mixnum = 2;
while($count <= 4){
	
	my $postfix;
	#2 aurora, 1 原来
	if($type == 2){
		$postfix = $mixnum."_new";
	}else{
		$postfix = $mixnum;
	}
	print "mixture ".$mixnum."\n";
	system "HHEd -B -H $HMM_ROOT/hmm".$beghmm."/macros -H $HMM_ROOT/hmm".$beghmm."/hmmdefs -M $HMM_ROOT/hmm".$tohmm." $DOC/mix".$postfix.".hed $TIEDLIST >$LOG/hhed_mix".$postfix.".log";

	#pause( "HHEd -B -H $HMM_ROOT/hmm".$beghmm."/macros -H $HMM_ROOT/hmm".$beghmm."/hmmdefs -M $HMM_ROOT/hmm".$tohmm." $DOC/mix".$postfix.".hed $TIEDLIST >$LOG/hhed_mix".$postfix.".log");
	++$beghmm; ++$tohmm;
	system $AUEXE."/train_iter.pl $HMM_ROOT hmm$beghmm hmm$tohmm $TIEDLIST $TRIWORDS 0 bin $TRAINSCP";
	++$beghmm; ++$tohmm;
	system $AUEXE."/train_iter.pl $HMM_ROOT hmm$beghmm hmm$tohmm $TIEDLIST $TRIWORDS 0 bin $TRAINSCP";
	++$beghmm; ++$tohmm;
	system $AUEXE."/train_iter.pl $HMM_ROOT hmm$beghmm hmm$tohmm $TIEDLIST $TRIWORDS 0 bin $TRAINSCP";
	++$beghmm; ++$tohmm;
	system $AUEXE."/train_iter.pl $HMM_ROOT hmm$beghmm hmm$tohmm $TIEDLIST $TRIWORDS 0 bin $TRAINSCP";
	++$beghmm; ++$tohmm;
	#1 原来， 2  aurora
	if(($type == 1)||($type == 0)){
		$mixnum = $mixnum + 2;
	}elsif($type == 2){
		$mixnum = $mixnum * 2;
	}
	++$count;
}
--$beghmm;--$tohmm;

system "echo ".$tohmm.">".$HMM_ROOT."/train_mixup_endhmm.log";







