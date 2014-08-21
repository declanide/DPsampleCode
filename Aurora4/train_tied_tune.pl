
# Train the word internal phonetic decision tree state tied models

#cd $TRAIN_WSJ0
require ("common_config.pl");

use File::Copy 'cp';
use File::Path 'rmtree';
use File::Path 'mkpath';

if (@ARGV < 4){
	print "$0 usage: mainfold, ro, tb, wi|cross, [iflat], [type], [trainnum], [\$del] [$endfile1], [$endfile2] \n";
	exit 0;
}

my ($tunefold, $r,$t,$wi_cro,$iflat,$type, $trainnum, $del, $endfile1, $endfile2) = @ARGV;
# $type: 1 -->  用+2模式递增，而且还有一个单独的静音训练
# $type:2 --> 传统的乘以2递增。




# my $tunefold  = $TUNE_WORK."/".$addstr;
# my $ro_tb   = "ro".$r."tb".$t;
# $tunefold     = $tunefold."/".$ro_tb;
if($iflat eq "lat"){
	$tunefold = $tunefold."/withlat";
}elsif($iflat eq "nolat"){
	$tunefold = $tunefold."/nolat"; 
}elsif($iflat eq ""){
     $tunefold = $tunefold."/nolat"; 
}

my $lasthmm = lasthmm($tunefold."/prep_tied_tune_endhmm.log");
#pause($lasthmm);
my $beghmm  = $lasthmm;
my $tohmm   = $beghmm +1;
#pause($lasthmm);
my $tlist	  = $tunefold."/tiedlist";

my $tn = 4;
if ($trainnum){
	$tn = $trainnum;
}

#my $beghmm = 13;
#my $tohmm  = $beghmm + 1;

my $beghmmid2 = $beghmm + 1;
my $finalhmmid1 = $beghmm + $tn;
my $finalhmmid2;
# 1 原来那个 ， 2 aurora
if(($type == 1)||($type == 0)){    
	$finalhmmid2= $finalhmmid1 + 5*($tn+1);
}elsif($type == 2){	
	$finalhmmid2= $finalhmmid1 + 4*($tn+1);
}
#pause($beghmmid2." ".$finalhmmid2." ".$finalhmmid1);

for($beghmmid2..$finalhmmid2){
	if (-e $tunefold."/hmm".$_){
		rmtree($tunefold."/hmm".$_)||die "unable to rmtree hmm".$_.": ".$!;
	}
}
for($beghmmid2..$finalhmmid2){
	#create_fold($tunefold."/hmm".$_,"tree","in tune_train_tied.pl");
	unless(-e $tunefold."/hmm".$_){
		mkpath($tunefold."/hmm".$_)||die "can not mkpath hmm".$_." ".$!;
	}

}
for($beghmmid2..$finalhmmid2){
	if (-e $tunefold."/hmm".$_."/hmm".$_."\.log"){
		unlink($tunefold."/hmm".$_."/hmm".$_."\.log");
	}	
}
#pause();

#goto test;

my $count  = 1;
for(1..$tn){
	my $cmd = $AUEXE."/train_iter.pl $tunefold hmm$beghmm hmm$tohmm $tlist $TRIWORDS ".'0'." bin $TRAINSCP";
	system $cmd;
	++$beghmm; ++$tohmm;
}	
print "snowdp here\n";
#17 18
# 1  原来， 2 aurora
if(($type == 1)||($type == 0)){
	print "mixture 1\n";
	system "HHEd -B -H $tunefold/hmm".$beghmm."/macros -H $tunefold/hmm".$beghmm."/hmmdefs -M $tunefold/hmm".$tohmm." $DOC/mix1.hed ".$tlist.">$tunefold/hhed_mix1.log";
	++$beghmm; ++$tohmm;
	for(1..$tn){
		system $AUEXE."/train_iter.pl $tunefold hmm$beghmm hmm$tohmm $tlist $TRIWORDS ".'0'." bin $TRAINSCP";
		++$beghmm; ++$tohmm;
	}	

}

print "snowdp2 here\n";

my $count = 1;
my $mixnum = 2;
while($count <= 4){
	
	my $postfix;
	#2 aurora,  1, 原来
	if($type == 2){
		$postfix = $mixnum."_new";
	}elsif(($type == 1)||($type == 0)){
		$postfix = $mixnum;
	}
	print "mixture ".$mixnum."\n";
	
	system "HHEd -B -H $tunefold/hmm".$beghmm."/macros -H $tunefold/hmm".$beghmm."/hmmdefs -M $tunefold/hmm".$tohmm." $DOC/mix".$postfix.".hed ".$tlist.">$tunefold/hhed_mix".$postfix.".log";
	++$beghmm; ++$tohmm;
	
	for(1..$tn){
		system $AUEXE."/train_iter.pl $tunefold hmm".$beghmm." hmm".$tohmm." $tlist $TRIWORDS ".'0'." bin $TRAINSCP";
		++$beghmm; ++$tohmm;
	}	
    
	# 2 aurora, 1 原来
	if($type == 2){
		$mixnum = $mixnum * 2;
	}elsif(($type == 1)||($type == 0)){
		$mixnum = $mixnum + 2;
	}
	++$count;
}

test:
print "snowdp3 here\n";

for($lasthmm..$finalhmmid2){
	next if ($_ == $finalhmmid1);
	next if ($_ == $finalhmmid2);
	if (-e $tunefold."/hmm".$_){
		rmtree($tunefold."/hmm".$_)||die "unable to rmtree hmm".$_.": ".$!;
	}
}

print "go here\n";

--$beghmm;
--$tohmm;
unless($finalhmmid2 == $tohmm){
    pause("there are problem in train tied tune pl. ");
}

print "go here2\n";

system "echo ".$finalhmmid1.">".$tunefold."/".$endfile1;
system "echo ".$finalhmmid2.">".$tunefold."/".$endfile2;


print "end of train_tied\n";






