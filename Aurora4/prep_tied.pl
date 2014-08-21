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
#cd $TRAIN_WSJ0

my ($r,$t,$wi_cro) = @ARGV;
if (@ARGV != 3){
	print "prep_tied.pl ro tb wi|cross \n";
	exit(0);
}

my $lasthmm = lasthmm($HMM_ROOT."/train_tri_endhmm.log");



my $beghmm = $lasthmm;
my $tohmm  = $beghmm + 1;
my $treehed = $LIB."/tree.hed";
my $trees    = $LIB."/trees";

#my $hmm12 = $HMM_ROOT."/hmm12";
#my $hmm13 = $HMM_ROOT."/hmm13";

#rm -f -r hmm13 hhed_cluster.log fullist tree.hed
if(-e $HMM_ROOT."/hmm".$tohmm){
	rmtree($HMM_ROOT."/hmm".$tohmm)||die "can not rmtree hmm$tohmm: ".$!;
	#movecopy_dir("move",$HMM_ROOT."/hmm".$tohmm,$RUNBAK."/prep_tied","tree");
}
for($LOG."/hhed_cluster.log", $FULLLIST, $treehed,$TIEDLIST,$trees){
	if (-e $_){
		unlink($_)||die "can not unlink $_: ".$!;
	}
}


unless(-e $HMM_ROOT."/hmm".$tohmm){
	mkpath($HMM_ROOT."/hmm".$tohmm,{mode => 0777})||die "can not mkpath ".$HMM_ROOT."/hmm".$tohmm.": ".$!;
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
	system $AUEXE."/CreateFullListWI.pl $LIB/cmu6\>$FULLLIST";
}else{
	system $AUEXE."/CreateFullList.pl $MONOLIST0\>$FULLLIST";
}

# Now create the instructions for doing the decision tree clustering

# RO sets the outlier threshold and load the stats file from the
# last round of training


#system "echo RO $r $LIB/stats\>".$treehed;
open(TH,">".$treehed)||die "can not open file ".$treehed.": ".$!;
print TH "RO $r $LIB/stats\n";
print TH "TR 0\n";
close TH;

cat("\>\>",$treehed, $DOC."/tree_ques.hed");

# Now the commands that cluster each output state
system "echo TR 12\>\>".$treehed;
system $AUEXE."/MakeClusteredTri.pl TB $t $MONOLIST1\>\>".$treehed;

system "echo TR 1 \>\>".$treehed;
system "echo AU \"".$FULLLIST."\"\>\>".$treehed;

system "echo CO \"".$TIEDLIST."\" \>\>".$treehed;
system "echo ST \"".$trees."\"\>\>".$treehed;

# Do the clustering
#HHEd -A -T 1 -H hmm12/macros -H hmm12/hmmdefs -M hmm13 tree.hed triphones1 >hhed_cluster.log

system "HHEd -A -T 1 -H $HMM_ROOT/hmm".$beghmm."/macros -H $HMM_ROOT/hmm".$beghmm."/hmmdefs -M $HMM_ROOT/hmm".$tohmm." $treehed $TRILIST1>$LOG/hhed_cluster.log";

system "echo $tohmm>".$HMM_ROOT."/prep_tied_endhmm.log";


