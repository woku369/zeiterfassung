#!/bin/sh
# Zeiterfassung DB-Backup – täglich per Aufgabenplaner ausführen
# Aufgabentyp: Geplante Aufgabe → täglich z.B. 03:00 Uhr

APP_DIR=/volume1/Gurktaler/zeiterfassung/backend
BACKUP_DIR=$APP_DIR/data/backups
DB=$APP_DIR/data/zeiterfassung.db

mkdir -p $BACKUP_DIR

# Tages-Backup (SQLite WAL-safe copy)
sqlite3 $DB ".backup '$BACKUP_DIR/zeiterfassung_$(date +%Y%m%d).db'"

# Nur die letzten 30 Backups behalten
ls -t $BACKUP_DIR/zeiterfassung_*.db | tail -n +31 | xargs rm -f

echo "Backup fertig: $(date)" >> $APP_DIR/backup.log
