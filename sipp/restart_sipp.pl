#!/usr/local/bin/perl

local $| =1;

my $killwaitT = $ARGV[0];
my $startwaitT = $ARGV[1];
$SIG{INT}=\&signalhandler;

open(FILE,">>restart_log.log");
print FILE "Logging Started.........\n";

while(1)
{

csleep($killwaitT);
logtxt("calling stopsipp.sh !!!");
system("sh stopsipp.sh");
csleep($startwaitT);
logtxt("calling startsipp.sh ##");
system("sh startsipp.sh");
}

sub signalhandler
{
	logtxt("ERROR Got a signal to Terminate the process..!");
	close(FILE);
	exit(0);
}
sub csleep
{
	my $TimeToSleep = shift;
	for (0..$TimeToSleep)
	{
		print "\rsleeping sec:$_";
		sleep(1);
	}	
	print "\n";
	return 0;
}

sub logtxt
{
	my $txttolog= shift;
	$datestring = localtime();
	print FILE "$datestring $txttolog\n";
	return 0;
}
