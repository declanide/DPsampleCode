# Take the best TIMIT monophone models and reestimate using the
# forced aligned phone transcriptions of WSJ0.
#
# Parameters:
#  $1 - "flat" if we are flat starting from monophone models living
#       in hmm5 in this directory.
require ("common_config.pl");

use File::Path;
use File::Copy 'cp';

unless(@ARGV == 1){	
	print $0.'ifflat'."\n";
	exit(0);
}
my ($ifflat) = @ARGV;

#cd $TRAIN_WSJ0
my $cmd ="";
# Copy our lists of monophones over from TIMIT directory

cp ($DOC."/monophones0", $MONOLIST0)||die "unable to copy file $DOC/monophones0 to $LIB: ".$!;
cp ($DOC."/monophones1", $MONOLIST1)||die "unable to copy file $DOC/monophones1 to $LIB: ".$!;

my $lasthmm = lasthmm($HMM_ROOT."/flat_start_endhmm.log");
my $newhmm  = $lasthmm + 1;
my $newend  = $lasthmm + 4;

my $hmm    = $HMM_ROOT."/hmm".$lasthmm;
my $hmmtxt = $HMM_ROOT."/hmm".$lasthmm."_text";

# Cleanup old files and directories
#rm -f -r hmm6 hmm7 hmm8 hmm9
for($newhmm..$newend) {
	if (-e $HMM_ROOT."/hmm".$_){
		#if(/9/){
		#	movecopy_dir("move",$HMM_ROOT."/hmm".$_,$RUNBAK."/train_mono","tree");
		#}else{
			rmtree($HMM_ROOT."/hmm".$_);
		#}
	}
	if(-e $HMM_ROOT."/hmm".$_."/hmm".$_.".log"){
		unlink($HMM_ROOT."/hmm".$_."/hmm".$_.".log");
	}	
}
if(-e $hmmtxt){
	rmtree($hmmtxt);
}

#pause(1);

for($newhmm..$newend){
	create_fold($HMM_ROOT."/hmm".$_,"tree","train_mono.pl hmm$_");
#mkdir hmm6 hmm7 hmm8 hmm9
}
unless(-e $hmmtxt){
	mkpath($hmmtxt);
}

#rm -f hmm6.log hmm7.log hmm8.log hmm9.log

# Now do three rounds of Baum-Welch reesimtation of the monophone models
# using the phone-level transcriptions.
#cd $WSJ0_DIR

unless ($ifflat eq "flat"){
# Copy over the TIMIT monophones to the same directory that a 
# flat-start would use.
	mkpath($hmm) || die "unable to mkpath ".$hmm.": ".$!;
#cp -f $TRAIN_TIMIT/hmm8/* $TRAIN_WSJ0/hmm5
	movecopy_dir("copy",$HMM_ROOT."/hmm8",$hmm);
#fi
}

# We'll create a new variance floor macro that reflects 1% of the 
# global variance over our WSJ0 + WSJ1 training data.

# First convert to text format so we can edit the macro file
#mkdir -p $TRAIN_WSJ0/hmm5_text

#HHEd -H $TRAIN_WSJ0/hmm5/hmmdefs -H $TRAIN_WSJ0/hmm5/macros -M $TRAIN_WSJ0/hmm5_text /dev/null $TRAIN_WSJ0/monophones1
$cmd = join (
	" ",
	"HHEd",
	"-H ".$hmm."/hmmdefs",
	"-H ".$hmm."/macros",
	"-M ".$hmmtxt,
	"nul",
	$MONOLIST1);
system $cmd;

#pause();

# HCompV parameters:
#  -C   Config file to load, gets us the TARGETKIND = MFCC_0_D_A_Z
#  -f   Create variance floor equal to value times global variance
#  -m   Update the means as well (not needed?)
#  -S   File listing all the feature vector files
#  -M   Where to store the output files
#  -I   MLF containg phone labels of feature vector files
$cmd = join (" ",
	"HCompV -A -T 1",
	"-C ".$CONFIG."/config",
	"-f 0.01 -m",
	"-S ".$TRAINSCP,
	"-M ".$hmmtxt,
	"-I ".$ALIGNED2,
	$LIB."/proto",
	">".$LOG."/hcompv.log");
system $cmd;
#HCompV -A -T 1 -C $TRAIN_COMMON/config -f 0.01 -m -S train.scp -M $TRAIN_WSJ0/hmm5_text -I $TRAIN_WSJ0/aligned2.mlf $TRAIN_TIMIT/proto >$TRAIN_WSJ0/hcompv.log
#cp $TRAIN_TIMIT/macros $TRAIN_WSJ0/hmm5_text/macros
cp ($DOC."/macros_plp",$hmmtxt."/macros")||die "unable to copy file $DOC/macros to". $hmmtxt."/macros: ".$!;
cat("\>\>",$hmmtxt."/macros", $hmmtxt."/vFloors");

#pause();

system $AUEXE."/train_iter.pl $HMM_ROOT hmm".$lasthmm."_text hmm".$newhmm." $MONOLIST1 $ALIGNED2 3";
my $beghmm = $newhmm;
my $tohmm  = $beghmm + 1;
for(0..2){
	system $AUEXE."/train_iter.pl $HMM_ROOT hmm$beghmm hmm$tohmm $MONOLIST1 $ALIGNED2 3";
	++$beghmm;
	++$tohmm;
}
--$beghmm;
--$tohmm;
system "echo ".$tohmm."\>".$HMM_ROOT."/train_mono_endhmm.log";
#system "train_iter.pl $HMM_ROOT hmm7 hmm8 $MONOLIST1 $ALIGNED2 3";

# Do an extra round just so we end up with hmm9 and synched with the tutorial
#$TRAIN_TIMIT/train_iter.sh $TRAIN_WSJ0 hmm8 hmm9 monophones1 aligned2.mlf 3
#system "train_iter.pl $HMM_ROOT hmm8 hmm9 $MONOLIST1 $ALIGNED2 3";

# end hmm9







