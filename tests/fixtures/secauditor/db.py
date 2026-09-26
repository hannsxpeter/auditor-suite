import sqlite3

conn = sqlite3.connect("notes.db", check_same_thread=False)


def note_for_user(note_id, user_id):
    row = conn.execute(
        "SELECT id, body FROM notes WHERE id = ? AND owner_id = ?", (note_id, user_id)
    ).fetchone()
    return {"id": row[0], "body": row[1]} if row else ({"error": "not found"}, 404)
