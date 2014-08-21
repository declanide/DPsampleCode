#require("common_config.pl");

my ($yes_no,$pattern, @files) = @ARGV;


if(@ARGV < 3){
	print 'grep.pl usage: $yes_no, $pattern,file1 file2 file3...'."\n";
	exit(0);
} 

#open (OUT,$wstyle.$dstf)||die("can not open file $dstf for writting: ".$!);
foreach my $file(@files){
	my $filestr ="";
	open (IN,"<".$file)||die("can not open file $dstf for reading: ".$!);
	if($pattern){		
		while(<IN>){
			chomp;
			
			if (($yes_no eq "-v")||($yes_no eq 'no')){
				next if( $_ =~ /$pattern/);
				print $_."\n";
			}elsif (($yes_no eq '')||($yes_no eq 'yes')){
				print $_."\n" if ($_ =~ /$pattern/);
			}
		}		
	}else{
		$filestr = join "",<IN>;
	}
	close(IN);
	print $filestr;
}
close(OUT);
