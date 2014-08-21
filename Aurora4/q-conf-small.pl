require "common_config.pl";

if (@ARGV < 1){
	print $0." usage: ".'$fold, [$TN]'."\n";
	exit 0;
}

my ($latfold, $TN)=@ARGV;

my $tokn = 4;
if ($TN){
	$tokn = $TN;
}
my $conflatscp = $lig."/conflat.scp";

my $config_reconf = $CONFIG."/config_reconf";

my $sentstart= '<s>';
my $sentend  = '</s>';
my $unk      = '<UNK>';
system "echo STARTWORD=$sentstart>$config_reconf";
system "echo ENDWORD=$sentend>>$config_reconf";
system "echo UNKNOWNNAME=$unk>>$config_reconf";
#system "echo LATRATE=100000.0>>%config-reconf%";

fea2lat($FEA_DEV_PATH,$DEVSCP,$latfold,$conflatscp);

my $latscp=%mainout%\t30lat.scp

%MyPerlId% %exe%\datas2lats.pl %doc%\t30.scp %latscp% %datapath% %latpath% mfc 



set alfadown=0.01
set alfastep=0.01
set alfaup=1.9

set down=6.0
set up=14.0
set step=0.1


%MyPerlId% %exe%\alfa_op_step.pl %MyPerlId% %exe% %alfadown% %alfastep% %alfaup% %down% %step% %up% %mainout% %htk% %config-reconf% ext 2 %doc%\bigram  t30lat.scp %doc%\dict1





