
#cd $WSJ0_DIR

# The WSJ0 data is stored compressed using shorten method.  Using w_decode
# or shorten as the filter to HTK didn't work, but sph2pipe does work but
# if we leave it in sphere format the header is wrong and lists it as 
# still being shortened.  So we'll have sph2pipe convert to WAVE 16-bit
# linear PCM for HCopy to work with.

# Clean up any old files
#rm -f wv1_files.txt wv1_mfc.scp $TRAIN_WSJ0/hcopy.log

# Create a file with the filename with wc1, wav and mfc extensions on it
# Only get the files in the training directory.
#require "subroutine.pl";

require "common_config.pl";

my $cmd = join(
	" ",
	$AUEXE."/wsj0_prep.pl",
	"train",
	'SI_TR_S',
	$FEA_TRAIN_PATH,
	$TRAIN_SPH2WAV_LOG,
	$NEWWSJ0,
	$WSJ0);

system $cmd;
	
# my ($outpath) = @ARGV;
# if (@ARGV != 1){
	# print "prep usage: outpath\n";
	# exit(0);
# }
#goto ENDLAB;
#my $cmd = "find.pl ".$WSJ0." .*WSJ0\\SI_TR_S\\.*\.WV1 \>".$LIB."/wv1_files.txt";
#system $cmd;
#goto MID;
# print  "begin create training scp file...\n";
# find_files($WSJ0,'.*WSJ0\/SI_TR_S\/.*\.WV1',$LIB."/wv1_files0.txt");

##MID:
# system "sphconvert.pl $LIB/wv1_files0.txt $NEWWSJ0 ".$TRAIN_SPH2WAV_LOG;

# pause("sphconvert");

# find_files($NEWWSJ0,'.*WSJ0\/SI_TR_S\/.*\.WV1',$LIB."/wv1_files.txt");

##ENDLAB:
##Create the list file we need to send to HCopy to convert .wv1 files to .mfc
# system "CreateMFCList.pl"." "."$LIB/wv1_files.txt"." "."WV1"." "."fe"." ".$FEA_TRAIN_PATH."\>$LIB/wv1_mfc.scp";
##pause("mfclist");


# print "begin coding speech data...\n";
# system "HCopy -A -T 1 -C $CONFIG/configwav -C $CONFIG/config -C $CONFIG/config_wsj -C $CONFIG/configbyteorder -S $LIB/wv1_mfc.scp >$LOG/hcopy.log";
# pause("hcopy");

