# from go_flat_cross_2.pl

require ("common_config.pl");

my $TYPE = 2;
$addstr1 	= "_ro".$LATRO."_TB".$LATTB."_prune".$PRUNE1."_flat_cross";
$addstr2 	= "_ro".$LATRO."_TB".$LATTB."_prune".$PRUNE2."_flat_cross";
#$addstr2 = "_ro".$LATRO."_TB".$LATTB."_prune".$PRUNE2."_flat_cross";
goto MID;

#goto train_snow2;

create_folders();


wtime("all begin and speech data will be processed",">");

# We need to massage the CMU dictionary for our use
print "Preparing CMU dictionary...\n";
system $AUEXE."/prep_cmu_dict.pl";


# Code the audio files to MFCC feature vectors
print "Coding audio (train)...\n";
system $AUEXE."/prep.pl";

#MID1:
print "Coding Nov92 audio (test)...\n";
system $AUEXE."/prep_nov92.pl";

print "Coding audio (dev)...\n";
system $AUEXE."/prep_dev92.pl";
#pause("dev prep");
print "data process finished\n";


wtime("language source begin");


# Intial setup of language model, dictionary, training and test MLFs
print "Building language models and dictionary...\n";
system $AUEXE."/build_lm.pl";


print "Building training MLF...\n";
system $AUEXE."/make_mlf.pl";


print "Building test MLF...";
system $AUEXE."/make_mlf_nov92.pl";


print "Building dev MLF...";
system $AUEXE."/make_mlf_dev92.pl";

#pause("language source finished");

#======================================================================================================
# train
train_snow:

wtime("train mono");


# Get the basic monophone models trained
print "Flat starting monophones...\n";
system $AUEXE."/flat_start.pl $HMM_ROOT $TYPE";


# Create a new MLF that is aligned based on our monophone model
print "Aligning with monophones...\n";
system($AUEXE."/align_mlf.pl flat $HMM_ROOT");

#pause();
# More training for the monophones, create triphones, train
# triphones, tie the triphones, train tied triphones, then
# mixup the number of Gaussians per state.



print "Training monophones...";
#$TRAIN_WSJ0/train_mono.sh flat
system ($AUEXE."/train_mono.pl flat");

#pause("train_mono");
wtime("tri, tied - first training");



print "Prepping triphones...";
system $AUEXE."/prep_tri.pl cross";


print "Training triphones...";
system $AUEXE."/train_tri.pl $TYPE";


prep_train_mixup($LATRO, $LATTB, $TYPE);

#pause("first training process");
print "first training process...\n";

wtime("lattice and tune tied");
# Evaluate how we did, also produces lattics we use for tuning
print "Evaluating on Dev92 test set...\n";


my $rechmm = lasthmm($HMM_ROOT."/train_mixup_endhmm.log");
$rechmm    = "hmm".$rechmm;
system $AUEXE."/eval92_muti.pl ".$rechmm." ".$addstr1." ".$PRUNE1." ".$LATP." ".$LATS." cross ".$DEVSCP." cvp lat ".$DEVLAT_FIRST_FOLD1." ".$DEVWORDS3." dellat";
#pause("first eval92_muti withlat");
train_snow2:

print "Tuning tied topdown thresholds...\n";
system $AUEXE."/tune_tied.pl ".$PRUNE1." cross ".$TYPE." ".$DEVLAT_FIRST_FOLD1." cvp";
pause("tune tied");

MID:
my ($bestRO,$bestTB)=bestpara($TUNE_LOG);
#pause($bestRO." ".$bestTB);
(my $devaddstr1 = $addstr1) =~ s/^(_ro)$LATRO(.*TB)$LATTB(.*prune.*)/$1$bestRO$2$bestTB$3/gi;
$devaddstr1 = "dev".$devaddstr1;

goto MID2;

# Tune the insertion penalty and language model scale factor
#pause($bestRO." ".$bestTB." ".$devaddstr1);
wtime("tune insertion and penalty");
prep_train_mixup($bestRO,$bestTB, $TYPE);

MID2:

#pause("second prep train mixup");
print "second prep train mixup\n";

wtime("tune muti");
print "Tuning insertion penalty and scale factor...\n";
# tune_muti 默认是 rough 而不是 precise
goto ddp1;
system $AUEXE."/tune_muti.pl cross ".$devaddstr1." dev rough ".$DEVLAT_FIRST_FOLD1." cvp";

# pause("tune muti");
print "tune muti\n";

ddp1:

my ($bestP,$bestS)=bestpara($TUNE_BESTPS_LOG);
#pause("tune muti rec".$bestP." ".$bestS);
print "tune muti rec\n";

wtime("final recognition");
# You can probably now increase results slightly by running
# the best penalty and scale factor with a higher beam width,
# say 350.0.  Then relax and have a beer- you've earned it.
#pause("use muti or old single");
print "use muti or old single\n";

print "Evaluating on Nov92 test set without LAT ...\n";
(my $novaddstr2 = $addstr2) =~ s/^(_ro)$LATRO(.*TB)$LATTB(.*prune.*)/$1$bestRO$2$bestTB$3/gi;
$novaddstr2 = "nov".$novaddstr2;
my $rechmm = lasthmm($HMM_ROOT."/train_mixup_endhmm.log");
$rechmm    = "hmm".$rechmm;

print $rechmm." ".$bestP." ".$bestS;

system $AUEXE."/dp_eval92_muti.pl ".$rechmm." ".$novaddstr2." ".$PRUNE2." ".$bestP." ".$bestS." cross ".$TESTSCP." cnvp";

wtime("all finished");

pause("final eval92_muti nolat");

#REPORT:
#system "eval92_muti.pl hmm42 renewalreport_ro200tb750prune350flat_cross ".$prune2." -10.0 14.7 cross ".$TESTSCP." nolat";
#pause("这个识别是为了report的，请注释掉它");

#============================================================================================================================


sub create_folders {
	use File::Path 'mkpath';
	create_fold($LIB,"tree","create_folders in go_flat_cross.pl");
	create_fold($LOG,"tree","create_folders in go_flat_cross.pl");
	create_fold($RECOUT_FOLD,"tree","create_folders in go_flat_cross.pl");
	create_fold($NEWWSJ0,"tree","create_folders in go_flat_cross.pl");	
	create_fold($FEA_TRAIN_PATH,"tree","create_folders in go_flat_cross.pl");
	create_fold($FEA_TEST_PATH,"tree","create_folders in go_flat_cross.pl");
	create_fold($FEA_DEV_PATH,"tree","create_folders in go_flat_cross.pl");
	create_fold($LATFOLD,"tree","create_folders in go_flat_cross.pl");
	if(-e $RUNBAK){
	 rmtree($RUNBAK)||die("can not rmtree $RUNBAK: ".$!);
	}
	create_fold($RUNBAK,"tree","create_folders in go_flat_cross.pl");
}

sub prep_train_mixup {
	my ($ro, $tb, $type) = @_;
	

	print "Prepping state-tied triphones...\n";
	system $AUEXE."/prep_tied.pl ".$ro." ".$tb." cross";

	#pause("prep_tied");
	print "Training state-tied triphones...\n";
	system $AUEXE."/train_tied.pl";
	
	
	#pause("mix up");
	print "Mixing up...\n";
	
	system $AUEXE."/train_mixup.pl $type";
}








