# Roadmap aktualisieren

Aktualisiere die Datei `ROADMAP.md` im Projektroot basierend auf dem aktuellen Stand des Repositories.

## Schritte

1. Lies die aktuelle `ROADMAP.md`
2. Führe `git log --oneline -20` aus um jüngste Commits zu sehen
3. Führe `git diff main...HEAD --stat` aus (oder `git log main..HEAD --oneline` falls kein diff verfügbar)
4. Prüfe welche Dateien neu sind oder sich geändert haben:
   - Neue Models/Services/Screens → neue Features dokumentieren
   - Geänderte bestehende Dateien → ggf. Verbesserungen vermerken
5. Schreibe die ROADMAP.md neu:
   - Verschiebe abgeschlossene Punkte von "Offen" nach "Erledigt"
   - Füge neue erledigte Features unter der passenden Version ein
   - Aktualisiere "In Arbeit" mit realistischen nächsten Schritten
   - Passe Architektur-Notizen an (neue Dateien, DB-Versionen, Branches)
   - Setze das Datum "Letztes Update" auf heute
6. Committe die aktualisierte ROADMAP.md mit Message `docs: update roadmap`

## Wichtige Hinweise

- Keine neuen Features implementieren – nur dokumentieren was existiert
- Einschränkungen ehrlich und vollständig halten
- Branches-Abschnitt auf den aktuellen Branch aktualisieren
- "Langfristig / Ideen" nur bei expliziten Nutzer-Wünschen ergänzen
