
# Train the word internal phonetic decision tree state tied models

#cd $TRAIN_WSJ0
require ("common_config.pl");

use File::Copy 'cp';
use File::Path 'rmtree';
my $lasthmm = lasthmm($HMM_ROOT."/prep_tied_endhmm.log");
my $beghmm  = $lasthmm;
my $tohmm   = $beghmm + 1;
# Cleanup old files and create new directories for model files
#rm -f -r hmm14 hmm15 hmm16 hmm17
for(0..3){
	my $num  = $tohmm + $_;
	my $hmm  = $HMM_ROOT."/hmm".$num;
	if (-e $hmm){
		#if(/17/){
		#	movecopy_dir("move", $hmm, $RUNBAK."/train_tied","tree");
		#}else{
		rmtree($hmm)||die "unable to rmtree hmm".$_.": ".$!;
		#}
	}
}
for(0..3){
	my $num  = $tohmm + $_;
	my $hmm  = $HMM_ROOT."/hmm".$num;
	create_fold($hmm,"tree","in train_tied.pl");
}
for(0..3){
	my $num  = $tohmm + $_;
	if (-e $HMM_ROOT."/hmm".$num."/hmm".$num."\.log"){
		unlink($HMM_ROOT."/hmm".$num."/hmm".$num."\.log");
	}	
}
#mkdir hmm14 hmm15 hmm16 hmm17
#rm -f hmm14.log hmm15.log hmm16.log hmm17.log

#cd $WSJ0_DIR

# HERest parameters:
#  -d    Where to look for the monophone defintions in
#  -C    Config file to load
#  -I    MLF containing the phone-level transcriptions
#  -t    Set pruning threshold (3.2.1)
#  -S    List of feature vector files
#  -H    Load this HMM macro definition file
#  -M    Store output in this directory
#  -m    Sets the minimum number of examples for training, by setting 
#        to 0 we stop suprious warnings about no examples for the 
#        sythensized triphones
#
# As per the CSTIT notes, do four rounds of reestimation (more than
# in the tutorial).
for(0..3){
	system $AUEXE."/train_iter_host.pl $HMM_ROOT hmm".$beghmm." hmm".$tohmm." ".$TIEDLIST." ".$TRIWORDS_WILD." 0 bin";
	++$beghmm;
	++$tohmm;	
}
--$beghmm;
--$tohmm;
system  "echo ".$tohmm.">$HMM_ROOT/train_tied_endhmm.log";

#HERest -B -A -T 1 -m 0 -C $TRAIN_COMMON/config -I $TRAIN_WSJ0/wintri.mlf -t 250.0 150.0 1000.0 -S train.scp -H $TRAIN_WSJ0/hmm13/macros -H $TRAIN_WSJ0/hmm13/hmmdefs -M $TRAIN_WSJ0/hmm14 $TRAIN_WSJ0/tiedlist >$TRAIN_WSJ0/hmm14.log
#$TRAIN_TIMIT/train_iter.sh $TRAIN_WSJ0 hmm13 hmm14 tiedlist wintri.mlf 0
#system "train_iter.pl $HMM_ROOT hmm13 hmm14 $TIEDLIST $TRIWORDS 0 bin";
#HERest -B -A -T 1 -m 0 -C $TRAIN_COMMON/config -I $TRAIN_WSJ0/wintri.mlf -t 250.0 150.0 1000.0 -S train.scp -H $TRAIN_WSJ0/hmm14/macros -H $TRAIN_WSJ0/hmm14/hmmdefs -M $TRAIN_WSJ0/hmm15 $TRAIN_WSJ0/tiedlist >$TRAIN_WSJ0/hmm15.log
#$TRAIN_TIMIT/train_iter.sh $TRAIN_WSJ0 hmm14 hmm15 tiedlist wintri.mlf 0
#system "train_iter.pl $HMM_ROOT hmm14 hmm15 $TIEDLIST $TRIWORDS 0 bin";
#HERest -B -A -T 1 -m 0 -C $TRAIN_COMMON/config -I $TRAIN_WSJ0/wintri.mlf -t 250.0 150.0 1000.0 -S train.scp -H $TRAIN_WSJ0/hmm15/macros -H $TRAIN_WSJ0/hmm15/hmmdefs -M $TRAIN_WSJ0/hmm16 $TRAIN_WSJ0/tiedlist >$TRAIN_WSJ0/hmm16.log
#$TRAIN_TIMIT/train_iter.sh $TRAIN_WSJ0 hmm15 hmm16 tiedlist wintri.mlf 0
#system "train_iter.pl $HMM_ROOT hmm15 hmm16 $TIEDLIST $TRIWORDS 0 bin";
#HERest -B -A -T 1 -m 0 -C $TRAIN_COMMON/config -I $TRAIN_WSJ0/wintri.mlf -t 250.0 150.0 1000.0 -S train.scp -H $TRAIN_WSJ0/hmm16/macros -H $TRAIN_WSJ0/hmm16/hmmdefs -M $TRAIN_WSJ0/hmm17 $TRAIN_WSJ0/tiedlist >$TRAIN_WSJ0/hmm17.log
#$TRAIN_TIMIT/train_iter.sh $TRAIN_WSJ0 hmm16 hmm17 tiedlist wintri.mlf 0
#system "train_iter.pl $HMM_ROOT hmm16 hmm17 $TIEDLIST $TRIWORDS 0 bin";


