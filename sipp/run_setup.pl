#!/usr/bin/perl -w
# This will start the scaling teset to measure the CCP call setup latency
# load is used to generate the backgroud load
# test is used to generate a single call session to measure the latency

our $test_remote_ip = shift;
our $test_remote_port = shift;
our $load_remote_ip = shift;
our $load_remote_port = shift;
our $local_ip = shift;
our $load_port = shift;
our $test_port = shift;
our $load_media_port = shift;
our $test_media_port = shift;

our $sipp = "./sipp";
#our @concurrent_list=(5,100);
#our @concurrent_list=(1,10,20,30,40,45,50,55,60,65);
our @concurrent_list=(1,2,3,4,5,6,7,8);
#our @concurrent_list=(10,40);

# Number of sip messages captured
our $sip_msgs_per_call = 11;

# Number of samples collected for test session
our $test_samples = 1800;
#our $test_samples = 300;

# Call duration of each load session
our $load_duration = 80;

# Call duration of each test session
our $test_duration = 2;

if (!defined($test_remote_ip)) {
    print "\nUsage: $0 <test_remote_ip> [test_remote_port] [load_remote_ip] [load_remote_port] [local_ip] [load_port] [test_port] [load_media_port] [test_media_port]\n\n";
    exit 1;
}

if (!defined($test_remote_port)) {
    $test_remote_port = "5070";
}

if (!defined($load_remote_ip)) {
    $load_remote_ip = $test_remote_ip;
}

if (!defined($load_remote_port)) {
    $load_remote_port = $test_remote_port;
}

if (!defined($local_ip)) {
    $local_ip = `/sbin/ifconfig eth0 | grep 'inet ' | awk '{print \$2}' | awk -F : '{print \$2}'`;
    chomp $local_ip;
}

if (!defined($load_port)) {
    $load_port = "5095";
}

if (!defined($test_port)) {
    $test_port = "5099";
}

if (!defined($load_media_port)) {
    $load_media_port = "10025";
}

if (!defined($test_media_port)) {
    $test_media_port = "10029";
}

# Kill the previous test first if any and remove old logs
&waitProcessKill(0, "$sipp", "hls_perf.xml");
&waitProcessKill(0, "$sipp", "test_hls.xml");

if (-d "current") {
    print "WARNING: previous log directory (current) is found! Rename or remove it before launch test again.\n\n";
    exit 1;
} else {
    mkdir "current";
}

foreach $concurrent (@concurrent_list) {
    # First $load_duration, we wait for load part to reach peak
    # Test duration, we wait for test part to complete
    # Second $load_duration, we wait for load part to clean up
    my $full_test_duration = $load_duration + $test_samples * $test_duration + $load_duration;
    my $max_calls = $concurrent * $full_test_duration;
    my $cur_calls = $concurrent * ($load_duration * 1.1);

    print "\nTest started for $concurrent concurrent calls!\n";
    print "Full test durtion: $full_test_duration\n";
    print "Overall load calls: $max_calls\n";
    print "Peak calls: $cur_calls\n";

    # Background load UAC
#    for sipp v3.0
#    my $cmd = "$sipp -sf load.xml -mp $load_media_port -i $local_ip -p $load_port -r $concurrent -m $max_calls $remote_ip:$remote_port -trace_screen -bg";
#    for sipp v3.1
    my $cmd = "$sipp $load_remote_ip:$load_remote_port -s dialog -sf hls_perf.xml -mp $load_media_port -i $local_ip -p $load_port -r $concurrent -rp 1s -l $cur_calls -m $max_calls -trace_screen -trace_stat -bg -nostdin";
    print "$cmd\n";
    system $cmd;
    print "Backgroud load UAC started\n";

    my $sip_messages = $test_samples * $sip_msgs_per_call;
    $cmd = "/usr/sbin/tcpdump -i eth0 -s 1500 -c $sip_messages \\(src host $local_ip and dst host $test_remote_ip and udp[0:2] == $test_port \\) or \\(src host $test_remote_ip and dst host $local_ip and \\(udp[2:2] == $test_port or \\(udp[2:2] == $test_media_port and udp[10:2]=1\\)\\)\\) -w pcap_$concurrent.pcap &";

#    $cmd = "/usr/sbin/tcpdump -i eth0 -s 1500 -c $sip_messages \\(src host $local_ip and dst host $test_remote_ip and \\(udp[0:2] == $test_port or \\(udp[0:2] == $test_media_port and udp[10:2]=1\\)\\)\\) or \\(src host $test_remote_ip and dst host $local_ip and \\(udp[2:2] == $test_port or \\(udp[0:2] == $test_media_port and udp[10:2]=1\\)\\)\\) -w pcap_$concurrent.pcap &";
#    $cmd = "/usr/sbin/tcpdump -A -tt -c $sip_messages \\(src host $local_ip and dst host $test_remote_ip and \\(udp[0:2] == $test_port or \\(udp[0:2] == $test_media_port and udp[10:2]=1\\)\\)\\) or \\(src host $test_remote_ip and dst host $local_ip and \\(udp[2:2] == $test_port or \\(udp[2:2] == $test_media_port and udp[10:2]=1\\)\\)\\) > messages_$concurrent.log &";
    print "$cmd\n";
    system $cmd;
    print "Dump script started\n";

    # Sleep until the backgroud load reach the peak concurrent calls
    print "Now wait for $load_duration seconds\n";
    sleep $load_duration;

    # The test UAC
#    for sipp v3.0
#    $cmd = "$sipp -sf test.xml -mp $test_media_port -i $local_ip -p $test_port -r 1 -m $test_samples $remote_ip:$remote_port -trace_screen -bg";
#   for sipp v3.1
    $cmd = "$sipp $test_remote_ip:$test_remote_port -s dialog -sf test_hls.xml -mp $test_media_port -i $local_ip -p $test_port -r 1 -rp $test_duration"."s -m $test_samples -trace_screen -bg -nostdin";
    print "$cmd\n";
    system $cmd;
    print "The test UAC started\n";

    # Sleep until the test UAC complete
    print "Now wait for $full_test_duration seconds\n";
    sleep $full_test_duration;

    # Sleep until the backgroud load clean up all the calls and leave a gap for next loop of testing
    print "Now wait for 2*$load_duration+60 seconds\n";
    sleep $load_duration;
    sleep $load_duration;
    sleep 60;

    # Kill the sipp process if any and backup the logs
    &waitProcessKill(0, "$sipp", "load.xml", 1);
    &waitProcessKill(0, "$sipp", "test.xml", 1);
    &waitProcessKill(0, "tcpdump");

    &mvFile ("load_*_screen.log", "current/load_screen_$concurrent.log");
#    &mvFile ("load_*_errors.log", "current/load_errors_$concurrent.log");
    &mvFile ("load*_.csv", "current/load_stat_$concurrent.csv");
    &mvFile ("test_*_screen.log", "current/test_screen_$concurrent.log");
#    &mvFile ("test_*_errors.log", "current/test_errors_$concurrent.log");
#    &mvFile ("test_*_messages.log", "current/test_messages_$concurrent.log");
    print "Test completed for $concurrent concurrent calls.\n";

    system ("/usr/sbin/tshark -r pcap_$concurrent.pcap > messages_$concurrent.log");
#    system ("./result.pl messages_$concurrent.log > latency_$concurrent.csv");

#    &mvFile ("latency_$concurrent.csv", "current/latency_$concurrent.csv");
    &mvFile ("messages_$concurrent.log", "current/messages_$concurrent.log");
    &mvFile ("pcap_$concurrent.pcap", "current/pcap_$concurrent.pcap");
    print "Result generated for $concurrent concurrent calls.\n";
    print "------------------------------------------------\n";
}

print "\nTest all completed. Find result in \"current\" directory.\n\n";

sub mvFile()
{
    my $srcFile = shift;
    my $dstFile = shift;

    if (!defined($dstFile)) {
        return;
    }

    system ("if [ -f $srcFile ]; then mv -f $srcFile $dstFile; fi");
}

sub waitProcessKill()
{
    my $maxLoops = shift;
    my $process = shift;
    my $name = shift;
    my $screen = shift;

    if (!defined($process)) {
        print "Invalid process name!\n";
        exit 1;
    }
    # Sleep a little while in case the previous process is not launched yet
    # sleep 10;

    my $number = 0;
    my $i = 0;

    while(1) {
        if (defined($name)) {
            $number = `ps -efww | grep $process | grep $name | grep -v grep | wc -l`;
        } else {
            $number = `ps -efww | grep $process | grep -v grep | wc -l`;
        }

        if ($number <= 0) {
            return;
        }
        if (++$i > $maxLoops) {
            last;
        }
        sleep 60;
    }

    $kill = "kill.sh";

    # Dump screen of sipp process?
    if (defined($screen)) {
        system ("ps -efw | grep $process|grep $name|grep -v grep|awk '{printf \"kill -SIGUSR2 %s; kill -9 %s\\n\", \$2, \$2}' > $kill");
    } else {
        system ("ps -efw | grep $process|grep $name|grep -v grep|awk '{printf \"kill -9 %s\\n\", \$2}' > $kill");
    }
    system ("chmod +x $kill");
    system ("./$kill");
    system ("rm -f $kill");
}
