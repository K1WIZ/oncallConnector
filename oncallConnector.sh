#!/bin/bash
#
# Script to search incoming mail messages for PROBLEM Alerts and dispatch alerts to MQTT
# and invoke HA actions for waking my ass up at 3AM.  Set in crontab to run every minute.
# 
# John Rogers   10/10/20
#

# Globals
alert=""
count="0"
threshold="1"
mqttHost=""
mqttUser=""
mqttPasswd=""
mqttAlertTopic="alerts/oncall"
mqttActionTopic="domoticz/in"
mqttAction=`echo -e "{\"command\": \"switchlight\", \"idx\": 50, \"switchcmd\": \"On\" }"`
mailFile=""

# Location to scan for relevant messages
scanFor() {
mail -p | grep -e 'WARNING' -e 'CRITICAL'
}

# Perform an action via MQTT such as turning on a light, buzzer, etc
wakeUp() {
mosquitto_pub -u $mqttUser -P $mqttPasswd -h $mqttHost -p 1883 -t $mqttActionTopic -m "${mqttAction}"
}

# Dispatch a copy of alerts via MQTT to MQTT Push Client on iPhone
dispatch() {
mosquitto_pub -u $mqttUser -P $mqttPasswd -h $mqttHost -p 1883 -t $mqttAlertTopic -m "${alert}"
}

# Support for Pushover - populate your user key and token
pushOver() {
curl -s \
  --form-string "token=" \
  --form-string "user=" \
  --form-string "message=${alert}" \
  --form-string "title=ONCALL PAGE" \
  --form-string "sound=persistent" \
  --form-string "priority=2" \
  --form-string "retry=60" \
  --form-string "expire=7200" \
  https://api.pushover.net/1/messages.json
}

pageMe() {
#alertPage=`echo $alert | cut -c 1-80`
#echo $alertPage
/home/john/sendPage.sh -m "${alert}";
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
   pageMe;
   pushOver;
 fi
done < <(scanFor)

if [ $count -lt $threshold ]; then
   break
 else
   wakeUp;
#   pageMe;
fi
}

# Count the number alerts to determine threshold.  
countAlerts() {
cd /var/mail/.
count=`scanFor | wc -l`
checkAlerts
}

# Main calls
countAlerts
resetAlerts
exit 0;
