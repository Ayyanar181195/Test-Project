#!/bin/bash
# run sipp test CentOs5, arg1= test-name [arg2= mcp_ip_port]
if [ -z $1 ]; then 
echo test-name not defined
exit 1
fi
if [ -z $2 ]; then mcp_ip_port="172.24.130.139:5070"; else mcp_ip_port=$2; fi
local_machine="135.17.224.230"
# rm -f *.log
test=$1
/sipp/sipp.test/./sipp -sf $test-a.xml $mcp_ip_port -i 172.24.131.34 -m 1 -trace_msg
#-----------------------
# killall -SIGUSR2 sipp 
# killall -9 sipp 
# echo Done $test
