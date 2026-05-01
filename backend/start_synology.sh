#!/bin/sh
# Zeiterfassung Backend – Synology Task Scheduler Script
# Eintragen unter: Systemsteuerung → Aufgabenplaner → Erstellen → Benutzerdefiniertes Skript
# Aufgabentyp: Beim Systemstart ausführen

sleep 30

NODE=/volume1/@appstore/Node.js_v20/usr/local/bin/node
APP_DIR=/volume1/Gurktaler/zeiterfassung/backend
LOG=$APP_DIR/server.log
DATA_DIR=$APP_DIR/data

export API_KEY="ZE-Gurktaler-2026"
export DATA_DIR=$DATA_DIR
export PORT=3000

cd $APP_DIR
$NODE server.js >> $LOG 2>&1 &

echo "Zeiterfassung Backend gestartet (PID $!)" >> $LOG
