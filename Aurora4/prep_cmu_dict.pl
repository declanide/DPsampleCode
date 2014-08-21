# Given the CMU 0.6 pronounciation dictionary, convert it
# into the form we'll be using with the HTK.
#
# Also adds in extra words we discovered we needed for
# coverage in the WSJ1 training data
#
require ("common_config.pl");

my $tempdict   = $LIB."/cmu6temp";
my $oridict    = $DOC."/c0.6";
my $extra_dict = $DOC."/wsj1_extra_dict";
my $newdict    = $LIB."/cmu6";


system $AUEXE."/FixCMUDict.pl $oridict \>$tempdict";

system $AUEXE."/MergeDict.pl $tempdict $extra_dict \>$newdict";

unlink($tempdict);
