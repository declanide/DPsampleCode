# Builds the word list and network we need for recognition 
# using the WSJ 5K standard language models

# We use the WSJ non-verbalized 5k closed word list. 

require "common_config.pl";

# Create a dictionary with a sp short pause after each word, this is
# so when we do the phone alignment from the word level MLF, we get
# the sp phone inbetween the words.  This version duplicates each
# entry and uses a long pause sil after each word as well.  By doing
# this we get about a 0.5% abs increase on Nov92 test set.
system $AUEXE."/AddSp.pl $LIB/cmu6 1\>$LIB/cmu6sp";

# We need a dictionary that has the word "silence" with the mapping to the sil phone
#cat $TRAIN_TIMIT/cmu6sp >$TRAIN_TIMIT/cmu6temp
cat(">",$LIB."/cmu6temp", $LIB."/cmu6sp");
#echo "silence sil" >>$TRAIN_TIMIT/cmu6temp
system("echo silence sil \>\>$LIB/cmu6temp");

#sort $TRAIN_TIMIT/cmu6temp >$TRAIN_TIMIT/cmu6spsil
system $AUEXE."/txtsort.pl"." ".$LIB."/cmu6temp"."\>".$LIB."/cmu6spsil";

#grep -v "#" $WSJ0_DIR/WSJ0/LNG_MODL/VOCAB/WLIST5C.NVP >dict_temp

my $diffofvp_log  = $LOG."/diff_between_nvp_and_cvp.log";

system $AUEXE."/grep.pl"." ".'no'." ".'#'." ".$DOC."/WLIST5C.NVP".'>'.$LIB."/dict_temp";
system $AUEXE."/grep.pl"." ".'no'." ".'#'." ".$DOC."/WLIST5C.VP".'>'.$LIB."/dicttempcvp_temp";

my $count = 0;
open(DTMP,"<".$LIB."/dicttempcvp_temp")||die "can not open file".$LIB."/dicttempcvp_temp for reading: ".$!;
open(DT,">".$LIB."/dict_temp_cvp")||die "can not open file".$LIB."/dict_temp_cvp for reading: ".$!;
while(my $word= <DTMP>){
	chomp($word);
	my ($prewrd,$postwrd) = ($word =~ /([^A-Za-z\d]*)(.+)/);
	if ($prewrd eq "--"){
		$prewrd = "\\-\\-";
	}elsif($prewrd ne ''){
		$prewrd = "\\".$prewrd;
	}
	
	if ($prewrd ne ''){
		$count++;
	}
	# my @special_chars = ($prewrd=~/(\S)/g);
	# print $prewrd."\n";	
	# for(@special_chars){
		# $_ = "\\".$_;
	# }
	# $prewrd = join '',@special_chars;

	$word   = $prewrd.$postwrd;
	print DT $word."\n";	
}
close DT;
close DTMP;

system "echo the special words in vp: $count>".$diffofvp_log;


#rm -f $TRAIN_TIMIT/cmu6temp


# open (LI,"<".$DOC."/WLIST5C.NVP")||die("can not open file ".$DOC."/WLIST5C.NVP for reading: ".$!);
# open (LO,">".$WLIST)||die("can not open file ".$WLIST." for writting: ".$!);
# print LO for grep !"#",<LI>;
# close LO;
# close LI;

# We need sentence start and end symbols which match the WSJ
# standard language model and produce no output symbols.
open(D5,">".$DICT)||die "can not open file $DICT for writting: ".$!;
print D5 '<s> [] sil'."\n";
print D5 '</s> [] sil'."\n";
close D5;

open(D5CVP,">".$DICTCVP)||die "can not open file $DICTCVP for writting: ".$!;
print D5CVP '<s> [] sil'."\n";
print D5CVP '</s> [] sil'."\n";
close D5CVP;

# Add pronunciations for each word
#perl $TRAIN_SCRIPTS/WordsToDictionary.pl dict_temp $TRAIN_TIMIT/cmu6sp dict_temp2
system ($AUEXE."/WordsToDictionary.pl $LIB/dict_temp $LIB/cmu6sp $LIB/dict_temp2");
cat(">>",$DICT,$LIB."/dict_temp2");

system ($AUEXE."/WordsToDictionary.pl $LIB/dict_temp_cvp $LIB/cmu6sp $LIB/dict_temp_cvp2");
cat(">>",$DICTCVP,$LIB."/dict_temp_cvp2");

difftxt($DICT,$DICTCVP,$diffofvp_log,"\>\>");


#rm -f dict_temp dict_temp2
rename($LIB."/dict_temp2",$RUNBAK."/dict_temp2")||die "can not move file dict_temp2 to ".$RUNBAK." ".$!;
#pause("please set the one file below to command");
rename($LIB."/dict_temp",$RUNBAK."/dict_temp")||die "can not move file dict_temp to ".$RUNBAK." ".$!;

rename($LIB."/dict_temp_cvp2",$RUNBAK."/dict_temp_cvp2")||die "can not move file dict_temp_cvp2 to ".$RUNBAK." ".$!;
#pause("please set the one file below to command");
rename($LIB."/dict_temp_cvp",$RUNBAK."/dict_temp_cvp")||die "can not move file dict_temp_cvp to ".$RUNBAK." ".$!;
# Decompress the WSJ standard language model and build the word network

#cat('>', $LIB."/lm_temp", $DOC."/BCB05CNP");
# open(INB,"<".$DOC."/BCB05CNP_unix")||die "unable to open file ".$DOC."/BCB05CNP for reading: ".$!;
# open(OUB,">".$LIB."/lm_temp")||die "unable to open file ".$LIB."/lm_temp for writting: ".$!;
# my $bigramstr = join "", <INB>;
# my $datapos   = rindex($bigramstr,"\\data\\");
# pause ($datapos);
# $bigramstr   = substr($bigramstr,$datapos);
# print OUB $bigramstr;
# close INB;
# close OUB;


copy($DOC."/BCB05CNP_unix",$LIB."/lm_temp")||die "can not copy file ".$DOC."/BCB05CNP_unix to ".$LIB."/lm_temp ".$!;

my $cmd = join (
	" ",
	"HBuild -A -T 1 ",
	"-C ".$CONFIG."/configrawmit ",
	"-n ".$LIB."/lm_temp ",
	"-u ", 
	#"\'",
	'^<UNK^>',
	#"\' ",
	"-s ",
	#"\'",
	'^<s^>',
	#"\' ",
	#"\'",
	'^<^/s^>',
	#"\' ",
	"-z ",
	$DICT,
	$WDNET."\>".$LOG."/hbuild.log");
system $cmd;
if (-e $LIB."/lm_temp"){
	rename($LIB."/lm_temp",$RUNBAK."/lm_temp")||die "can not rename file lm_temp from $LIB to $RUNBAK: ".$!;
}
#pause($cmd);
copy($DOC."/BCB05CVP_unix",$LIB."/lm_temp_cvp")||die "can not copy file ".$DOC."/BCB05CVP_unix to ".$LIB."/lm_temp_cvp ".$!;

$cmd = join (
	" ",
	"HBuild -A -T 1 ",
	"-C ".$CONFIG."/configrawmit ",
	"-n ".$LIB."/lm_temp_cvp ",
	"-u ", 
	#"\'",
	'^<UNK^>',
	#"\' ",
	"-s ",
	#"\'",
	'^<s^>',
	#"\' ",
	#"\'",
	'^<^/s^>',
	#"\' ",
	"-z ",
	$DICTCVP,
	$WDNETCVP."\>".$LOG."/hbuild_cvp.log");
	

system $cmd;
if (-e $LIB."/lm_temp_cvp"){
	rename($LIB."/lm_temp_cvp",$RUNBAK."/lm_temp_cvp")||die "can not rename file lm_temp_cvp from $LIB to $RUNBAK: ".$!;
}

print "...the wdnet cvp has been finished\n";
#unlink($LIB."/lm_temp");


