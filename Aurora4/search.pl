require("common_config.pl");

my ($file, $pattern, $pos) = @ARGV;



if(@ARGV < 1){
	print "$0 usage: file, [pattern, position]";
	exit(0);
} 

my $num   = scalar @ARGV;
my @searchs;

#open (OUT,$wstyle.$dstf)||die("can not open file $dstf for writting: ".$!);

open (IN,"<".$file)||die("can not open file $file for reading: ".$!);
if($num >= 2 ){		
	while(<IN>){				
		chomp;							
		push (@searchs, $_) if ($_ =~ /$pattern/);		
	}
    if($num >= 3){
		print $searchs[$pos];
		print "\n";
	}else{
		foreach(@searchs){
		print $_."\n";
		}
	}
}else{
	my $filestr = join "",<IN>;
	print $filestr."\n";
}
close(IN);




