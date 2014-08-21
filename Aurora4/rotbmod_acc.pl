require "common_config.pl";

#use strict;

if(@ARGV < 2) {
	print $0.'$modf, $rtf'."\n";
	exit 0;
}
my ($rotb_modf, $rotb_accf,$bestmodelnum_file) = @ARGV;
my %rt_model;
my %rt_acc;

open(MF,"<".$rotb_modf)||die "can not open file $rotb_modf for reading: ".$!;
open(RTF,"<".$rotb_accf)||die "can not open file $rotb_accf for reading: ".$!;
#open(LOG,">".$log)||die "can not open file ".$log." for writting: ".$!;
while(<MF>){	
	next if (/^\s+$/);
	next if (/^#/);
	#print $_."\n";
	chomp;	
   	my ($r, $t, $model_num) = /RO:(\d+)\s+TB:(\d+)\s+\d+\-\>(\d+)\s*\S+/;
	$rt_model{$r." ".$t}    = $model_num; 
}

#pause(scalar keys %rt_model);
my $count = 0;
while(<RTF>){
	next if (/^\s+$/);
	next if (/^#/);
	chomp;
	next unless(/\d+\:\s+([\d\.]+)\s+([\d\.]+)\s+penalty and scal\:/);

	my ($cor, $acc, $rotbline)       = /\d+\:\s+([\d\.]+)\s+([\d\.]+)\s+penalty and scal\:\s+(\([\d\-\.]+\s+[\d\.\-]+\).*)/;

	my @rotbs = ($rotbline =~ /\(([\d\-\.]+\s+[\d\.\-]+)\)/gi);	
	print $cor." ".$acc." ";
	my $model_num;
	foreach my $rt(@rotbs){
		$rt =~ s/(\S+)\s+(\S+)/$1 $2/gi;
		$model_num = $rt_model{$rt};
		print "(".$rt." ".$model_num.")\t";
		$rt_acc{$_} = $acc;		
	}	
	print "\n";
	if($count == 0){
		if ($bestmodelnum_file){
			open(MN,">".$bestmodelnum_file)||die "can not open file ".$bestmodelnum_file." for reading: ".$!; 
			print MN $model_num."\n";
			close MN;
		}
	}
	++$count;
}
close MF;
close RTF;





