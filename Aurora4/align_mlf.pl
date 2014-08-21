
# Aligns a new MLF based on the best monophone models.
#
# Parameters:
#  1 - "flat" if we are flat starting from monophone models living
#      in hmm5 in this directory.
require ("common_config.pl");

use File::Copy 'cp';

my ($ifflat,$main) = @ARGV;
if (@ARGV != 2){
	print "$0 usage:ifflat, main path\n";
	exit(0);
}
print $ifflat." align_mlf...\n";
#cd $WSJ0_DIR

# Cleanup old files
#rm -f $TRAIN_WSJ0/hvite_align.log $TRAIN_WSJ0/hled_sp_sil.log
for("hvite_align.log","hled_sp_sil.log","removeprunefiles.log"){
	if(-e $LOG."/".$_){
		unlink($LOG."/".$_)||die "can not delete file ".$LOG."/".$_.": ".$!;
	}
}

my $lasthmm = lasthmm($main."/flat_start_endhmm.log");

# Do alignment using our best monophone models to create a phone-level MLF
# HVite parameters
#  -l       Path to use in the names in the output MLF
#  -o SWT   How to output labels, S remove scores, 
#           W do not include words, T do not include times
#  -b       Use this word as the sentence boundary during alignment
#  -C       Config files
#  -a       Perform alignment
#  -H       HMM macro definition files
#  -i       Output to this MLF file
#  -m       During recognition keep track of model boundaries
#  -t       Enable beam searching
#  -y       Extension for output label files
#  -I       Word level MLF file
#  -S       File contain the list of MFC files

# if [[ $1 != "flat" ]]
# then
# HVite -A -T 1 -o SWT -b silence -C $TRAIN_COMMON/config -a -H $TRAIN_TIMIT/hmm8/macros -H $TRAIN_TIMIT/hmm8/hmmdefs -i $TRAIN_WSJ0/aligned.mlf -m -t 250.0 -I $TRAIN_WSJ0/words.mlf -S train.scp $TRAIN_TIMIT/cmu6spsil $TRAIN_TIMIT/monophones1 >$TRAIN_WSJ0/hvite_align.log
# else
# HVite -A -T 1 -o SWT -b silence -C $TRAIN_COMMON/config -a -H $TRAIN_WSJ0/hmm5/macros -H $TRAIN_WSJ0/hmm5/hmmdefs -i $TRAIN_WSJ0/aligned.mlf -m -t 250.0 -I $TRAIN_WSJ0/words.mlf -S train.scp $TRAIN_TIMIT/cmu6spsil $TRAIN_TIMIT/monophones1 >$TRAIN_WSJ0/hvite_align.log
# fi
#my $hmm5;
my $opstr = "";

if ($ifflat eq "flat"){
	my $hmm = $main."/hmm".$lasthmm;		
	$opstr = "-H ".$hmm."/macros -H ".$hmm."/hmmdefs";
	#pause($opstr);
}else{
	print "$0: the training must started from flat,or else some programs should be modified\n";
	exit(0);
}
#goto TEST;

my $cmd = "";
$cmd = join (
	" ",
	"HVite -A -T 1",
	"-o SWT -b silence",
	"-C ".$CONFIG."/config",
	"-a",
	$opstr,
	"-i ".$ALIGNED,
	"-m -t 250.0",
	"-I ".$WORDS,
	"-S ".$TRAINLIST_FEA,
	$LIB."/cmu6spsil",
	$MONOLIST1,
	">".$LOG."/hvite_align.log");
#pause($cmd);
system $cmd;

	# HVite -A -T 1 -o SWT -b silence -C $TRAIN_COMMON/config -a -H $TRAIN_TIMIT/hmm8/macros -H $TRAIN_TIMIT/hmm8/hmmdefs -i $TRAIN_WSJ0/aligned.mlf -m -t 250.0 -I $TRAIN_WSJ0/words.mlf -S train.scp $TRAIN_TIMIT/cmu6spsil $TRAIN_TIMIT/monophones1 >$TRAIN_WSJ0/hvite_align.log
# }else{
	# HVite -A -T 1 -o SWT -b silence -C $TRAIN_COMMON/config -a -H $TRAIN_WSJ0/hmm5/macros -H $TRAIN_WSJ0/hmm5/hmmdefs -i $TRAIN_WSJ0/aligned.mlf -m -t 250.0 -I $TRAIN_WSJ0/words.mlf -S train.scp $TRAIN_TIMIT/cmu6spsil $TRAIN_TIMIT/monophones1 >$TRAIN_WSJ0/hvite_align.log
# fi
# }

# We'll get a "sp sil" sequence at the end of each sentance.  Merge these
# into a single sil phone.  Also might get "sil sil", we'll merge anything
# combination of sp and sil into a single sil.
$cmd = join (
	" ",
	"HLEd -A -T 1",
	"-i ".$ALIGNED2,
	$DOC."/merge_sp_sil.led",
	$ALIGNED,
	">".$LOG."/hled_sp_sil.log");
system $cmd;

#HLEd -A -T 1 -i $TRAIN_WSJ0/aligned2.mlf $TRAIN_WSJ0/merge_sp_sil.led $TRAIN_WSJ0/aligned.mlf >$TRAIN_WSJ0/hled_sp_sil.log

# Forced alignment might fail for a few files (why?), these will be missing
# from the MLF, so we need to prune these out of the script so we don't try 
# and train on them.
#TEST:
#cp $WSJ0_DIR/train.scp $WSJ0_DIR/train_temp.scp
cp($TRAINLIST_FEA, $LIB."/train_temp.scp")||die "unable to copy file $TRAINLIST_FEA to $LIB/train_temp.scp: ".$!;
#perl $TRAIN_SCRIPTS/RemovePrunedFiles.pl $TRAIN_WSJ0/aligned2.mlf $WSJ0_DIR/train_temp.scp >$WSJ0_DIR/train.scp
system $AUEXE."/RemovePrunedFiles_me.pl $ALIGNED2 $LIB/train_temp.scp $LOG/removeprunefiles.log\>".$TRAINSCP;
#rm -f $WSJ0_DIR/train_temp.scp

if(-e $LIB."/train_temp.scp"){
	unlink($LIB."/train_temp.scp")||die "can not delete file ".$LIB."/train_temp.scp ".$!;
}




