# Build – Zeiterfassung APK + Windows

Führt das Build-Script auf dem Windows-Entwicklungsrechner aus.

## Build-Script

Datei: `C:\Users\wolfg\zeiterfassung\build.ps1`

## Aufruf

```powershell
# APK + Windows (Standard)
C:\Users\wolfg\zeiterfassung\build.ps1

# Nur APK
C:\Users\wolfg\zeiterfassung\build.ps1 -ApkOnly

# Nur Windows-EXE
C:\Users\wolfg\zeiterfassung\build.ps1 -WindowsOnly

# Ohne git pull (wenn Branch noch nicht gepusht)
C:\Users\wolfg\zeiterfassung\build.ps1 -NoPull

# flutter clean davor
C:\Users\wolfg\zeiterfassung\build.ps1 -Clean
```

## Was das Script macht

1. `git pull` auf aktuellem Branch
2. versionCode in `pubspec.yaml` automatisch inkrementieren
3. `flutter pub get`
4. `flutter build apk --release` → `builds\zeiterfassung-DATUM-bNR.apk`
5. `flutter build windows --release` → `builds\zeiterfassung-DATUM-windows.zip`

## Hinweise

- Ausgabe landet in `zeiterfassung\builds\`
- Nach dem Build: APK per USB/ADB auf Poco X7 Pro + Doogee U11 Pro installieren
- Windows-ZIP auf Home-PC entpacken und `zeiterfassung.exe` starten
- NAS-Neustart ist nach einem reinen App-Build **nicht** nötig
