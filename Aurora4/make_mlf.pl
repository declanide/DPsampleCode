
require "common_config.pl";
# After we do prep.sh, we want to create a word level MLF for all 
# the files that were succefully converted to MFC files.
use File::Find 'find';
use File::Basename 'basename';
##cd $WSJ0_DIR
#goto MID;
# Cleanup old files
print "delete some unused files\n";
for ("mfc_files.txt","mfc_files_si84.txt","train_missing.txt","dot_files.txt"){
	my $fname = $LIB."/".$_;
	if (-e $fname){
		rename($fname,$RUNBAK."/".$_)||die "can not rename file $fname to $RUNBAK: ".$!;
	}
}
for ("prune.log","missing.log","hvite_align.log","hled_sp_sil.log"){
	my $fname = $LOG."/".$_;
	if (-e $fname){
		rename($fname,$RUNBAK."/".$_)||die "can not rename file $fname to $RUNBAK: ".$!;
	}
}

if (-e $TRAINLIST_FEA){
	my $trainname = basename $TRAINLIST_FEA;
	rename($TRAINLIST_FEA, $RUNBAK."/".$trainname)||die "can not rename file $TRAINLIST_FEA to $RUNBAK: ".$!;
}
if(-e $WORDS){
	my $name = basename $WORDS;
	rename($WORDS, $RUNBAK."/".$name)||die "can not rename file $WORDS to $RUNBAK: ".$!;
}

# Create a file listing all the MFC files in the training directory
#find -iname '*.mfc' | grep -i SI_TR_S >mfc_files.txt
#find_files($FEA_TRAIN_PATH,'.*\.fe',$LIB."/mfc_files.txt");
print "create all feature list\n";
open(SCP,">",$LIB."/mfc_files.txt")||die "unable to open file mfc_files.txt"." for writting: ".$!;
find(\&wanted1, $FEA_TRAIN_PATH);
close SCP;



# There appears to be more in the SI_TR_S directory than is in the
# index file for the SI-84 training set.  We'll limit to just the
# SI-84 set for comparison purposes.
print "create si84 training list\n";
my $cmd = $AUEXE."/PruneWithIndex.pl si_tr_s $LIB/mfc_files.txt $DOC/TR_S_WV1.NDX $LIB/mfc_files_si84.txt \>$LOG/prune.log";
system $cmd;

# Create a file that contains the filename of all the transcription files
#find -iname '*.dot' | grep -i SI_TR_S >dot_files.txt
#find_files($WSJ0, '.*SI_TR_S.*\.dot', $LIB."/dot_files.txt");
print "create dot files\n";
open(SCP,">",$LIB."/dot_files.txt")||die "unable to open file dot_files.txt"." for writting: ".$!;
find(\&wanted2, $WSJ0);
close SCP;

print "create mlf file\n";
# Now create the MLF file using a script, we prune out anything that
# has words that aren't in our dictionary, producing a MLF with only
# these files and a cooresponding script file.
$cmd  =join (
	" ",
	$AUEXE."/CreateWSJMLF_me.pl",
	$LIB."/mfc_files_si84.txt",
	$LIB."/dot_files.txt",
	$LIB."/cmu6",
	$WORDS,
	$TRAINLIST_FEA,
	"1 ".$LIB."/train_missing.txt",
	">".$LOG."/missing.log");
system $cmd;
	
	
my $cmd = join (
	" ",
	"HLEd -A -T 1 -l \*",
	"-d ".$LIB."/cmu6",
	"-i ".$PHONES0, 
	$DOC."/mkphones0.led",
	$WORDS,
	">".$LOG."/hhed_flat.log");
system $cmd;


$cmd = join (
	" ",
	"HLEd -A -T 1 -l \*",
	"-d ".$LIB."/cmu6sp",
	"-i ".$PHONES1, 
	$DOC."/mkphones1.led",
	$WORDS,
	">".$LOG."/hhed_flat.log");
system $cmd;


#perl $TRAIN_SCRIPTS/CreateWSJMLF.pl $WSJ0_DIR/mfc_files_si84.txt $WSJ0_DIR/dot_files.txt $TRAIN_TIMIT/cmu6 $TRAIN_WSJ0/words.mlf train.scp 1 $TRAIN_WSJ0/train_missing.txt >$TRAIN_WSJ0/missing.log

sub wanted1 {			
	my $found_file = $File::Find::name;		
	if ($found_file =~ /.*\.fe/gi){
		next if (index($found_file,"NIST-Speech-Disc-11-4.1-maybecopy")>=0);		
		print SCP $found_file."\n";	
					
	}
}


sub wanted2 {			
	my $found_file = $File::Find::name;		
	if ($found_file =~ /.*SI_TR_S.*\.dot/gi){
		next if (index($found_file,"NIST-Speech-Disc-11-4.1-maybecopy")>=0);
		print SCP $found_file."\n";
				
	}
}


#pause("in make_mlf.pl");








