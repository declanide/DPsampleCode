require "common_config.pl";

use File::Path 'mkpath';
use File::Basename 'dirname';
use File::Basename 'basename';
use Cwd;

my ($scp,$newpath, $log,$str)=@ARGV;

#my ($newpath, $log,$str,$scp)=@ARGV;

my %idirs,%odirs;%dirs,@idirs,@odirs;
my %names;
my @names;


my $count = 0;

my $oripath = getcwd();

#$str="train";

my $createfoldlog = $LOG."/".$str."sphconvert_createfold.log";



unlink($createfoldlog) if (-e $createfoldlog);


open(WV,"<".$scp)||die("can not open file $scp for reading: ".$!);
while(<WV>){
	next if (/^\s+$/);
	++$count;
	chomp;
	#s/\//$SPLIT/gi;	
	my $olddir  = dirname $_;
	my $name    = basename $_;
	push (@names,$name);
	my $indir   = $olddir;
	$olddir     = name($olddir,4,1);
	#my $oldname = basename $_;
	my $outdir  = $newpath."/".$olddir;
	$idirs{$indir} = 1;
	$odirs{$outdir} =1;
	#$odirs{$outdir} = 1;	
}



close WV;
if (scalar @names != $count){
	print "there are some files in $sccp are missed when create related folders\n";
	exit(0);
}else{
	print "create folders finished\n";
}

@idirs = sort keys %idirs;
@odirs = sort keys %odirs;



if (scalar @idirs != scalar @odirs){
	print "there is problem in \@idirs and \@odirs because they have no the same quantity of elements\n";
	exit(0);
}else{
	for (0..$#idirs){
		my $iname   = name($idirs[$_],2,1);
		my $oname   = name($odirs[$_],2,1);
		print "there is problem\n" unless($iname eq $oname);
		#$dirs{$idirs[$_]}=$odirs[$_];	
		create_fold($odirs[$_],"tree","in first while loop of sphconvert.pl","\>\>".$createfoldlog);
		print $idirs[$_];
		print "\-\-\-\-\-\>";
		print $odirs[$_];
		print "\n";
	}	
}


#pause("begin conver inside");
print "\n\n--------------------------begin convert-----------------------\n\n";
#pause("begin conver inside");

my $cmd;
my $opstr1 = "";
my $opstr2 = "";
my $opstr  = "";
if($log){
	unlink($log) if (-e $log);
	$opstr1 = ">".$log;
	$opstr2 = ">>".$log;
}



$count = 0;
for(0..$#idirs){
	++$count;
	my $idir = $idirs[$_];
	my $odir = $odirs[$_];
	print "chdir into output dir: $odir\ninput dir: is $idir\n";
	chdir ($odir)||die "can not chdir $odir: ".$!;
	if ($count == 1){
		$opstr = $opstr1;
	}elsif ($count > 1){
		$opstr = $opstr2;		
	}
	$cmd = join (
		" ",
		$AUEXE."/sph_convert\.exe -p -v -f wav -r ".$idir,
		$opstr
	);
	system $cmd;
	print "Convert: sph ".$idir." ------\> wave ".$odir."\n";
	
}

chdir ($oripath)||die "can not chdir ".$oripath.": ".$!;


print "finish function";



# while (my($key,$val)=idirs){
	# ++$count;
	# print "chdir into output dir: $val\ninput dir: is $key\n";
	# chdir ($val)||die "can not chdir $val: ".$!;	
	# if ($count == 1){
		# $opstr = $opstr1;
	# }elsif ($count > 1){
		# $opstr = $opstr2;		
	# }
	
	# $cmd = join (
		# " ",
		# "$LDC/sph_convert\.exe -p -v -r ".$key,
		# $opstr
	# );
	# system $cmd;
	# print "Convert: sph ".$key." ------\> wave ".$val."\n";
# }

# foreach my $indir(@idirs){
	# foreach my $outdir(@odirs){
		# my $subin  = name($indir,4,1);
		# my $subout = name($outdir,4,1);
		# unless ($subin eq $subout){
			# print "there problem in $indir and $outdir because they have no the same subname: $subin \!= $subout\n";
			# exit(0);
		# }
		# if ($count == 1){
			# $opstr = $opstr1;
		# }elsif ($count > 1){
			# $opstr = $opstr2;		
		# }
	# }
# }


