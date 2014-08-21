# This encodes the Nov 1992 ARPA WSJ evaluation,
# 330 sentences from 8 speakers.

# Create a file with the filename with wc1, wav and mfc extensions on it
# Only get the files in the training directory.
#find -iname '*.wv1' | grep -i SI_ET_05 >nov92_wv1_files.txt
# my ($outpath)= @ARGV;
# if (@ARGV != 1){
	# die "prep_nov92.pl usage: outpath: ".$!;
# }

require "common_config.pl";

my $cmd = join(
	" ",
	$AUEXE."/wsj0_prep.pl",
	"dev",
	'SI_DT_05',
	$FEA_DEV_PATH,
	$DEV_SPH2WAV_LOG,
	$NEWWSJ0,
	$WSJ0);

system $cmd;

# print  "begin create training scp file...\n";
# find_files($WSJ0,'.*WSJ0\\SI_ET_05\\.*\.WV1',$LIB."/nov92_wv1_files0.txt");

# system "sphconvert.pl $LIB/nov92_wv1_files0.txt $NEWWSJ0 ".$TEST_SPH2WAV_LOG;

# find_files($NEWWSJ0,'.*WSJ0\/SI_ET_05\/.*\.WV1',$LIB."/nov92_wv1_files.txt");

# system "CreateMFCList.pl"." "."$LIB/nov92_wv1_files.txt"." "."WV1"." "."fe"." ".$FEA_TEST_PATH."\>$LIB/nov92_wv1_mfc.scp";


# $cmd = "HCopy -T 1 -C $CONFIG/configwav -C $CONFIGVAX/config -C $CONFIGVAX/config_wsj -S $LIB/nov92_wv1_mfc.scp >$LOG/hcopy_nov92.log";
# system $cmd;

