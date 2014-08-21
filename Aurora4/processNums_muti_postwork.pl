require "common_config.pl";
my ($t,$pv,$sv,$tunefold,$devortest) = @ARGV;
if (@ARGV != 5){
	print $0." usage: \$t \$pv \$sv \$devortest\n";
	die $0." usage: \$t \$pv \$sv \$devortest\n";
	exit 0;	
}
#print $t.$pv.$sv.$tunefold."\n";

 for ($tunefold."/recout_tune_$pv\_$sv\_$t\.mlf", $tunefold."/hvite_".$devortest."92_tune_".$t."\.log", $tunefold."/hresults_".$devortest."92_tune_".$t."\.log", $tunefold."/".$devortest."92_tune_".$t."\.log"){
	
	if (/.+tune.*\_$t\.(mlf|log)/gi){
		my $op = $devortest."92_tune";
		if ((-e $_)&&(-f $_)){			
			(my $ifname = $_) =~ s/\//\\/gi;
			unless($ifname =~ /.+\.mlf/){
				(my $ofname = $ifname) =~ s/(.*$op)\_$t(\.log)/$1$2/gi; 
				system("type ".$ifname.">>".$ofname);
				#pause($ifname."\n".$ofname."\n");
			}	

			unlink($_);
		}
	}

} 



