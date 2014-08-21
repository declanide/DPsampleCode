
# Prepare things for the tied state triphones
#
# Parameters:
#   1 - RO value for clustering
#   2 - TB value for clustering
#   3 - "cross" if we are doing cross word triphones
#
# We need to create a list of all the triphone contexts we might

# see based on the whole dictionary (not just what we see in 
# the training data).
require ("common_config.pl");

use File::Path 'rmtree';
use File::Copy 'cp';
use File::Basename;
#cd $TRAIN_WSJ0



if (@ARGV < 4){
	print $0.'usage: $tunefold $r $t $wi_cro $iflat $allhhedlog'."\n";
	exit 0;
}


my ($tunefold,$r,$t,$wi_cro,$iflat, $allhhedlog) = @ARGV;

#pause($tunefold);
#my $tunefold  = $TUNE_WORK."/".$addstr;
#my $bak     = $TUNE_BAK."/work/".$addstr;
#my $ro_tb   = "ro".$r."tb".$t;
#$tunefold     = $tunefold."/".$ro_tb;
#$bak 		 = $bak."/".$ro_tb;
if($iflat eq "lat"){
	$tunefold = $tunefold."/withlat";
}elsif($iflat eq "nolat"){
	$tunefold = $tunefold."/nolat"; 
}elsif($iflat eq ""){
     $tunefold = $tunefold."/nolat"; 
}
#pause($iflat." ".$tunefold);

my $lasthmm = lasthmm($HMM_ROOT."/train_tri_endhmm.log");
my $beghmm = $lasthmm;
my $tohmm  = $beghmm + 1;
my $orihmm  = $HMM_ROOT."/hmm".$lasthmm;

my $hmmfold   = $tunefold."/hmm".$beghmm;
my $hmmfold2     = $tunefold."/hmm".$tohmm;
my $flist	  = $tunefold."/fulllist";
my $tlist	  = $tunefold."/tiedlist";
my $treehed = $tunefold."/tree.hed";

#unless(-e $bak){
#	mkpath($bak,{mode=>0777})||die "can not mkpath $bak: $!";
#}

unless(-e $tunefold){
	mkpath($tunefold,{mode=>0777})||die "can not mkpath tunefold: $!";
}

#pause($tunefold);

if (-e $hmmfold){
	rmtree ($hmmfold)|| die "can not rmtree ".$hmmfold.": $!";	
}

unless(-e $hmmfold){
	mkpath($hmmfold,{mode=>0777})||die "can not mkpath hmmfold: $!";
}
movecopy_dir2("copy",$orihmm, $hmmfold);

#rm -f -r hmm13 hhed_cluster.log fullist tree.hed
if (-e $hmmfold2){
	rmtree($hmmfold2)||die "can not rmtree: ".$hmmfold2." $!";
}

unless(-e $hmmfold2){
	mkpath($hmmfold2,{mode => 0777})||die "can not mkpath ".$hmmfold2.": ".$!;
}
for($tunefold."/hhed_cluster.log", $flist, $treehed){
	if (-e $_){
		unlink($_)||die "can not unlink $_: ".$!;
	}
}



# We have our own script which generate all possible monophone,
# left and right biphones, and triphones.  It will also add
# an entry for sp and sil
# if [[ $3 != "cross" ]]
# then
# perl $TRAIN_SCRIPTS/CreateFullListWI.pl $TRAIN_TIMIT/cmu6 >fulllist
# else
# perl $TRAIN_SCRIPTS/CreateFullList.pl $TRAIN_TIMIT/monophones0 >fulllist
# fi



unless ($wi_cro eq "cross"){	
	#perl $TRAIN_SCRIPTS/CreateFullListWI.pl $TRAIN_TIMIT/cmu6 >fulllist
	system $AUEXE."/CreateFullListWI.pl $LIB/cmu6\>".$flist;
}else{
	system $AUEXE."/CreateFullList.pl $MONOLIST0\>".$flist;
}

# Now create the instructions for doing the decision tree clustering

# RO sets the outlier threshold and load the stats file from the
# last round of training
open(TH,">".$treehed)||die "can not open file ".$treehed.": ".$!;
#system "echo RO $r $LIB/stats\>".$treehed;
print TH "RO $r $LIB/stats\n";
# Add the phoenetic questions used in the decision tree
#system "echo TR 0\>\>".$treehed;
print TH "TR 0\n";
close TH;
	

cat("\>\>",$treehed, $DOC."/tree_ques.hed");

# Now the commands that cluster each output state
system "echo TR 1 \>\>".$treehed;
system $AUEXE."/MakeClusteredTri.pl TB $t $MONOLIST1\>\>".$treehed;

system "echo TR 1 \>\>".$treehed;
system "echo AU \"$flist\"\>\>".$treehed;

system "echo CO \"$tlist\" \>\>".$treehed;
system "echo ST \"$tunefold/trees\"\>\>".$treehed;



# Do the clustering
#HHEd -A -T 1 -H hmm12/macros -H hmm12/hmmdefs -M hmm13 tree.hed triphones1 >hhed_cluster.log

my $cmd = "HHEd -A -T 1 -H ".$hmmfold."/macros -H ".$hmmfold."/hmmdefs -M ".$hmmfold2." $treehed $TRILIST1>$tunefold/hhed_cluster.log";
system $cmd;



my $nownum;
if($allhhedlog){
	my ($allinfo, $total, $penc);
	open(LOG,"<".$tunefold."/hhed_cluster.log")||die "can not open file".$tunefold."/hhed_cluster.log for reading: ".$!;
	while(<LOG>){
		chomp;
		if(/TB:\s+Stats\s+\d+\-\>\d+\s+\[.+\%\]\s+\{\s*(\d+)\-\>(\d+)\s+\[([\d\.\%]+)\]\s+total\s*\}/){
		 #TB: Stats 22->1 [4.5%]  { 46758->2836 [6.1%] total }
			$allinfo = $_;
			$total   = $1;
			$nownum  = $2;
			$penc    = $3;
		}
	}
	close LOG;
	open(ALOG,">>".$allhhedlog)||die "can not open file ".$allhhedlog." for reading: ".$!;
	print ALOG "RO:".$r."\tTB:".$t."\t\t";
	print ALOG $total."\-\>".$nownum." [".$penc."]\n";	
	close ALOG;
}



if (-e $hmmfold){
	rmtree ($hmmfold)|| die "can not rmtree ".$hmmfold.": $!";	
}

system "echo $nownum\>".$tunefold."/modelnum.log";

system "echo $tohmm\>".$tunefold."/prep_tied_tune_endhmm.log";








