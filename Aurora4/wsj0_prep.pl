
#cd $WSJ0_DIR

# The WSJ0 data is stored compressed using shorten method.  Using w_decode
# or shorten as the filter to HTK didn't work, but sph2pipe does work but
# if we leave it in sphere format the header is wrong and lists it as 
# still being shortened.  So we'll have sph2pipe convert to WAVE 16-bit
# linear PCM for HCopy to work with.

# Clean up any old files
#rm -f wv1_files.txt wv1_mfc.scp $TRAIN_WSJ0/hcopy.log

# Create a file with the filename with wc1, wav and mfc extensions on it
# Only get the files in the training directory.
#require "subroutine.pl";

require "common_config.pl";
use File::Find 'find';
my ($str,$subpatt,$outpath,$convertlog,$wavpath,$findpath) = @ARGV;

if (@ARGV != 6){
	print "prep usage: \$str,$\subpatt,\$outpath,\$convertlog,\$wavpath,\$findpath\n";
	exit(0);
}
#goto ENDLAB;
#my $cmd = "find.pl ".$WSJ0." .*WSJ0\\SI_TR_S\\.*\.WV1 \>".$LIB."/wv1_files.txt";
#system $cmd;
#goto MID;
#pause("$str $subpatt $outpath $convertlog $wavpath $findpath");
print  "begin create ".$str." scp file...\n";
#MID:
#find_files($findpath,'.*WSJ0\/'.$subpatt.'\/.*\.WV1',$LIB."/".$str."_wv1_files0.txt");
#pause();

open(SCP,">",$LIB."/".$str."_wv1_files0.txt")||die "unable to open file ".$str."_wv1_files0.txt"." for reading: ".$!;

#pause($findpath);

find(\&wanted1, $findpath);
close SCP;

print "...convert sph in ".$str." scp to wav\n";
pause("convert");

#system $AUEXE."/sphconvert.pl ".$LIB."/".$str."_wv1_files0.txt"." ".$wavpath." ".$convertlog." ".$str.">".$LOG."/".$str."_sphconvert_all\.log";
system $AUEXE."/sphconvert.pl ".$LIB."/".$str."_wv1_files0.txt"." ".$wavpath." ".$convertlog." ".$str.">".$LOG."/".$str."_sphconvert_all\.log";
pause("sphconvert");


#find_files($wavpath,'.*WSJ0\/'.$subpatt.'\/.*\.wa1',$LIB."/".$str."_wv1_files.txt");
open(SCP,">",$LIB."/".$str."_wv1_files.txt")||die "unable to open file ".$str."_wv1_files.txt"." for reading: ".$!;
find(\&wanted2, $wavpath);
close SCP;

pause($wavpath);

#ENDLAB:
# Create the list file we need to send to HCopy to convert .wv1 files to .mfc
system $AUEXE."/CreateMFCList.pl"." ".$LIB."/".$str."_wv1_files.txt"." "."wa1"." "."fe"." ".$outpath."\>".$LIB."/".$str."_wv1_mfc.scp";

print  "finish create ".$str." scp file...\n";


print "begin coding speech data...\n";
system "HCopy -A -D -T 1 -C $CONFIG/configwav -C $CONFIG/config -C $CONFIG/config_wsj -C $CONFIG/configbyteorder -S ".$LIB."/".$str."_wv1_mfc.scp\>$LOG/hcopy_".$str.".log";
#pause("hcopy");

sub wanted1 {			
	my $found_file = $File::Find::name;		
	if ($found_file =~ /.*WSJ0\/$subpatt\/.*\.WV1/gi){
		next if (index($found_file,"NIST-Speech-Disc-11-4.1-maybecopy")>=0);	
		print SCP $found_file."\n";
				
	}
}



sub wanted2 {			
	my $found_file = $File::Find::name;		
	if ($found_file =~ /.*WSJ0\/$subpatt\/.*\.wa1/gi){
		next if (index($found_file,"NIST-Speech-Disc-11-4.1-maybecopy")>=0);	
		print SCP $found_file."\n";					
	}

}







