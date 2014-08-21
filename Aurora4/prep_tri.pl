# Convert our monophone models and MLFs into triphones.  If a parameter
# "cross" is passed to script, we'll build cross word triphones, otherwise
# they will be word internal.
#
# Parameters:
#  1 - "cross" for cross word triphones, anything else means word internal
require ("common_config.pl");

use File::Path 'rmtree';
use File::Copy 'cp';

unless(@ARGV >= 1){	
	print $0.'wi_cro'."\n";
	exit(0);
}

my ($wi_cro, $if2wild) =@ARGV;
#cd $TRAIN_WSJ0

my $cmd;

#hmm9
my $lasthmm = lasthmm($HMM_ROOT."/train_mono_endhmm.log");
#pause($lasthmm);

#my $hmm9 = $HMM_ROOT."/hmm9";
#my $hmm10 = $HMM_ROOT."/hmm10";

my $beghmm = $lasthmm;
my $tohmm  = $beghmm + 1;


#rm -f -r hled_make_tri.log mktri.hed hhed_clone_mono.log hmm10
for("hled_make_tri.log","maktri.hed","hhed_clone_mono.log"){
	my $fname = $LOG."/".$_;
	if (-e $fname){
		rename($fname,$RUNBAK."/".$_)||die("can not rename $fname to ".$RUNBAK.": ".$!);
	}
}
#10
if(-e $HMM_ROOT."/hmm".$tohmm){
	movecopy_dir2("move",$HMM_ROOT."/hmm".$tohmm,$RUNBAK."/prep_tri");
    rmtree($HMM_ROOT."/hmm".$tohmm)||die "can not rmtree ".$HMM_ROOT."/hmm".$tohmm." ".$!;
}

create_fold($HMM_ROOT."/hmm".$tohmm,"tree", "prep_tri.pl");

# Keep a copy of the monophones around in this directory for convience.
cp($DOC."/monophones0",$MONOLIST0)||die "can not copy file $DOC/monophones0 to ".$MONOLIST0.": ".$!;
cp($DOC."/monophones1",$MONOLIST1)||die "can not copy file $DOC/monophones1 to ".$MONOLIST1.": ".$!;
# Check to see if we are doing cross word triphones or not
# if [[ $1 != "cross" ]]
# then
##This converts the monophone MLF into a word internal triphone MLF
# HLEd -A -T 1 -n triphones1 -i wintri.mlf mktri.led aligned2.mlf >hled_make_tri.log
# else
##This version makes it into a cross word triphone MLF, the short pause
##phone will not block context across words.
# HLEd -A -T 1 -n triphones1 -i wintri.mlf mktri_cross.led aligned2.mlf >hled_make_tri.log
# fi
unless ($wi_cro eq "cross") {
	$cmd = join (" ",
			"HLEd -A -T 1",
			"-n ".$TRILIST1,
			"-i ".$TRIWORDS,
			$DOC."/mktri.led",
			$ALIGNED2,
			">".$LOG."/hled_make_tri.log");
	system $cmd;
	#HLEd -A -T 1 -n triphones1 -i wintri.mlf mktri.led aligned2.mlf >hled_make_tri.log;
}else{
	$cmd = join (
		" ",
		"HLEd -A -T 1",
		"-n ".$TRILIST1,
		"-i ".$TRIWORDS,
		$DOC."/mktri_cross.led",
		$ALIGNED2,
		">".$LOB."/hled_make_tri.log");
	system $cmd;
# This version makes it into a cross word triphone MLF, the short pause
# phone will not block context across words.
#HLEd -A -T 1 -n triphones1 -i wintri.mlf mktri_cross.led aligned2.mlf >hled_make_tri.log
}

if($if2wild eq "wild"){
	mlf_path2wild($TRIWORDS,$TRIWORDS_WILD);
}

#pause("pre tri mid");

# Prepare the script that will be used to clone the monophones into
# their cooresponding triphones.  The script will also tie the transition
# matrices of all triphones with the same central phone together.
system $AUEXE."/MakeClonedMono.pl $MONOLIST1 $TRILIST1\>$LIB/mktri.hed";
#9--> 10
# Go go gadget clone monophones and tie transition matricies
$cmd = join (
	" ",
	"HHEd -A -T 1 -B",
	"-H ".$HMM_ROOT."/hmm".$beghmm."/macros",
	"-H ".$HMM_ROOT."/hmm".$beghmm."/hmmdefs",
	"-M ".$HMM_ROOT."/hmm".$tohmm,
	$LIB."/mktri.hed",
	$MONOLIST1,
	">".$LOG."/hhedCloneMono_".$tohmm.".log");
system $cmd;
#HHEd -A -T 1 -B -H hmm9/macros -H hmm9/hmmdefs -M hmm10 mktri.hed monophones1 >hhed_clone_mono.log

print"...finish the preparation of triphone generation\n";

system "echo ".$tohmm.">".$HMM_ROOT."/prep_tri_endhmm.log";

