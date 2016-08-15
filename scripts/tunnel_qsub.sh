#!/bin/bash -l
# script that qsubs a mathematica SubKernel to the Sun Grid Engine
# this script was largely inspired by the Tunnel-method of Sascha Kratky, c.f. https://github.com/sakra/Tunnel
# call like: ./tunnel_qsub.sh path/to/math linkname path/to/log qsub_arguments

cd "`dirname \"$0\"`"

if [ -n "$3" ]
then
  LOG_PATH=$3
else
  LOG_PATH="$PWD/Logs"
fi

if [ -z "$LOGFILE" ]
then
	# log file with unique name for each invocation
	mkdir -p "$LOG_PATH/`date \"+%Y-%m-%d\"`"
	LOGFILE="$LOG_PATH/`date \"+%Y-%m-%d\"`/`basename \"$0\" .sh`_`date \"+%Y-%m-%d-%H%M%S\"`_$$.log"
fi

echo `hostname` `date` >> $LOGFILE
echo $0 $@ >> $LOGFILE
echo "\$2=$3" >> $LOGFILE

# check arguments
if [ "$#" -lt "2" ]
then
	echo "Usage: $0 [user[:password]@]host[:port] path_to_mathematica_kernel linkname" >> $LOGFILE
	exit 1
fi

REMOTE_KERNEL_PATH=$1
LINK_NAME=$2

QSUB_PATH=qsub
SSH_PATH=/usr/bin/ssh
LOAD_MATH_SCRIPT_PATH=tunnel_qsub_loadmath.sh

if [ ! -x "$SSH_PATH" ]
then
	echo "Error: OpenSSH client $SSH_PATH does not exist or is not executable." >> $LOGFILE
	exit 1
fi

# parse port link name port numbers, e.g., 53994@127.0.0.1,39359@127.0.0.1
MAIN_LINK_DATA_PORT=`echo $LINK_NAME | awk -F "[,@]" '{print $1}'`
MAIN_LINK_HOST=`echo $LINK_NAME | awk -F "[,@]" '{print $2}'`
MAIN_LINK_MESSAGE_PORT=`echo $LINK_NAME | awk -F "[,@]" '{print $3}'`

if [ -z "$MAIN_LINK_DATA_PORT" -o -z "$MAIN_LINK_MESSAGE_PORT" ]
then
	echo "Error: $LINK_NAME is not a properly formatted MathLink TCPIP protocol link name!" >> $LOGFILE
	exit 1
fi

# test if MAIN_LINK_HOST is an IPv6 address
if echo $MAIN_LINK_HOST | grep -q ":"
then
	# SSH requires IPv6 address to be enclosed in square brackets
	MAIN_LINK_HOST="[$MAIN_LINK_HOST]"
fi

LOOPBACK_IP_ADDR="127.0.0.1"
MAIN_LINK_LOOPBACK="$MAIN_LINK_DATA_PORT@$LOOPBACK_IP_ADDR,$MAIN_LINK_MESSAGE_PORT@$LOOPBACK_IP_ADDR"

if [ "$MAIN_LINK_HOST" != "$LOOPBACK_IP_ADDR" ]
then
	echo "Warning: $LINK_NAME does not use the loopback IP address $LOOPBACK_IP_ADDR!" >> $LOGFILE
fi

# SSH options
# -C enable compression
# -v verbose mode
# -x disable X11 forwarding
# -n prevent reading from stdin
# -T disable pseudo-tty allocation
# -A enable SSH agent forwarding
SSH_OPTS="-C -v -x -n -T -A -o CheckHostIP=no -o StrictHostKeyChecking=no -o ControlMaster=no -o ServerAliveInterval=20"

# QSUB options
# - specify log dir for QSUB
QSUB_OPTS="$QSUB_OPTS -e $LOG_PATH -o $LOG_PATH"

# - append user options
QSUB_OPTS="$QSUB_OPTS $(echo $@ | cut -d" " -f4-)"

# set up remote port forwardings for kernel main link
SSH_OPTS="$SSH_OPTS -R $LOOPBACK_IP_ADDR:$MAIN_LINK_DATA_PORT:$MAIN_LINK_HOST:$MAIN_LINK_DATA_PORT"
SSH_OPTS="$SSH_OPTS -R $LOOPBACK_IP_ADDR:$MAIN_LINK_MESSAGE_PORT:$MAIN_LINK_HOST:$MAIN_LINK_MESSAGE_PORT"

REMOTE_KERNEL_OPTS="-mathlink"
REMOTE_KERNEL_OPTS="$REMOTE_KERNEL_OPTS -LinkMode Connect -LinkProtocol TCPIP -LinkName $MAIN_LINK_LOOPBACK"

# Mathematica kernel options
# -lmverbose print information to stderr on connecting to the license manager
REMOTE_KERNEL_OPTS="$REMOTE_KERNEL_OPTS -lmverbose"

# compute kernel specific options
# the Remote Kernels connection method requires the launch command to return immediately
# thus we are adding option -f to launch SSH client as a background process
SSH_OPTS="$SSH_OPTS -f"
# compute kernel needs -subkernel switch
REMOTE_KERNEL_OPTS="$REMOTE_KERNEL_OPTS -subkernel -noinit"
# no local port forwardings required for compute kernels

# remove Mathematica SystemFiles/Libraries dir from LD_LIBRARY_PATH
# the libcrypto.so in SystemFiles/Libraries may be incompatible with /usr/bin/ssh
if [ -n "$LD_LIBRARY_PATH" ]
then
	export LD_LIBRARY_PATH=`echo $LD_LIBRARY_PATH | awk -v RS=: -v ORS=: '/SystemFiles\/Libraries/ {next} {print}'`
fi

# log everything
echo "REMOTE_KERNEL_PATH=$REMOTE_KERNEL_PATH" >> $LOGFILE
echo "REMOTE_KERNEL_OPTS=$REMOTE_KERNEL_OPTS" >> $LOGFILE
echo "LINK_NAME=$LINK_NAME" >> $LOGFILE
echo "MAIN_LINK_HOST=$MAIN_LINK_HOST" >> $LOGFILE
echo "MAIN_LINK_DATA_PORT=$MAIN_LINK_DATA_PORT" >> $LOGFILE
echo "MAIN_LINK_MESSAGE_PORT=$MAIN_LINK_MESSAGE_PORT" >> $LOGFILE
echo "MAIN_LINK_LOOPBACK=$MAIN_LINK_LOOPBACK" >> $LOGFILE
echo "SSH_PATH=$SSH_PATH" >> $LOGFILE
echo "SSH_OPTS=$SSH_OPTS" >> $LOGFILE
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> $LOGFILE
echo "QSUB_PATH=$QSUB_PATH" >> $LOGFILE
echo "QSUB_OPTS=$QSUB_OPTS" >> $LOGFILE
echo "PWD=$PWD" >> $LOGFILE

# qsub the startup-script
COMMAND="$QSUB_PATH $QSUB_OPTS $LOAD_MATH_SCRIPT_PATH $(hostname -f) $MAIN_LINK_DATA_PORT $MAIN_LINK_MESSAGE_PORT $REMOTE_KERNEL_PATH $REMOTE_KERNEL_OPTS"
echo $COMMAND >> $LOGFILE 2>&1
$COMMAND >> $LOGFILE 2>&1
