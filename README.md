# oncallConnector
a script to invoke actions based on alert input into a mail file.

How to use:
1) setup fetchmail on a machine to grab the contents of a mail folder via IMAP.
2) configure fetchmail to check the mailbox and pull down mail continuously.
3) install mosquitto-clients package on the same linux host that is running fetchmail.
4) populate global variables as appropriate for your needs at the top of the script.
5) setup oncallConnector.sh script in user's crontab to run every minute or as appropriate.

Enjoy reliable alerting and wakeup.

Added improvements:
1) POCSAG actions for sending alerts to an optional POCSAG private paging transmitter. (completed)
2) support for Pushover API (api.pushover.net) - (completed)
