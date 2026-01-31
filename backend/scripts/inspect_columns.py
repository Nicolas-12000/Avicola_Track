import sqlite3, json, sys

db = r'C:/Users/nicolas/Desktop/proyectos/Avicola_Track/backend/avicolatrack/db.sqlite3'
try:
    conn = sqlite3.connect(db)
    cur = conn.execute("PRAGMA table_info('alarms_alarmconfiguration')")
    cols = list(cur.fetchall())
    print(json.dumps(cols, indent=None))
finally:
    try:
        conn.close()
    except:
        pass
