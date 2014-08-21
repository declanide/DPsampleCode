#!/usr/bin/perl

# Checks that every file in the script file is actually in the MLF file.
#
# Copyright 2005 by Keith Vertanen
#

#use strict;
require "common_config.pl";

if ( @ARGV < 2 )
{
    print "$0 <MLF file> <original script file> [output not in]\n"; 
    exit(1);
}

my $MLFFile;
my $scriptFile;
my $posStart;
my $posEnd;
my $line;
my %files;
my $filename;
my $invert;

($MLFFile, $scriptFile, $log, $invert) = @ARGV;

# Read in all the filename lines from the MLF
open(IN, $MLFFile);
while ($line = <IN>) 
{
    #$line =~ s/\n//g;
	$line =~ chomp($line);
	
	if ($line =~/.*\.lab\"/gi){
		$line =~ s/\.lab\"//gi;
		$line =~ s/^\"//gi;

	}elsif($line =~ /.*\.rec\"/gi){
		$line =~ s/\.rec\"//gi;
		$line =~ s/^\"//gi;		
	}else{
		#pause("next");
		next;
	}
	$filename 			= $line;
	$files{$filename} 	= 1;	
	
}
close IN;
if ($log){
	open(LOG,">".$log)||die "can not open file ".$log." for writting\n";
}
open(IN, $scriptFile);
while ($line = <IN>) 
{
    $line =~ chomp($line);

    #$posStart = rindex($line, "/");
	$posStart = 0;

    if ($posStart >= 0)
    {
	
	$posEnd = rindex($line, ".fe");

	if ($posEnd > 0)
	{
	    $filename = substr($line, $posStart, $posEnd - $posStart);

	    if ($invert){
			if (!$files{$filename}){				
				print $line. "\n";			
			}else{
				if($log){
					print LOG "miss: $line\n";
				}
			}
	    }else{
			if ($files{$filename}){				
				print $line."\n";
				
			}else{
				if($log){
					print LOG "miss: $line\n";
				}
			}
	    }
	}
    }	
}
close IN;
if ($log){
	close(LOG);
}
