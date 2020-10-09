#!/bin/bash
#
# Script to search incoming mail messages for PROBLEM Alerts and dispatch alerts to MQTT
# and invoke home automation actions for waking my ass up at 3AM.  Set in crontab to run every minute.
# 
# Dependencies:
# 1) MQTT Push Client  - if you want notifications to go to your iPhone
# 2) fetchmail - install and configure fetchmail to pickup mail of interest from a gmail box or whatever
# 3) mosquitto-client - install on the same host that this script will run.  Used for performing dispatch
#    of alerts as well as invoking actions through your home automation system (via MQTT) to help get you 
#    out of bed at those nasty hours.
# 
# John Rogers   10/9/20
#

# Globals
alert=""
count="0"
threshold="10"
mqttHost=""
mqttUser=""
mqttPasswd=""
mqttAlertTopic="alerts/oncall"
mqttActionTopic="domoticz/in"
mqttAction=""
mailFile=""
scanFor=`/usr/bin/grep -i 'problem alert' $mailFile | cut -d' ' -f3- | grep 'CRITICAL'`

# Perform an action via MQTT such as turning on a light, buzzer, etc
wakeUp() {
mosquitto_pub -u $mqttUser -P $mqttPasswd -h $mqttHost -p 1883 -t $mqttActionTopic -m "${mqttAction}"
}

# Dispatch a copy of alerts via MQTT to MQTT Push Client on iPhone
dispatch() {
mosquitto_pub -u $mqttUser -P $mqttPasswd -h $mqttHost -p 1883 -t $mqttAlertTopic -m "${alert}"
}

# Clear the mail file when we're done processing
resetAlerts() {
reset=`> $mailFile`
reset
exit 0;
}

# Check alerts and decide if threshold warrants wakeup action
checkAlerts() {
cd /var/mail/.

while IFS= read -r alert
do
 if [ $count -lt $threshold ]; then
   break
 else
   dispatch;
 fi
done < <($scanFor)

if [ $count -lt $threshold ]; then
   break
 else
   wakeUp;
fi
}

# Count the number alerts to determing threshold.  
countAlerts() {
 cd /var/mail/.
 count=`$scanFor | wc -l`
 checkAlerts
}

# Main calls
countAlerts
resetAlerts
