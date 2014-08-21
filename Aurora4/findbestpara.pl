use strict;

unless (@ARGV == 1){
	print "$0 usage: \$file\n";
	#exit(0);
}

my ($file) = @ARGV;

my $file_line;
my %results;

open(IN,"<".$file)||die "can not open $file for reading: ".$!;
$file_line = join '',<IN>;
close IN;

my %results  =  ($file_line =~ /Crossword\s+([\-\.\d]+\s+[\-\.\d]+)\s*\nWORD\:\s+\%Corr\=([-\.\d]+\,\s+Acc\=[-\.\d]+)\s+\[.+?\]\n/gi);

my (%ps_ac, %ps_ca_str);
my $ind = 0;
while(my($key,$val) = each %results){
	my $p_s 	    = $key;#join 'and', (split /\s+/,$key);
	my $ca_str      = "\%Corr=".$val;
	#print $p_s."\t".$ca_str."\n";
	(my $temp = $val) =~ s/\,\s+Acc\=/ /;
	my @temps 	    = split /\s+/,$temp;
	
	for(@temps){
		$_=$_*100;
		$_=sprintf("%04d", $_);
	}
	my $a_c = join "",reverse @temps;
	$ps_ac{$p_s}     = $a_c; 
	$ps_ca_str{$p_s} = $ca_str;

	++$ind;
}
my @acc_cors = (sort {$a<=>$b} values %ps_ac);
my $max_a_c_val = @acc_cors[-1];

while (my ($key,$val)=each %ps_ac){
	if ($val == $max_a_c_val){
		print "\nbest: ".$key."\n".$ps_ca_str{$key}."\n";
	}
}
print "\n\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\n";
print "\-\-\-\-\-\-\- 按照先Acc后Corr的顺序,从大到小-\-\-\-\-\-\-\-\-\-\-\-\-\-\n";
print "\-\-\-\-\-\-\-\-屏幕排列是先 Corr 后 Acc -\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\n";
print "\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\n";

my %acval;
$ind = 0;
print "num \tCorr\tAcc\n";
foreach(reverse @acc_cors){
	++$ind;
	my $acnum  = $_;
	if ($acval{$acnum}){
		next;		
	}
	my @acnums = /(\d{4})/gi;
	my @canums = reverse @acnums;
	my $count = 0;
	for(@canums){
		my @canums_temp = /(\d{2})/gi;
		my $val = join "\.",@canums_temp;
	    
		if ($count == $#acnums){
			print $val;
		}else{
			print $ind.":\t".$val."\t";
		}		
		++$count;		
	}
	print "\t\tpenalty and scal:";
	while (my ($key,$val)=each %ps_ac){
		if ($val == $acnum){
			print " (".$key."\)";
		}
	}
	print "\n";
	
	$acval{$acnum} = 1;
	
}





