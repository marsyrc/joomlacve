#!/bin/bash
redis-server --daemonize yes
./start.sh 

flagCont=ea6b2efbdd4255a9f1b3bbc6399b58f4
connectRes=$(redis-cli -h $1 -p $2 -a $3 set "container_flag_$4_$5" $flagCont)
if [ "$connectRes" = 'OK' ]
then
/bin/bash
else
echo "Connection Failed"
fi

tail -f /dev/null
