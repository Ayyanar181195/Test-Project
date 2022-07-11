#!/bin/bash
#
# This script starts SIPp UAS processes.
export PATH=.:$PATH

# Remove old SIPp logs
rm -f *.log || :

# SIPp Installation directory: "F:\Program Files\SIPp\sipp.exe"
# By default, this directory should be included in cygwin env $PATH. If not,
# Uncomment the following line for the full path.
#SIPP_CMD="/cygdrive/f/Program\ Files/SIPp/sipp.exe"
SIPP_CMD="./sipp"
typeset -i port=5070
typeset -i numOfMCPs=1
typeset -i count=0
background=false

# Parse command line arguments
# Arguments are optional.  
while [ $# -gt 0 ]; do
    case $1 in
        -n)
            numOfMCPs=$2
            shift; shift
            ;;
        -p)
            port=$2
            shift; shift
            ;;
        -bg)
            background=true
            shift; 
            ;;
        *)
            echo "Usage: $0 [-n number_of_MCPs ] [-p port_number] [-bg]"
            exit 1
            ;;
    esac
done

# Start number of SIPp, with auto-incremented port number
while [ $count -lt $numOfMCPs ]  
do 
	BGPID=`$SIPP_CMD  -bg -sf mcp_sim.xml -p $port -trace_logs -trace_screen -skip_rlimit`
	# The output format:
	# Background mode - PID=[480]
	BGPID=${BGPID/Background mode - PID=[/}
	BGPID=${BGPID/]/}
	echo Started SIPp, PID: $BGPID
	let count=count+1
	let port=port+1
	sleep 1
done

# Run in background
if [ $background ] ; then
	echo SIPp instances started in background.
	exit 0
fi

echo Press Control-C to stop all SIPp instances...
cmd >/dev/null
wait
exit 0
