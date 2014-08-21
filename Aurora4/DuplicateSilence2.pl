#!/usr/local/bin/perl -w
use strict;

my ($hmmdefs_in, $proto_tex, @proto_array);

# check usage
if (@ARGV != 1) {
  print "usage: $0 hmmdefs_in\n\n"; 
  exit (0);
}

# read in command line arguments
# cmu1 is the original cmu. cmu2 is the modified cmu.
($hmmdefs_in) = @ARGV;

# open files
#
open (IN,"$hmmdefs_in") || die ("Unable to open hmmdefs_in $hmmdefs_in file for reading: ".$!);
#open (OUT,">$hmmdefs_out") || die ("Unable to open hmmdefs_out $hmmdefs_out file for writing");

# hmmdefs generate!
$proto_tex = join '',<IN>;

print $proto_tex;
$proto_tex =~ s/(~h \"sil\".*?<ENDHMM>)/$1/sgi; 
$proto_tex = $1; 
$proto_tex =~ s/~h \"sil\"/~h \"sp\"/gi;
$proto_tex =~ s/<NUMSTATES> 5/<NUMSTATES> 3/gi;
$proto_tex =~ s/<STATE> 2.*?<STATE> 3/<STATE> 2/sgi;
$proto_tex =~ s/(<STATE> 4.*?<TRANSP> 5\n)(.*?<ENDHMM>)/<TRANSP> 3\n/sgi;
print $proto_tex;
@proto_array = split /\n/,$2;
# print HMMDEFS_OUT $proto_tex;
print "0.000000e+000 1.000000e+000 0.000000e+000\n";
$proto_array[2] =~s/^\s+|\s+$//g;
my @num_array = split /\s+/,$proto_array[2];
my $line = join ' ',$num_array[1],$num_array[2],$num_array[3];
print "$line\n";
print "0.000000e+000 0.000000e+000 0.000000e+000\n";
print "<ENDHMM>\n";
close(IN);





