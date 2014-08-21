# If previous monophone models aren't available (say from TIMIT), then
# this script can be used to flat start the models using the word 
# level MLF of WSJ0.
require ("common_config.pl");


use File::Copy 'cp';
use File::Path 'rmtree';

if (@ARGV < 1){
	print "$0 usage: mainhmm [$fixpattern]\n";
	exit(0);
}
#print "1\n";

my ($mainhmm,$type) = @ARGV;
#goto ENDLAB;
#goto BEG;

# for(0..9){
	# if (-e $mainhmm."/hmm".$_){		
		#movecopy_dir("move",$mainhmm."/hmm".$_,$RUNBAK,"tree");
		#pause();
		#if (/5/){
		#	mocopy_dir("move",$mainhmm."/hmm".$_,$RUNBAK,"tree");
		#}else{
			#rmtree($mainhmm."/hmm".$_)||die "can not rmtree $mainhmm/hmm$_: ".$!;
		#}
	# }
# }
#print "2\n";
if ($LOG."/hhed_flat.log",$LOG."/hcompv_flat.log"){
	if (-e $_){
		unlink($_)||die "can not delete $_: ".$!;
	}
}

#print "3\n";
#BEG:
#rm -f -r hmm0 hhed_flat.log hcompv_flat.log hmm1 hmm2 hmm3 hmm4 hmm5
my $hmm0 = $mainhmm."/hmm0";

my $silhed;

if(($fixpattern eq "5states")||($fixpattern eq '')){
	$silhed = "sil.hed"
}elsif($fixpattern eq "3states"){
	$silhed = "sil2.hed";
}else{
	die "there are wrong with the fixpattern parameter in flat_start.pl\n";
}

# my $hmm1 = $mainhmm."/hmm1";
# my $hmm2 = $mainhmm."/hmm2";my $hmm3 = $mainhmm."/hmm3";
# my $hmm4 = $mainhmm."/hmm4";my $hmm5 = $mainhmm."/hmm5";
# my $hmm6 = $mainhmm."/hmm6";my $hmm7 = $mainhmm."/hmm7";
# my $hmm8 = $mainhmm."/hmm8";my $hmm9 = $mainhmm."/hmm9";
# my $hmm10 = $mainhmm."/hmm10";
#goto MID;

#muti_mkdir("tree","in flat_start.pl",$hmm0,$hmm1,$hmm2,$hmm3,$hmm4,$hmm5,$hmm6,$hmm7,$hmm8,$hmm9,$hmm10);
cp ($DOC."/monophones0", $MONOLIST0)||die "unable to copy file $DOC/monophones0 to $LIB: ".$!;
cp ($DOC."/monophones1", $MONOLIST1)||die "unable to copy file $DOC/monophones1 to $LIB: ".$!;

# First convert the word level MLF into a phone MLF




# Compute the global mean and variance and set all Gaussians in the given
# HMM to have the same mean and variance

# HCompV parameters:
#  -C   Config file to load, gets us the TARGETKIND = MFCC_0_D_A_Z
#  -f   Create variance floor equal to value times global variance
#  -m   Update the means as well
#  -S   File listing all the feature vector files
#  -M   Where to store the output files
if (-e $hmm0){
	rmtree($hmm0);
}

unless(-e $hmm0){
	mkpath($hmm0);
}
#hm0
cp($DOC."/proto_plp",$LIB."/proto")||die "can not copy proto from $DOC to $LI: ".$!;

print "let's begin\n";
$cmd = join (
	" ",
	"HCompV -A -T 1",
	"-C ".$CONFIG."/config",
	"-f 0.01 -m -S ".$TRAINLIST_FEA,
	"-M ".$hmm0,
	$LIB."/proto",
	">".$LOG."/hcompv_flat.log");

system $cmd;

print "pass\n";

# Create the master model definition and macros file

cp ($DOC."/macros_plp",$hmm0."/macros")||die "unable to copy $DOC/macros_plp to $hmm0/macros";
cat ("\>\>", $hmm0."/macros",$hmm0."/vFloors");

system $AUEXE."/CreateHMMDefs.pl $hmm0/proto $LIB/monophones0 \>$hmm0/hmmdefs";
my $beghmm = 0; $tohmm = 1;

print "pass again\n";

#AURORA: 0.. 3   另一个：0..2;
my $tn;
if($type == 2){
	$tn = 3;
}elsif(($type == 1)||($type == 0)){
	$tn = 2;
}
#hmm0->hmm4
for(0..$tn){
	if(-e $mainhmm."/hmm".$tohmm){
		rmtree($mainhmm."/hmm".$tohmm);
	}
	unless(-e $mainhmm."/hmm".$tohmm){
		mkpath($mainhmm."/hmm".$tohmm);
	}
	system $AUEXE."/train_iter.pl $mainhmm hmm".$beghmm." hmm".$tohmm." $MONOLIST0 $PHONES0 3 text $TRAINLIST_FEA";
	++$beghmm;
	++$tohmm;
#pause("training 1");
}


#$TRAIN_TIMIT/train_iter.sh $TRAIN_WSJ0 hmm1 hmm2 monophones0 phones0.mlf 3 text
#$TRAIN_TIMIT/train_iter.sh $TRAIN_WSJ0 hmm2 hmm3 monophones0 phones0.mlf 3 text

#cd $TRAIN_WSJ0

# Finally we'll fix the silence model and add in our short pause sp 
# See HTKBook 3.2.2.



if(-e $mainhmm."/hmm".$tohmm){
	rmtree($mainhmm."/hmm".$tohmm);	
}
unless(-e $mainhmm."/hmm".$tohmm){
	mkpath($mainhmm."/hmm".$tohmm);
}

#hmm4-->hmm5

if(($fixpattern eq "5states")||($fixpattern eq '')){
	system $AUEXE."/DuplicateSilence.pl $mainhmm/hmm".$beghmm."/hmmdefs \>$mainhmm/hmm".$tohmm."/hmmdefs";
}elsif($fixpattern eq "3states"){
	system $AUEXE."/DuplicateSilence2.pl $mainhmm/hmm".$beghmm."/hmmdefs \>$mainhmm/hmm".$tohmm."/hmmdefs";
}else{
	die "there are wrong with the fixpattern parameter in flat_start.pl\n";
}

#perl $TRAIN_SCRIPTS/DuplicateSilence.pl hmm3/hmmdefs >hmm4/hmmdefs
cp($mainhmm."/hmm".$beghmm."/macros",$mainhmm."/hmm".$tohmm."/macros")||die "unable to cp file $mainhmm/hmm".$beghmm."/macros to $mainhmm/hmm".$tohmm."/macros";
#cp hmm3/macros hmm4/macros
++$beghmm; 
++$tohmm;

if(-e $mainhmm."/hmm".$tohmm){
	rmtree($mainhmm."/hmm".$tohmm);	
}
unless(-e $mainhmm."/hmm".$tohmm){
	mkpath($mainhmm."/hmm".$tohmm);
}
#hmm5-->hmm6;
$cmd = join (
	" ",
	"HHEd -A -T 1",
	"-H ".$mainhmm."/hmm".$beghmm."/macros",
	"-H ".$mainhmm."/hmm".$beghmm."/hmmdefs",
	"-M ".$mainhmm."/hmm".$tohmm,
	$DOC."/".$silhed,
	$MONOLIST1,
	">".$LOG."/hhed_flat_sil.log");
system $cmd;
#HHEd -A -T 1 -H hmm4/macros -H hmm4/hmmdefs -M hmm5 $TRAIN_TIMIT/sil.hed monophones1 >hhed_flat_sil.log
#pause("in flat start");

#hmm6->hmm10
#当按照AURORA模式进行训练时，如果不按照aurora模式，哪么这部分不执行。
#unless(($type == 1)||($type == 0)){
if($type == 2){
	for(0..3){
		++$beghmm;
		++$tohmm;
		if(-e $mainhmm."/hmm".$tohmm){
			rmtree($mainhmm."/hmm".$tohmm);	
		}
		unless(-e $mainhmm."/hmm".$tohmm){
			mkpath($mainhmm."/hmm".$tohmm);
		}
		system $AUEXE."/train_iter.pl $mainhmm hmm".$beghmm." hmm".$tohmm." $MONOLIST1 $PHONES1 3 text $TRAINLIST_FEA";
	}
}

system "echo $tohmm\>".$HMM_ROOT."/flat_start_endhmm.log";



