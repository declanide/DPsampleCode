# Train the triphone models
require ("common_config.pl");

use File::Copy 'cp';
my ($type) = @ARGV;

#goto ENDLAB;

my $lasthmm = lasthmm($HMM_ROOT."/prep_tri_endhmm.log");

my $beghmm = $lasthmm;
my $tohmm  = $beghmm + 1;
#cd $TRAIN_WSJ0

#1 or 0  ---> 老外模式     type 2--> Aurora 模式;  
my $tn;
if(($type == 1)||($type == 0)){
	$tn = 1;
}elsif($type == 2){
	$tn = 3;	
}

#11  12 13 14
for(0..$tn) {
	my $hmm = $tohmm + $_;
	$hmm    = $HMM_ROOT."/hmm".$hmm;
	if (-e $hmm){
		#if (/12/){
		#	movecopy_dir("move",$HMM_ROOT."/hmm".$_,$RUNBAK."/train_tri","tree");
		#}else{
		rmtree($hmm)||die "can not rmtree hmm".$hmm." folder: ".$!;
		#}
	}
}
#pause();

#11  12 13 14
#rm -f -r hmm11 hmm12 hmm11.log hmm12.log
for(0..$tn){
	my $hmm = $tohmm + $_;
	$hmm    = $HMM_ROOT."/hmm".$hmm;

	unless(-e $hmm){
		mkpath($hmm, 0777)||die "can not mkpath hmm".$hmm." folder: ".$!;
	}
}

#mkpath($hmm11,$hmm12,{verbose=>1,mode=>0777,error=> \my $err_list});
#print "mkpath error: $_" for(@$err_list);

#cd $WSJ0_DIR

# HERest -B -A -T 1 -m 1 -d $TRAIN_WSJ0/hmm10 -C $TRAIN_COMMON/config -I $TRAIN_WSJ0/wintri.mlf -t 250.0 150.0 1500.0 -S train.scp -H $TRAIN_WSJ0/hmm10/macros -H $TRAIN_WSJ0/hmm10/hmmdefs -M $TRAIN_WSJ0/hmm11 $TRAIN_WSJ0/triphones1 >$TRAIN_WSJ0/hmm11.log
#$TRAIN_TIMIT/train_iter.sh $TRAIN_WSJ0 hmm10 hmm11 triphones1 wintri.mlf 1


# Second round, also generate stats file we use for state tying
#HERest -B -A -T 1 -m 1 -d $TRAIN_WSJ0/hmm11 -C $TRAIN_COMMON/config -I $TRAIN_WSJ0/wintri.mlf -t 250.0 150.0 1500.0 -s $TRAIN_WSJ0/stats -S train.scp -H $TRAIN_WSJ0/hmm11/macros -H $TRAIN_WSJ0/hmm11/hmmdefs -M $TRAIN_WSJ0/hmm12 $TRAIN_WSJ0/triphones1 >$TRAIN_WSJ0/hmm12.log
#$TRAIN_TIMIT/train_iter.sh $TRAIN_WSJ0 hmm11 hmm12 triphones1 wintri.mlf 1
#11  12 13 14
for(0..$tn){
	system $AUEXE."/train_iter.pl $HMM_ROOT hmm".$beghmm." hmm".$tohmm." $TRILIST1 $TRIWORDS 1 bin $TRAINSCP";
	++$beghmm;
	++$tohmm;
}
--$beghmm; --$tohmm;
# Copy the stats file off to the main directory for use in state tying
#14
cp ($HMM_ROOT."/hmm".$tohmm."/stats_hmm".$tohmm,$LIB."/stats")||die "unable to copy file hmm".$tohmm."/stats_hmm".$tohmm." to file $LIB/stats";

#ENDLAB:
system "echo ".$tohmm.">".$HMM_ROOT."/train_tri_endhmm.log";
#system "echo 19>".$HMM_ROOT."/train_tri_endhmm.log";

print "...finish the training of triphones\n";

#pause("finish the training of tri");

