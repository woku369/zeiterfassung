#!/bin/sh
# Detached restart script – wird vom /api/restart Endpoint gestartet.
# Läuft als eigenständiger Prozess; 2s Pause damit die HTTP-Response
# noch ausgeliefert wird, bevor der alte Node-Prozess gekillt wird.

sleep 2

LOG=/volume1/Gurktaler/zeiterfassung/backend/server.log

echo "$(date '+%Y-%m-%d %H:%M:%S'): [RESTART] Neustart via API angefordert" >> "$LOG"

# Alten Prozess auf Port 3000 beenden
PID=$(netstat -tlnp 2>/dev/null | grep ':3000 ' | awk '{print $7}' | cut -d/ -f1)
if [ -n "$PID" ]; then
  kill "$PID" 2>/dev/null
  sleep 1
fi

# Neuen Server starten
NODE=/var/packages/Node.js_v20/target/usr/local/bin/node
APP_DIR=/volume1/Gurktaler/zeiterfassung/backend

export API_KEY="ZE-Gurktaler-2026"
export DATA_DIR="$APP_DIR/data"
export PORT=3000

cd "$APP_DIR"
$NODE server.js >> "$LOG" 2>&1 &

echo "$(date '+%Y-%m-%d %H:%M:%S'): [RESTART] Neugestartet (PID $!)" >> "$LOG"
