$SYS			= "WIN";
$SPLIT          = "\\";
$RUNNUM         = 2;
$ROOT 			= "D:/work/AURORA4_dp/myrun/experiments/go_flat_cross".$RUNNUM ;
$COND 			= "clean";
$EXEDOC 		= $ROOT."/exe_and_doc";
$AUEXE    		= $EXEDOC."/AuroraExe";
#$EXE    		= $EXEDOC."/AuroraExe";
$DOC    		= $EXEDOC."/doc";
$CONFIG      	= $DOC."/config";


$ALLLIB    		= $ROOT."/all_libs";
$LIB            = $ALLLIB."/aulib";

$DATAROOT 		= "D:/database";
$FEATYPE 		= "PLPDAZ0";
$WSJ0     		= $DATAROOT."/WsjEavLMandOthers";
$NEWWSJ0        = $DATAROOT."/WSJ0SPH_TOWAV".$RUNNUM;
$FEAROOT 		= $DATAROOT."/WSJ0WAV_TOFEA".$RUNNUM;
$FEAPATH  		= $FEAROOT."/".$FEATYPE;

$LATRO  = 200;   # 
$LATTB  = 750;
$LATP      = '-4.0';  #
$LATS      = '15.0';
$TUNETIEDP = '-4.0';
$TUNETIEDS = '15.0';
$PRUNE1    = '250.0'; #
$PRUNE2    = '350.0';

