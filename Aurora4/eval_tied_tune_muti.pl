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
use File::Path 'rmtree';
use File::Basename;
use POSIX qw(:sys_wait_h);

my ($addstr, $r, $t, $hmm,$p,$s,$prune,$wi_cro,$scp, $outlat)=@ARGV; 
if (@ARGV != 10){
	print $0.' usage: $mainfold,$r, $t, $hmm,$p,$s,$prune,$wi_cro,$outlat'."\n";
	exit(0);
}
#hmm42 _ro200_tb750_prune250_flat_cross 250.0 -4.0 15.0 cross
#cd $WSJ0_DIR
my $outfold  = $TUNE_RECOUT."/".$addstr;
my $tunefold = $TUNE_WORK."/".$addstr;
my $bak       = $TUNE_BAK."/recout/".$addstr;
my $ro_tb   = "ro".$r."tb".$t;
$outfold    = $outfold."/".$ro_tb;
$tunefold     = $tunefold."/".$ro_tb;
$bak 		  = $bak."/".$ro_tb;


if ($outlat eq "lat"){	
	$outfold = $outfold."/withlat";
	$tunefold= $tunefold."/withlat";
	$bak     = $bak."/withlat";
}elsif($outlat eq "nolat"){
	$outfold = $outfold."/nolat";
	$tunefold = $tunefold."/nolat";
	$bak     = $bak."/nolat";
}else{
	die "the eval_tied_tune_muti should have the input parameter \$outlat be selected in [lat|nolat]";
}


my $hmm15     = $tunefold."/hmm15";
my $flist	  = $tunefold."/fulllist";
my $tlist	  = $tunefold."/tiedlist";
my $latout  = $TUNE_LAT."/".$addstr;
my $latout  = $latout."/".$ro_tb;


unless(-e $bak){
	mkpath($bak)||die "can not mkpath $bak: ".$!;
}

#goto DEBUG;

if(-e $outfold."/recout_dev92".$addstr."_tempall\.mlf"){
	unlink($outfold."/recout_dev92".$addstr."_tempall\.mlf")||die "can not unlink file ".$outfold."/recout_dev92".$addstr."_tempall\.mlf: ".$!;
}

# begin delet and mkdir;
if(-e $outfold){
	movecopy_dir2("move",$outfold,$bak);	
}
if (-e $outfold){
	(my $fold = $outfold) =~ s/\//\\/gi;	
	system ("RMDIR /Q /S ".$fold);
	
	#pause("RMDIR /Q /S ".$fold);
	#rmdir($outfold)||die "can not rmdir $outfold: ".$!;		
}
unless(-e $outfold){
	mkpath($outfold,{mode => 0777})||die "can not mkpath $outfold: ".$!;
}

if ($outlat eq "lat"){
	unless(-e $latout){
		mkpath($latout,{mode=>0777})||die "can not mkpath folder ".$latout.": ".$!;
	}
}



# HVite parameters:
#  -H    HMM macro definition files to load
#  -S    List of feature vector files to recognize
#  -i    Where to output the recognition MLF file
#  -w    Word network to you as language model
#  -p    Insertion penalty
#  -s    Language model scale factor
#  -z    Extension for lattice output files
#  -n    Number of tokens in a state (bigger number means bigger lattices)

# We'll run with some reasonable values for insertion penalty and LM scale,
# but these will need to be tuned.

# We need to send in a different config file depending on whether
# we are doing cross word triphones or not.
# if [[ $6 != "cross" ]]
# then
# HVite -A -T 1 -t $3 -C $TRAIN_COMMON/configwi -H $TRAIN_WSJ0/$1/macros -H $TRAIN_WSJ0/$1/hmmdefs -S $WSJ0_DIR/nov92_test.scp -i $TRAIN_WSJ0/recout_nov92$2.mlf -w $TRAIN_WSJ0/wdnet_bigram -p $4 -s $5 -z lat -n 4 $TRAIN_WSJ0/dict_5k $TRAIN_WSJ0/tiedlist >$TRAIN_WSJ0/hvite_nov92$2.log
# else
# HVite -A -T 1 -t $3 -C $TRAIN_COMMON/configcross -H $TRAIN_WSJ0/$1/macros -H $TRAIN_WSJ0/$1/hmmdefs -S $WSJ0_DIR/nov92_test.scp -i $TRAIN_WSJ0/recout_nov92$2.mlf -w $TRAIN_WSJ0/wdnet_bigram -p $4 -s $5 -z lat -n 4 $TRAIN_WSJ0/dict_5k $TRAIN_WSJ0/tiedlist >$TRAIN_WSJ0/hvite_nov92$2.log
# fi

my $configrec ="";
unless ($wi_cro eq "cross"){
	$configrec = $CONFIG."/configwi";	
}else{
	$configrec = $CONFIG."/configcross";	
}
my $latop = "";
if($outlat eq "lat"){
	$latop = "-z lat -l $latout -n 4";
}elsif($outlat eq "nolat"){
	$latop ="";
}else{
	die "the eval_tied_tune_muti should have the input parameter \$outlat be selected in [lat|nolat]";
}




for (my $I=1,my $J=0;$I<=$HVITE_SPLIT;){
	my @procs;

    for (my $T=0;$T<$HVITE_THREADS&$I<=$HVITE_SPLIT;$T++,$I++,$J++){
	
		system $AUEXE."/OutputEvery.pl $scp $HVITE_SPLIT $J > $outfold/eval_temp_split_$T.scp"; 		
		defined($procs[$T] = fork()) or die "can not fork $!";
		#pause($proc);
		
        unless($procs[$T]) {			
			print "exec HVite process:$T data chunk:$I \n";	
			my $cmd = join (
				" ",
				"HVite -A -T 1 -t ".$prune,
				"-C ".$configrec,
				"-H $tunefold/$hmm/macros -H $tunefold/$hmm/hmmdefs",
				"-S ".$outfold."/eval_temp_split_".$T.".scp",
				"-i ".$outfold."/recout_dev92".$addstr."_".$T."\.mlf",
				"-w ".$WDNETCVP,
				"-p ".$p." -s ".$s,
				$latop,
				$LIB."/dict5k_cvp",
				$tlist,
				">".$outfold."/hvite_dev92".$addstr."_".$T.".log");
			
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
		cat("\>\>", $outfold."/hvite_dev92".$addstr.".log", $outfold."/hvite_dev92".$addstr."_".$_.".log");
		cat("\>\>", $outfold."/recout_dev92".$addstr."_tempall\.mlf", $outfold."/recout_dev92".$addstr."_".$_."\.mlf");	
	}	
	
}


for(<$outfold/*.mlf $outfold/*.log>){
	
	if (/.*\/(hvite|recout)\_dev92$addstr\_\d+\.(mlf|log)/g){
		#pause($addstr."\n".$_);
		if(-e $_){
			unlink($_)||die "can not unlink file ".$_.": ".$!;
		}
	}
}

for(<$outfold/*.scp>){
	if($_ =~ /.*\/eval_temp_split_\d+.scp/g){
		if(-e $_){
			unlink($_)||die "can not unlink file ".$_.": ".$!;
		}
	}
}

DEBUG:
my $tempoutallmlf = $outfold."/recout_dev92".$addstr."_tempall\.mlf";
my $outallmlf        = $outfold."/recout_dev92".$addstr."\.mlf";

#goto DEBUG2;
open (ALL,"<".$tempoutallmlf)||die "can not open file".$tempoutallmlf." for reading: ".$!;
open (MLF,">".$outallmlf)||die "can not open file".$outallmlf." for writting: ".$!;

my $allmlfstr = join '',<ALL>;
$allmlfstr =~ s/\n\#\!MLF\!\#\n/\n/gi;
print MLF $allmlfstr;
close ALL;
close MLF;


DEBUG2:
#pause($outallmlf);

# Now lets see how we did!  
#cd $TRAIN_WSJ0
# $tempwords     = $LIB."/temp_nov92_words.mlf";
# system "hled -A -T 1 -l * -i ".$tempwords." nul ".$TESTWORDS.">".$LOG."/hled_testwords2.log";
system "HResults -n -A -T 1 -L \* -I ".$DEVWORDS3." ".$tlist." ".$outallmlf."\>".$outfold."/hresults_dev92".$addstr.".log";
#pause();
#pause("HResults -n -A -T 1 -L \* -I $tempwords $TIEDLIST ".$outfold."/recout_nov92".$addstr."\.mlf\>".$outfold."/hresults_nov92".$addstr.".log");

# Add on a NIST style output result for good measure
system "HResults -n -h -A -T 1 -L \* -I ".$DEVWORDS3." ".$tlist." ".$outallmlf."\>\>".$outfold."/hresults_dev92".$addstr.".log";
#pause();
#system $cmd;

movecopy_dir2("copy",$outfold,$bak);


print "...eval_dev92 finished\n";


