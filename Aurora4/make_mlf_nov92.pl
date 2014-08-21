# Make the Nov92 test MLF
#
# After we do prep.sh, we want to create a word level MLF for all 
# the files that were succefully converted to MFC files.
require "common_config.pl";
use File::Find 'find';
use File::Basename;
#cd $WSJ0_DIR

# Cleanup old files
my $filesline = 'nov92_mfc_files.txt nov92_dot_files.txt nov92_prune.log nov92_mfc_files_pruned.txt nov92_missing.log nov92_missing.txt';
my @linefiles = split /\s+/,$filesline;

foreach my $file(@linefiles){

	my $fname;
	if ($file =~ /.*\.log$/gi)
	{
		$fname = $LOG."/".$file;
		if(-e $fname){
			rename($fname,$RUNBAK."/".$file)||die "can not rename $fname to $RUNBAK";
		}
	}
	else 
	{
		$fname = $LIB."/".$file;
		if(-e $fname){
			rename($fname,$RUNBAK."/".$file)||die "can not rename $fname to $RUNBAK";
		}
	}
}
if(-e $TESTWORDS1){
	my $name = basename $TESTWORDS1;
	rename($TESTWORDS1, $RUNBAK."/".$name)||die "can not rename file ".$TESTWORDS1." to ".$RUNBAK.": ".$!;
}
if(-e $TESTWORDS2){
	my $name = basename $TESTWORDS2;
	rename($TESTWORDS2, $RUNBAK."/".$name)||die "can not rename file ".$TESTWORDS2." to ".$RUNBAK.": ".$!;
}

if (-e $TESTSCP){
	my $name = basename $TESTSCP;
	rename($TESTSCP, $RUNBAK."/".$name)||die "can not rename file ".$TESTSCP." to ".$RUNBAK.": ".$!;
}

# Create a file listing all the MFC files in the training directory
#find -iname '*.mfc' | grep -i SI_ET_05 >nov92_mfc_files.txt
#find_files($FEA_TEST_PATH, '.*\.fe', $LIB/nov92_mfc_files.txt);
print "create all test feature list\n";
open(SCP,">",$LIB."/nov92_mfc_files.txt")||die "unable to open file nov92_mfc_files.txt"." for writting: ".$!;
find(\&wanted1, $FEA_TEST_PATH);
close SCP;
# Create a file that contains the filename of all the transcription files
#find -iname '*.dot' | grep -i SI_ET_05 >nov92_dot_files.txt
#system "find.pl $WSJ0 ".'.*SI_ET_05.*\.dot'." \>$LIB/nov92_dot_files.txt";
open(SCP,">",$LIB."/nov92_dot_files.txt")||die "unable to open file nov92_dot_files.txt"." for writting: ".$!;
find(\&wanted2, $WSJ0);
close SCP;
# Make sure we only include files in the index file for this set
my $cmd =join (
	" ",
	$AUEXE."/PruneWithIndex.pl",
	"si_et_05",
	$LIB."/nov92_mfc_files.txt",
	$DOC."/SI_ET_05.NDX",
	$LIB."/nov92_mfc_files_pruned\.txt",
	">".$LOG."/nov92_prune\.log");
system $cmd;
	
#perl $TRAIN_SCRIPTS/PruneWithIndex.pl si_et_05 nov92_mfc_files.txt $WSJ0_DIR/WSJ0/DOC/INDICES/TEST/NVP/SI_ET_05.NDX nov92_mfc_files_pruned.txt >$TRAIN_WSJ0/nov92_prune.log

# Now create the MLF file using a script, we prune out anything that
# has words that aren't in our dictionary, producing a MLF with only
# these files and a cooresponding script file.
$cmd = join (
	" ",
	$AUEXE."/CreateWSJMLF_me.pl",
	$LIB."/nov92_mfc_files_pruned\.txt",
	$LIB."/nov92_dot_files\.txt",
	$LIB."/cmu6",
	$TESTWORDS1,
	$TESTSCP,
	$LIB."/nov92_misssing.txt",
	">".$LOG."/nov92_missing\.log");
system $cmd;


open(IN,"<".$TESTWORDS1)||die "can not open file ".$TESTWORDS1." for reading: ".$!;
open(OUT,">".$TESTWORDS2)||die "can not open file ".$TESTWORDS2." for writting: ".$!;
while(<IN>){
	chomp;
	if (/\".+\/(.+\.lab)\"/){
		my $id = $1;
		print OUT "\"\*\/$id\"\n";		
	}else{
		print OUT $_."\n";
	}
}
close IN;
close OUT;


system "hled -A -T 1 -l * -i ".$TESTWORDS3." nul ".$TESTWORDS1.">".$LOG."/hled_testwords2.log";

#perl $TRAIN_SCRIPTS/CreateWSJMLF.pl $WSJ0_DIR/nov92_mfc_files_pruned.txt $WSJ0_DIR/nov92_dot_files.txt $TRAIN_TIMIT/cmu6 $TRAIN_WSJ0/nov92_words.mlf $WSJ0_DIR/nov92_test.scp $TRAIN_WSJ0/nov92_missing.txt >$TRAIN_WSJ0/nov92_missing.log

sub wanted1 {
	my $found_file = $File::Find::name;		
	if ($found_file =~ /.*\.fe/gi){	
		next if (index($found_file,"NIST-Speech-Disc-11-4.1-maybecopy")>=0);	
		print SCP $found_file."\n";			
	}
}

sub wanted2 {
	my $found_file = $File::Find::name;		
	if ($found_file =~ /.*SI_ET_05.*\.dot/gi){	
		next if (index($found_file,"NIST-Speech-Disc-11-4.1-maybecopy")>=0);
		print SCP $found_file."\n";			
	}
}









