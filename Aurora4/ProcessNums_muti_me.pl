#!/usr/bin/perl

# Processes a bunch of file with numbers in columns through a 
# template script file.  The template contains !COL1, !COL2, etc
# to indicate where to put the values from the list of numbers
# file.
#
# Copyright 2005 by Keith Vertanen
#

#use strict;
require "common_config.pl";

if (@ARGV < 7){
	print $0.' usage: $listFile, $devortest, $latin, $tunefold, $T, $rechmm, $co_n_vp, [$del_list], [$limit]'."\n";
	exit 0;
}


my ($listFile, $devortest, $latin, $tunefold, $T, $rechmm,$co_n_vp, $del_list, $inhmmroot,$intiedlist, $limit) = @ARGV;

my $hmmroot = $HMM_ROOT;
$hmmroot = $inhmmroot if($inhmmroot);

my $tiedlist = $TIEDLIST;
$tiedlist  = $intiedlist if($intiedlist);

#my @template;
#my $templateSize = 0;

#my $i = 0;
#my $command = "";
#my $pos = 0;



# open(IN, $templateFile);
# while ($line= <IN>)
# {
	
	# next if ($line =~ /^\#/);
	# next if ($line =~ /^\s+$/);
	# $template[$templateSize] = $line;
	# $templateSize++;
# }
# close IN;

open(IN, $listFile);
my $line;
my $count = 0;

while ($line = <IN>) 
{
	if (($limit ne "") && ($count >= $limit))
	{
		last;
	}
	
	if ($line =~ /^\s*\n/){
		print "space line in process $T\n";
		next;
	};
	if ($line =~ /^\#.*\n/){
		print "comment line in process $T\n";
		next;
	}
	
	$line =~ s/[\r\n]//g;
	
	
	my($pen,$lms) = split(/\s+/, $line);
	for($pen,$lms){
		unless (/[\-\d]+\.\d+/){
			s/([\-\d]+)/$1\.0/;
		}
	}
	
	exe_tune($hmmroot, $rechmm,$tunefold, $pen,$lms,$T,$latin,$co_n_vp);
	system $AUEXE."/processNums_muti_postwork.pl ".$T." $pen $lms $tunefold $devortest";
	
	$count++;

}
close IN;
unlink($listFile) if ($del_list eq "del");
	# my $LAB;
	# for ($i = 0; $i < $templateSize; $i++)
	# {
		# $command = $template[$i];

		# for ($j = 1; $j <= scalar @cols; $j++){
			# $command =~ s/!COL$j/$cols[$j - 1]/g;			
		# }
		#$command   =~ s///gi;
		
		# $command   =~ s/\$([a-zA-Z_]{1}\w*)/$$1/g;
		# $command   =~ s/!LATIN/$latin/gi;
		# $command   =~ s/!TUNE/$tunefold/gi;
		# $command   =~ s/!TH/$T/gi;
		# $command   =~ s/!DT/$devortest/gi;
		# $command   =~ s/!HMM/$rechmm/gi;
		
		# print $command."\n";	
		# system $command;

sub exe_tune {
	my($hmmroot, $inhmm,$tunefold, $p,$s,$t,$latin,$convp) = @_;
	my $dict;
	if ($convp eq "cvp"){
		$dict = $DICTCVP;
	}elsif($convp eq "cnvp"){
		$dict = $DICT;
	}
	system "HVite -A -T 1 -t 250.0 -C ".$CONFIG."/configcross -H $hmmroot/".$inhmm."/macros -H ".$hmmroot."/".$inhmm."/hmmdefs -S ".$DEVSCP." -i ".$tunefold."/recout_tune_".$p."_".$s."_".$t.".mlf -X lat -L ".$latin." -w -p ".$p." -s ".$s." ".$dict." ".$tiedlist."\>".$tunefold."/hvite_".$devortest."92_tune_".$t.".log";
	#print ($hvitecmd."\n"); 
	#pause("in process num muti me");
	
	system "echo Crossword, insertion penalty: ".$p."\>$tunefold/hresults_".$devortest."92_tune_".$t.".log";
	system "echo Crossword, LM scale factor: ".$s."\>\>$tunefold/hresults_".$devortest."92_tune_".$t.".log";

	system "HResults -A -T 1 -n -I ".$DEVWORDS3." ".$tiedlist." ".$tunefold."/recout_tune_".$p."_".$s."_".$t.".mlf\>\>".$tunefold."/hresults_".$devortest."92_tune_".$t.".log";

	system "echo Crossword  ".$p."	".$s.">".$tunefold."/".$devortest."92_tune_".$t.".log";
	system $AUEXE."/search.pl ".$tunefold."/hresults_".$devortest."92_tune_".$t.".log WORD -1>>".$tunefold."/".$devortest."92_tune_".$t.".log";

	system "HResults -A -T 1 -n -h -I ".$DEVWORDS3." ".$tiedlist." ".$tunefold."/recout_tune_".$p."_".$s."_".$t.".mlf\>\>".$tunefold."/hresults_".$devortest."92_tune_".$t.".log";	
}







