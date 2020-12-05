#!/bin/bash
#
# Script to send a message to pi-star software which runs as a pocsag pager transmitter for localized paging to any pocsag pager.
#
# NOTE: callsign value is optional and not needed unless you are going to use the "hampager" network. (commented out by default)
#

callsign=""
message=""
# Enter your pager's RIC code here.  Most pagers have pre-programmed or programmable RIC codes.
RIC="0125360"

# Send weather info option from my Domoticz home automation dashboard (when desired).  Only runs if called.
wx=`curl -s 'http://10.2.50.5:8080/json.htm?type=devices&rid=6' | jq .result[0].Data | sed 's/\"//g' | awk '{ print "Current Conditions - Temperature: "$1"F   Humidity: "$3"%   Pressure: "$5" hPa" }'`

sendIt() {
#curl -H "Content-Type: application/json" -X POST -u <dapnet user>:<dapnet password> -d '{ "text": "'"$message"'", "callSignNames": ["'"$callsign"'"], "transmitterGroupNames": ["us-ma"], "emergency": false }' http://www.hampager.de:8080/calls
message=`echo $message | cut -c -80 | sed "s:['\"\(\)]::g"`
# Send to transmitter running pi-star software (free download) after copying SSH keys to pi-star host.  Change IP for your environment.
ssh pi-star@10.1.73.73 RemoteCommand 7642 page $RIC "${message}"
}

while getopts ":wh:m:" option; do
   case "${option}" in
      m) message=${OPTARG};;
      c) callsign=${OPTARG};;
      w) message=$wx;;
      h) help;;
      *) help
         exit;;
   esac
done
if [ $# -eq 0 ]
   then
      echo -e "USAGE: sendPage.sh -m \"<message>\"";
      exit 0;
fi


sendIt
exit 0;
