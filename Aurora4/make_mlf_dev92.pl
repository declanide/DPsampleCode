# Make the Nov92 test MLF
#
# After we do prep.sh, we want to create a word level MLF for all 
# the files that were succefully converted to MFC files.
require "common_config.pl";
use File::Find 'find';
use File::Basename;
#cd $WSJ0_DIR

# Cleanup old files
my $filesline = 'dev92_mfc_files.txt dev92_dot_files.txt dev92_prune.log dev92_mfc_files_pruned.txt dev92_missing.log dev92_missing.txt';
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
if(-e $DEVWORDS1){
	my $name = basename $DEVWORDS1;
	rename($DEVWORDS1, $RUNBAK."/".$name)||die "can not rename file ".$DEVWORDS1." to ".$RUNBAK.": ".$!;
}
if(-e $DEVWORDS2){
	my $name = basename $DEVWORDS2;
	rename($DEVWORDS2, $RUNBAK."/".$name)||die "can not rename file ".$DEVWORDS2." to ".$RUNBAK.": ".$!;
}

if (-e $DEVSCP){
	my $name = basename $DEVSCP;
	rename($DEVSCP, $RUNBAK."/".$name)||die "can not rename file ".$DEVSCP." to ".$RUNBAK.": ".$!;
}

# Create a file listing all the MFC files in the training directory
#find -iname '*.mfc' | grep -i SI_ET_05 >nov92_mfc_files.txt
#find_files($FEA_TEST_PATH, '.*\.fe', $LIB/nov92_mfc_files.txt);
print "create all dev feature list\n";
open(SCP,">",$LIB."/dev92_mfc_files.txt")||die "unable to open file dev92_mfc_files.txt"." for writting: ".$!;
find(\&wanted1, $FEA_DEV_PATH);
close SCP;



# Create a file that contains the filename of all the transcription files
#find -iname '*.dot' | grep -i SI_ET_05 >nov92_dot_files.txt
#system "find.pl $WSJ0 ".'.*SI_ET_05.*\.dot'." \>$LIB/nov92_dot_files.txt";
open(SCP,">",$LIB."/dev92_dot_files.txt")||die "unable to open file dev92_dot_files.txt"." for writting: ".$!;
find(\&wanted2, $WSJ0);
close SCP;


open(D3,"<".$DOC."/devtest_0330.text")||die "can not open file ".$DOC."/devtest_0330.txt for reading: ".$!;
open(LIB_D3,">".$LIB."/devtest_0330.txt")||die "can not open file ".$LIB."/devtest_0330.txt for writting: ".$!;
while(<D3>){
	chomp;
	my @d3 = split /\s+/;
	print LIB_D3 "SI_DT_05/";
	print LIB_D3 $d3[0];
	print LIB_D3 "\n";
}
close D3;
close LIB_D3;


# Make sure we only include files in the index file for this set
my $cmd =join (
	" ",
	$AUEXE."/PruneWithIndex.pl",
	"si_dt_05",
	$LIB."/dev92_mfc_files.txt",
	$LIB."/devtest_0330.txt",
	$LIB."/dev92_mfc_files_pruned\.txt",
	">".$LOG."/dev92_prune\.log");
system $cmd;

# 普通的devwords1, mlf中的每个lab带有相应fea文件的完整路径
$cmd = join (
	" ",
	$AUEXE."/CreateWSJMLF_me.pl",
	$LIB."/dev92_mfc_files_pruned\.txt",
	$LIB."/dev92_dot_files\.txt",
	$LIB."/cmu6",
	$DEVWORDS1,
	$DEVSCP,
	$LIB."/dev92_misssing.txt",
	">".$LOG."/dev92_missing\.log");
system $cmd;

my ($id, $es_count, $allcount, @eswords);
open(IN,"<".$DEVWORDS1)||die "can not open file ".$DEVWORDS1." for reading: ".$!;
open(OUT,">".$DEVWORDS2)||die "can not open file ".$DEVWORDS2." for writting: ".$!;
open(OUT4,">".$DEVWORDS4)||die "can not open file ".$DEVWORDS4." for writting: ".$!;
while(<IN>){
	chomp;
	if (/\".+\/(.+\.lab)\"/){
		$id = $1;
		print OUT "\"\*\/$id\"\n";
		print OUT4 "\"\*\/$id\"\n";
	}else{
		print OUT $_."\n";
		++$allcount;
		if(/\\.+/){
			push @eswords, $id."\t".$_;			
			++$es_count;
			print OUT4 "\'\<UNK\>\'\n";
		}else{
			print OUT4 $_."\n";
		}
	}
}
close IN;
close OUT;
close OUT4;

open(LOG, ">".$LOG."/devmlf_escape.log")||die "can not open file ".$LOG."/mkmlfdev92.log for writting: ".$!;
print LOG "all words: $allcount\tescape words: $es_count\n";
foreach(@eswords){
	print LOG $_."\n";
}
close LOG;

#用 hled去掉 fea的完整路径
system "hled -A -T 1 -l * -i ".$DEVWORDS3." nul ".$DEVWORDS1.">".$LOG."/hled_devwords2.log";

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
	if ($found_file =~ /.*SI_DT_05.*\.dot/gi){	
		next if (index($found_file,"NIST-Speech-Disc-11-4.1-maybecopy")>=0);
		print SCP $found_file."\n";			
	}
}









