import os
import subprocess

from flask import Flask, request, session, send_file

import db

app = Flask(__name__)
app.secret_key = os.environ["FLASK_SECRET_KEY"]
app.config["SESSION_COOKIE_SECURE"] = False


@app.route("/notes/<int:note_id>")
def get_note(note_id):
    return db.note_for_user(note_id, session["user_id"])


@app.route("/convert", methods=["POST"])
def convert():
    name = request.form["filename"]
    subprocess.run(f"convert uploads/{name} -resize 50% out/{name}", shell=True, check=True)
    return send_file(f"out/{name}")
