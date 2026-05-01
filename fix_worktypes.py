"""
Korrigiert falsch zugeordnete work_type-Werte in der Datenbank.

"Mobil" aus Stempeluhr 2.1 wurde fälschlich als 'travel' (Fahrt) importiert.
Richtig: 'offsite' (Außer-Haus). Echte Fahrten haben distance_km oder travel_minutes > 0.

Aufruf: python fix_worktypes.py "C:\...\zeiterfassung.db"
"""

import sqlite3, sys
from pathlib import Path

if len(sys.argv) < 2:
    print("Aufruf: python fix_worktypes.py <pfad_zur_zeiterfassung.db>")
    sys.exit(1)

db_path = Path(sys.argv[1])
if not db_path.exists():
    print(f"Datenbank nicht gefunden: {db_path}")
    sys.exit(1)

con = sqlite3.connect(db_path)
cur = con.cursor()

# travel-Einträge ohne Fahrtdaten → offsite
cur.execute("""
    SELECT COUNT(*) FROM time_entries
    WHERE work_type = 'travel'
      AND (distance_km IS NULL OR distance_km = 0)
      AND (travel_minutes IS NULL OR travel_minutes = 0)
""")
count = cur.fetchone()[0]
print(f"Einträge 'travel' ohne Fahrtdaten: {count} → werden zu 'offsite'")

cur.execute("""
    UPDATE time_entries
    SET work_type = 'offsite', is_synced = 0
    WHERE work_type = 'travel'
      AND (distance_km IS NULL OR distance_km = 0)
      AND (travel_minutes IS NULL OR travel_minutes = 0)
""")
print(f"Korrigiert: {cur.rowcount} Einträge")

# Übersicht was jetzt in der DB ist
cur.execute("SELECT work_type, COUNT(*) FROM time_entries GROUP BY work_type ORDER BY COUNT(*) DESC")
print("\nAktuelle Verteilung:")
for row in cur.fetchall():
    print(f"  {row[0]:20s} {row[1]:4d}")

con.commit()
con.close()
print("\nFertig.")
