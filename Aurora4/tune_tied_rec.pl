# Do a search for good parameters for insertion penalty and 
# LM scale factor.  
#
# The template_eval_nov92 script assumes that recognition has 
# already been done on the Nov92 test set and the results stored 
# in lattice form.  
#
# The file insertion_scale should contain the combinations of
# penalities and scale factors to try.
#
# Output:
#   hvite_nov92_tune.log   The complete HResults output for each combo
#   nov92_tune.log         List of value combos and the resulting accuracy
#
# Parameters:
#  1 - "cross" if we are tuning crossword triphone models

#cd $WSJ0_DIR

# This does a search for which insertion and scale factor to use
# if [[ $1 != "cross" ]]
# then
# perl $TRAIN_SCRIPTS/ProcessNums.pl $TRAIN_WSJ0/insertion_scale $TRAIN_WSJ0/template_tune_nov92
# else
# perl $TRAIN_SCRIPTS/ProcessNums.pl $TRAIN_WSJ0/insertion_scale $TRAIN_WSJ0/template_tune_nov92_cross

require ("common_config.pl");

use File::Copy 'cp';
use File::Copy 'mv';
use File::Path 'rmtree';
use File::Path 'mkpath';
use POSIX qw(:sys_wait_h);

if (@ARGV < 8){
	print $0."usage: ".'$recfold, $hmmfold,$wi_cro, $r, $t, $scp, [$recbak], [$outlat], [$endhmmfile],[$latfold], [$wordlist_type], [$lm_p], [$lm_s]'."\n";
	exit 0;
}

my($recfold, $hmmfold, $wi_cro, $r, $t, $scp, $bak, $outlat, $endhmmfile, $latfold,$wordlist_type, $lm_p, $lm_s)=@ARGV;

my $recdict;
if ($wordlist_type eq "cvp"){
	$recdict = $DICTCVP;
}elsif($wordlist_type eq "cnvp"){
	$recdict = $DICT;
}

my $ro_tb   = "ro".$r."tb".$t;
my $latin = $DEVLAT_FIRST_FOLD1;
if ($latfold){
	$latin = $latfold;
}
#my $latin    = $TUNE_LAT."/".$addstr."/".$first_rotb;
# $latin 这个文件夹绝对不能有删除动作。

print "go i am here\n";

#my $recfold = $TUNE_RECOUT."/".$addstr."_tune_tied";
#my $bak       = $TUNE_BAK."/recout/".$addstr."/tune_mutirotb";

if($outlat eq "lat"){
	$hmmfold = $hmmfold."/withlat";
	$recfold = $recfold."/withlat";
	$bak 	 = $bak."/withlat";
}elsif($outlat eq "nolat"){
	$hmmfold = $hmmfold."/nolat"; 
	$recfold = $recfold."/nolat";
	$bak 	 = $bak."/nolat";
}elsif($outlat eq ""){
     $hmmfold = $hmmfold."/nolat"; 
	 $recfold = $recfold."/nolat";
	 $bak 	  = $bak."/nolat";
}

my $endfile = $hmmfold."/".$endhmmfile;
my $finalhmmid = lasthmm($endfile);
#pause($finalhmmid." ".$recfold." ".$bak);

my $recmlf   = $recfold."/recout".$ro_tb.$finalhmmid."\.mlf";
my $result   = $recfold."/hresult".$ro_tb.$finalhmmid."\.log";
my $hvitelog = $recfold."/hvite_dev92_tune\_".$ro_tb.$finalhmmid.".log";
my $devlog   = $recfold."/dev92_tune\_".$ro_tb.$finalhmmid.".log";


#my $hmmfold  = $TUNE_WORK."/".$addstr."/".$ro_tb;


my $endhmm    = $hmmfold."/hmm".$finalhmmid;

my $flist	  = $hmmfold."/fulllist";
my $tlist	  = $hmmfold."/tiedlist";
#goto RESULT;
unless(-e $bak){
	mkpath($bak)||die "can not mkpath $bak $!";
}

unless(-e $recfold){
	mkpath($recfold,{mode => 0777})||die "can not rmtree ".$recfold;	
}


if(-e $result){
	mv($result, $bak)||die "can not move $result to $bak";
}


for($recmlf, $hvitelog, $devlog){
	if (-e $_){
		unlink($_)||die "can not unlink $_: $!";
	}
}

DEBUG:

#begin
print "begin RO$r TB$t tune...\n";


my $p_s_setting = "-p ".$LATP." -s ".$LATS;
if ($lm_s){
	$p_s_setting = "-p ".$lm_p." -s ".$lm_s;		
}


my $cmd = "HVite -A -T 1 -t 250.0 -C ".$CONFIG."/configcross -H ".$endhmm."/macros -H ".$endhmm."/hmmdefs -S ".$scp." -i ".$recmlf." -X lat -L ".$latin." -w ".$p_s_setting." ".$recdict." ".$tlist.">".$hvitelog;
#print $cmd."\n";
system $cmd;
#pause();

RESULT:
system "echo Crossword, RO: $r".">".$result;
system "echo Crossword, TB: $t"."\>\>".$result;

system "HResults -A -T 1 -n -I ".$DEVWORDS3." ".$tlist." ".$recmlf."\>\>".$result;

system "echo Crossword  $r	$t"."\>".$devlog;
system $AUEXE."/search.pl $result WORD -1"."\>\>".$devlog;

system "HResults -A -T 1 -n -h -I ".$DEVWORDS3." ".$tlist." ".$recmlf.">>".$result;

print "...finish RO$r TB$t  tune rec\n";

#pause();








