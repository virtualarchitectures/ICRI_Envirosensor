#!/bin/bash
# Wrapper to control envirosensor python script

start() {
  	echo "start iotkit-agent"
	systemctl start iotkit-agent

	echo "running script as user: root"
	su -c "source /home/root/miniconda2/bin/activate root ; python /home/root/envirosensor.py" -m "root"
}

stop() {
	systemctl stop iotkit-agent
	killall python
}

case $1 in
  start|stop) "$1" ;;
esac