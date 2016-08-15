#!/bin/bash -l
# expect: loadmath.sh master.fqdn dataport messageport path/to/math options_to_math
MASTER_FQDN=$1
MAIN_LINK_DATA_PORT=$2
MAIN_LINK_MESSAGE_PORT=$3
MATH_EXEC=$4
SSH_OPTS="-C -x -n -T -A -N -o CheckHostIP=no -o StrictHostKeyChecking=no -o ControlMaster=no -o ServerAliveInterval=20"
LOOPBACK_IP_ADDR="127.0.0.1"
echo "all opts: $@"
MATH_PARAMS=$(echo $@ | cut -d" " -f5-)

echo "worker: $(hostname -f)"

SSH_OPTS="$SSH_OPTS -L $MAIN_LINK_DATA_PORT:$LOOPBACK_IP_ADDR:$MAIN_LINK_DATA_PORT"
SSH_OPTS="$SSH_OPTS -L $MAIN_LINK_MESSAGE_PORT:$LOOPBACK_IP_ADDR:$MAIN_LINK_MESSAGE_PORT"

# remove Mathematica SystemFiles/Libraries dir from LD_LIBRARY_PATH
# the libcrypto.so in SystemFiles/Libraries may be incompatible with /usr/bin/ssh
if [ -n "$LD_LIBRARY_PATH" ]
then
        export LD_LIBRARY_PATH=`echo $LD_LIBRARY_PATH | awk -v RS=: -v ORS=: '/SystemFiles\/Libraries/ {next} {print}'`
fi

# insert destination
SSH_OPTS="$SSH_OPTS $MASTER_FQDN"

# debug output
echo "> ssh $SSH_OPTS &"
ssh $SSH_OPTS &
sleep 1
ps axu | grep ssh

echo "> $MATH_EXEC $MATH_PARAMS"
$MATH_EXEC $MATH_PARAMS
