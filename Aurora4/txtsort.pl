use strict;


if (@ARGV < 1){
	print "$0 usage: input file, output file\n";
	exit(0);
}

my (@infiles) = @ARGV;

my @line_arr;

foreach my $infile(@infiles){
	open(IN,"<".$infile)||die("can not open file $infile for reading: ".$!);
	#open(OUT,">".$outfile)||die("can not open file $outfile for writting: ".$!);
	while (<IN>){
		chomp;
		push (@line_arr,$_);
	}
	
	close IN;	
	#close OUT;
}

for (sort @line_arr) {
	print $_."\n";
}




