# /nas-restart – NAS-Backend neu starten

Führt den Nutzer Schritt für Schritt durch den Neustart des
Zeiterfassung-Backends auf dem Synology NAS DS124.

---

## Kontext

- **NAS:** DS124-RockingK · IP `192.168.0.9` · User `Wolfgang`
- **App-Verzeichnis:** `/volume1/Gurktaler/zeiterfassung/backend`
- **Node.js:** `/var/packages/Node.js_v20/target/usr/local/bin/node`
- **Port:** 3000
- **Umgebungsvariablen:** `API_KEY=ZE-Gurktaler-2026`, `DATA_DIR=.../data`
- **Kein Docker**, kein pm2 – reiner Node.js-Prozess, gestartet über
  Synology Aufgabenplaner beim Systemstart

## Bekannte Fallen

- `pgrep` ist auf Synology nicht vorhanden → `pgrep -f server.js` schlägt fehl
- `ps` ohne `sudo` zeigt nur eigene Prozesse → root-Prozesse unsichtbar
- `kill` ohne sudo schlägt fehl wenn der Prozess root gehört
- Port 3000 kann noch belegt sein obwohl `ps` keinen Node-Prozess zeigt
  → immer via `netstat` prüfen und mit `sudo` killen

---

## Prozedur

Gib dem Nutzer die folgenden Schritte der Reihe nach aus.
Warte nach jedem Schritt auf die Ausgabe des Nutzers bevor du weitermachst.

### Schritt 1 – SSH-Verbindung öffnen

```powershell
ssh Wolfgang@192.168.0.9
```

Passwort eingeben wenn gefragt.

---

### Schritt 2 – Alten Prozess beenden

```bash
sudo kill $(sudo netstat -tlnp | grep 3000 | awk '{print $7}' | cut -d/ -f1)
```

**Erwartete Ausgaben:**
- Kein Output → Prozess wurde beendet ✓
- `kill: usage: ...` → Port war bereits frei, kein Prozess lief (auch OK)
- Passwort-Prompt → sudo-Passwort eingeben (= NAS-Passwort)

---

### Schritt 3 – In App-Verzeichnis wechseln und Umgebung setzen

```bash
cd /volume1/Gurktaler/zeiterfassung/backend
NODE=/var/packages/Node.js_v20/target/usr/local/bin/node
export API_KEY="ZE-Gurktaler-2026"
export DATA_DIR=/volume1/Gurktaler/zeiterfassung/backend/data
export PORT=3000
```

Kein Output erwartet.

---

### Schritt 4 – Server starten

```bash
$NODE server.js >> server.log 2>&1 &
```

**Erwartete Ausgabe:** `[1] 12345` (PID-Nummer, beliebig)

---

### Schritt 5 – Start bestätigen

```bash
sleep 2 && tail -5 server.log
```

**Erwartete Ausgabe (Erfolg):**
```
DB ready: /volume1/Gurktaler/zeiterfassung/backend/data/zeiterfassung.db
Zeiterfassung Backend läuft auf Port 3000
API_KEY: *** (gesetzt)
DATA_DIR: /volume1/Gurktaler/zeiterfassung/backend/data
```

**Bei Fehler `EADDRINUSE` (Port 3000 noch belegt):**
→ Zurück zu Schritt 2, Port ist noch nicht freigegeben. Kurz warten und wiederholen.

**Bei sonstigem Fehler:**
→ Vollständiges Log anzeigen: `tail -30 server.log`

---

### Schritt 6 – SSH-Verbindung schließen

```bash
exit
```

---

## Wann ist ein Neustart nötig?

- Nach jeder Änderung an `server.js` (kein Hot-Reload)
- Nach `git pull` das `backend/server.js` aktualisiert hat
- Wenn der Server abgestürzt ist (App meldet Sync-Fehler, NAS nicht erreichbar)
- Nicht nötig nach reinen App-Builds (Flutter-Code läuft auf dem Gerät, nicht am NAS)
