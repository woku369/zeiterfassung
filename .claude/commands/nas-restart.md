# /nas-restart – NAS-Backend neu starten

Startet das Zeiterfassung-Backend auf dem Synology NAS DS124 neu.

---

## Kontext

- **NAS:** DS124-RockingK · LAN `192.168.0.9` · Tailscale `100.121.103.107` · User `Wolfgang`
- **App-Verzeichnis:** `/volume1/Gurktaler/zeiterfassung/backend`
- **Node.js:** `/var/packages/Node.js_v20/target/usr/local/bin/node`
- **Port:** 3000
- **API-Key:** `ZE-2026` (gesetzt in `start_synology.sh` und beim manuellen Start)
- **Kein Docker**, kein pm2 – reiner Node.js-Prozess

## Bekannte Fallen

- Aufgabenplaner startet Server als `admin` → `pkill` ohne sudo schlägt fehl
- `sudo` über SSH braucht TTY → `ssh -t` verwenden
- Mehrere Node-Prozesse möglich → alle killen bevor neu starten
- `ss` nicht verfügbar auf Synology → `netstat` verwenden

---

## Prozedur

### Schritt 1 – Alle Node-Prozesse beenden (braucht sudo)

```powershell
ssh -t Wolfgang@192.168.0.9 "sudo pkill -f 'node server.js'"
```

Zweimal Passwort eingeben: erst SSH-Passwort, dann sudo-Passwort (= NAS-Passwort).
Kein Output = Erfolg. Verbindung schließt sich automatisch.

---

### Schritt 2 – Server neu starten

```powershell
ssh Wolfgang@192.168.0.9 "export API_KEY='ZE-2026' DATA_DIR=/volume1/Gurktaler/zeiterfassung/backend/data PORT=3000 && cd /volume1/Gurktaler/zeiterfassung/backend && nohup /var/packages/Node.js_v20/target/usr/local/bin/node server.js >> server.log 2>&1 & sleep 3 && tail -3 /volume1/Gurktaler/zeiterfassung/backend/server.log"
```

**Erwartete Ausgabe (Erfolg):**
```
Zeiterfassung Backend läuft auf Port 3000
API_KEY: *** (gesetzt)
DATA_DIR: /volume1/Gurktaler/zeiterfassung/backend/data
```

---

### Schritt 3 – Sync in der App auslösen

Einstellungen → Synchronisation → Jetzt synchronisieren.
Bei 401-Fehler: API-Key in App-Einstellungen auf `ZE-2026` prüfen.

---

## Diagnose bei Problemen

**Server antwortet nicht:**
```powershell
ssh Wolfgang@192.168.0.9 "netstat -tlnp 2>/dev/null | grep 3000"
```

**Tailscale-Verbindung prüfen:**
```powershell
ssh Wolfgang@192.168.0.9 "/var/packages/Tailscale/target/bin/tailscale ping 100.105.240.22"
```

**Laufende Node-Prozesse anzeigen:**
```powershell
ssh Wolfgang@192.168.0.9 "ps aux | grep 'node server' | grep -v grep"
```

**Server-Log (letzte 10 Zeilen):**
```powershell
ssh Wolfgang@192.168.0.9 "tail -10 /volume1/Gurktaler/zeiterfassung/backend/server.log"
```

---

## Wann ist ein Neustart nötig?

- Nach Änderungen an `backend/server.js`
- Wenn die App Sync-Fehler meldet und Tailscale läuft
- **Nicht nötig** nach reinen App-Builds (Flutter läuft auf dem Gerät)
