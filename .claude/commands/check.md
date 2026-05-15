# /check – Qualitätssicherung, Bugfixes, Docs, Commit

Führe folgende Schritte der Reihe nach aus. Überspringe einen Schritt nur wenn er
eindeutig nicht relevant ist (z.B. keine Docs-Änderung wenn sich nur Backend-Code
geändert hat).

---

## 1. Kontext ermitteln

```bash
git log --oneline -15
git diff main...HEAD --stat
```

Lies die geänderten Dateien grob durch um zu verstehen was sich seit dem letzten
`main`-Stand geändert hat.

---

## 2. Bug-Suche

Prüfe alle seit `main` geänderten Dart-, Kotlin- und JS-Dateien auf:

- **Null-Safety:** `!`-Operator auf Variablen die noch null sein könnten
- **Timer-Leaks:** Timer die nicht in allen Exit-Pfaden gecancelt werden
- **Typ-Casts:** unsichere Casts ohne Fallback (besonders MethodChannel-Ergebnisse)
- **Race Conditions:** SharedPreferences-Zugriffe aus mehreren Isolates
- **Logikfehler:** State-Flags die nicht in allen Zweigen zurückgesetzt werden
- **DB-Schema:** Background-Isolate schreibt Felder die nicht in der Tabelle existieren
- **Unvollständige Fehlerbehandlung:** fehlende `try/catch` an Netzwerk- oder DB-Aufrufen

Für jeden gefundenen Bug: **sofort fixen**, kurz kommentieren was das Problem war.

---

## 3. Versions- und Schema-Konsistenz

- DB-Version in `database_helper.dart` (`_kDbVersion`) mit der Anzahl tatsächlicher
  Migrations-Stufen abgleichen
- Neue Tabellen/Spalten in `_create()` UND in `_upgrade()` vorhanden?
- `pubspec.yaml`-Version bei größeren Features hochzählen (optional, nur wenn
  der Nutzer das explizit möchte)

---

## 4. Handbuch aktualisieren (`help_screen.dart`)

Prüfe ob neue Features eine Handbuch-Sektion brauchen oder bestehende Sektionen
veraltet sind:

- Neue Screens/Features → neue `_Section` anlegen
- Geänderte Workflows → `_KeyValue` / `_Step` / `_Hint` aktualisieren
- Keine technischen Details die den Nutzer nicht interessieren

Beachte: Das Handbuch ist in der App unter dem Tab „Handbuch" erreichbar.

---

## 5. Roadmap aktualisieren (`ROADMAP.md`)

- Erledigte Features in den passenden Versions-Block unter „Erledigt" eintragen
- Bugfixes als Unterlistenpunkte beim betroffenen Block vermerken
- DB-Versionen-Tabelle aktuell halten
- „Letztes Update"-Datum auf heute setzen
- Branch-Version korrigieren falls nötig

---

## 6. Commit & Push

Alle Änderungen (Bugfixes + Docs) in **einem einzigen Commit** zusammenfassen:

```
fix+docs: <kurze Zusammenfassung der wichtigsten Änderungen>

- <Bugfix 1>
- <Bugfix 2>
- docs: <was im Handbuch/Roadmap geändert wurde>
```

Dann pushen:

```bash
git push -u origin <aktueller-branch>
```

---

## Hinweise

- Keine neuen Features implementieren – nur bestehenden Code prüfen und dokumentieren
- Wenn ein Bug unklar ist: kurz beschreiben und den Nutzer fragen bevor fixen
- Wenn keine Bugs gefunden wurden: trotzdem Docs und Roadmap prüfen
- Dieser Workflow ersetzt nicht das Testen auf dem Gerät
