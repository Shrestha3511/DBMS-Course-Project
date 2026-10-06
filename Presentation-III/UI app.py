"""
Project 31: Event Registration and Venue Scheduling System
Presentation-III UI  (Flask + MySQL)

Run:  pip install flask mysql-connector-python
      set DB_PASSWORD below (or env var), then:  python app.py
Open: http://127.0.0.1:5000
Needs 01_DDL.sql, 02_SampleData.sql, 03_Queries_and_Views.sql already run in MySQL.
"""
import os
import mysql.connector
from flask import Flask, request, redirect, url_for, flash, render_template_string

DB = dict(
    host=os.getenv("DB_HOST", "localhost"),
    user=os.getenv("DB_USER", "root"),
    password=os.getenv("DB_PASSWORD", "Iwontforget67"),
    database="event_registration_db",
)

app = Flask(__name__)
app.secret_key = "dbms-project-31"

# ---- lookup labels for foreign-key dropdowns -------------------------------
FK = {
    "category_id": "SELECT category_id, category_name FROM categories",
    "venue_id": "SELECT venue_id, venue_name FROM venues",
    "speaker_id": "SELECT speaker_id, full_name FROM speakers",
    "event_id": "SELECT event_id, event_name FROM events",
    "participant_id": "SELECT participant_id, full_name FROM participants",
    "registration_id": ("SELECT r.registration_id, CONCAT('#', r.registration_id, ' ', p.full_name, ' - ', e.event_name) "
                        "FROM registrations r JOIN participants p USING (participant_id) JOIN events e USING (event_id)"),
    "session_id": ("SELECT s.session_id, CONCAT('#', s.session_id, ' ', e.event_name, ' ', s.session_date) "
                   "FROM sessions s JOIN events e USING (event_id)"),
}

# ---- table config: pk and insertable fields (name, input kind[, options]) --
STATUS = ["confirmed", "cancelled", "waitlisted"]
TABLES = {
    "participants": ("participant_id", [("full_name", "text"), ("email", "email"), ("phone", "text")]),
    "events": ("event_id", [("event_name", "text"), ("category_id", "fk"), ("start_date", "date"), ("end_date", "date")]),
    "sessions": ("session_id", [("event_id", "fk"), ("venue_id", "fk"), ("speaker_id", "fk"),
                                ("session_date", "date"), ("start_time", "time"), ("end_time", "time")]),
    "registrations": ("registration_id", [("participant_id", "fk"), ("event_id", "fk"),
                                          ("registration_date", "date"), ("status", "select", STATUS)]),
    "payments": ("payment_id", [("registration_id", "fk"), ("amount", "number"), ("payment_date", "date"),
                                ("mode", "select", ["cash", "upi", "card", "netbanking"])]),
    "attendance": ("attendance_id", [("registration_id", "fk"), ("session_id", "fk"),
                                     ("status", "select", ["present", "absent"])]),
    "certificates": ("certificate_id", [("registration_id", "fk"), ("issue_date", "date"),
                                        ("eligibility_status", "select", ["eligible", "not eligible"])]),
    "feedback": ("feedback_id", [("registration_id", "fk"), ("session_id", "fk"),
                                 ("rating", "number"), ("comments", "text")]),
    "venues": ("venue_id", [("venue_name", "text"), ("capacity", "number"), ("location", "text")]),
    "speakers": ("speaker_id", [("full_name", "text"), ("expertise", "text"), ("contact", "text")]),
    "coordinators": ("coordinator_id", [("full_name", "text"), ("contact", "text")]),
    "categories": ("category_id", [("category_name", "text")]),
}

REPORTS = {
    "Seats booked per event": "SELECT * FROM vw_event_seats",
    "Revenue per event": "SELECT * FROM vw_event_revenue ORDER BY total_revenue DESC",
    "Attendance summary": "SELECT * FROM vw_attendance_summary",
    "Speaker schedule": "SELECT * FROM vw_speaker_schedule ORDER BY speaker_name, session_date",
    "Certificate eligible (attendance >= 60%)": "SELECT * FROM vw_attendance_summary WHERE attendance_pct >= 60",
}


def run(sql, params=(), fetch=True):
    con = mysql.connector.connect(**DB)
    try:
        cur = con.cursor()
        cur.execute(sql, params)
        if fetch:
            cols = [c[0] for c in cur.description]
            return cols, cur.fetchall()
        con.commit()
        return cur.rowcount
    finally:
        con.close()


PAGE = """
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Event Registration Console</title>
<style>
:root{--ink:#1d2433;--paper:#f6f7f9;--line:#d9dde5;--brand:#1f4e5f;--brand-ink:#fff;--bad:#a8322d;--good:#1f6b43;--mute:#5d667a}
*{box-sizing:border-box}
body{margin:0;font:15px/1.5 "Segoe UI",system-ui,sans-serif;color:var(--ink);background:var(--paper);display:flex;min-height:100vh}
nav{width:230px;background:var(--brand);color:var(--brand-ink);padding:20px 0;flex-shrink:0}
nav h1{font:600 17px/1.3 Georgia,serif;margin:0 20px 16px}
nav a{display:block;padding:7px 20px;color:#d6e6ec;text-decoration:none}
nav a:hover,nav a.on{background:rgba(255,255,255,.14);color:#fff}
nav a:focus-visible,button:focus-visible,input:focus-visible,select:focus-visible{outline:3px solid #f2b84b;outline-offset:1px}
nav hr{border:0;border-top:1px solid rgba(255,255,255,.2);margin:10px 20px}
main{flex:1;padding:24px 28px;min-width:0}
h2{font:600 24px Georgia,serif;margin:0 0 4px}
.sub{color:var(--mute);margin:0 0 18px}
.msg{padding:10px 14px;border-radius:4px;margin-bottom:14px;border-left:4px solid}
.msg.ok{background:#e4f3ea;border-color:var(--good)}
.msg.err{background:#fbe7e5;border-color:var(--bad)}
form.add{background:#fff;border:1px solid var(--line);padding:16px;margin-bottom:20px;display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:12px;align-items:end}
label{display:flex;flex-direction:column;font-size:13px;color:var(--mute);gap:3px}
input,select{padding:7px 8px;border:1px solid var(--line);border-radius:3px;font:inherit;color:var(--ink);background:#fff}
button{padding:8px 16px;border:0;border-radius:3px;background:var(--brand);color:#fff;font:inherit;cursor:pointer}
button.del{background:var(--bad);padding:4px 10px;font-size:13px}
.tw{overflow-x:auto;background:#fff;border:1px solid var(--line)}
table{border-collapse:collapse;width:100%}
th,td{padding:8px 12px;text-align:left;border-bottom:1px solid var(--line);white-space:nowrap}
th{background:#eef1f5;font-weight:600;font-size:13px}
.count{color:var(--mute);margin:10px 0 6px}
@media(max-width:700px){body{flex-direction:column}nav{width:100%}}
</style></head><body>
<nav>
  <h1>Event Registration<br>Console</h1>
  {% for t in tables %}<a href="{{ url_for('table', name=t) }}" class="{{ 'on' if t==current }}">{{ t }}</a>{% endfor %}
  <hr><a href="{{ url_for('reports') }}" class="{{ 'on' if current=='reports' }}">Reports (views)</a>
</nav>
<main>
{% for cat, m in get_flashed_messages(with_categories=true) %}<div class="msg {{ cat }}">{{ m }}</div>{% endfor %}
{{ body|safe }}
</main></body></html>
"""

TABLE_BODY = """
<h2>{{ name }}</h2><p class="sub">Add a record, view all rows, or delete one.</p>
<form class="add" method="post" action="{{ url_for('insert', name=name) }}">
{% for f in fields %}
  <label>{{ f[0] }}
  {% if f[1]=='fk' %}<select name="{{ f[0] }}" required>{% for v,l in lookups[f[0]] %}<option value="{{ v }}">{{ l }}</option>{% endfor %}</select>
  {% elif f[1]=='select' %}<select name="{{ f[0] }}">{% for o in f[2] %}<option>{{ o }}</option>{% endfor %}</select>
  {% elif f[1]=='number' %}<input type="number" step="any" name="{{ f[0] }}" required>
  {% else %}<input type="{{ f[1] }}" name="{{ f[0] }}" {{ 'required' if f[0] not in optional }}>{% endif %}
  </label>
{% endfor %}
  <button type="submit">Add {{ name[:-1] if name.endswith('s') else name }}</button>
</form>
<p class="count">{{ rows|length }} row(s)</p>
<div class="tw"><table><tr>{% for c in cols %}<th>{{ c }}</th>{% endfor %}<th></th></tr>
{% for r in rows %}<tr>{% for v in r %}<td>{{ v if v is not none else '' }}</td>{% endfor %}
<td><form method="post" action="{{ url_for('delete', name=name, pk=r[0]) }}" onsubmit="return confirm('Delete row {{ r[0] }} from {{ name }}?')"><button class="del">Delete</button></form></td></tr>
{% else %}<tr><td colspan="{{ cols|length + 1 }}">No rows yet. Use the form above to add one.</td></tr>{% endfor %}
</table></div>
"""

REPORT_BODY = """
<h2>Reports</h2><p class="sub">Live results from the SQL views.</p>
{% for title, cols, rows in results %}
<p class="count"><strong>{{ title }}</strong></p>
<div class="tw"><table><tr>{% for c in cols %}<th>{{ c }}</th>{% endfor %}</tr>
{% for r in rows %}<tr>{% for v in r %}<td>{{ v if v is not none else '' }}</td>{% endfor %}</tr>{% endfor %}</table></div>
{% endfor %}
"""


def page(body_tpl, current, **ctx):
    body = render_template_string(body_tpl, **ctx)
    return render_template_string(PAGE, body=body, tables=TABLES.keys(), current=current)


@app.route("/")
def home():
    return redirect(url_for("table", name="registrations"))


@app.route("/t/<name>")
def table(name):
    if name not in TABLES:
        return redirect(url_for("home"))
    pk, fields = TABLES[name]
    try:
        cols, rows = run(f"SELECT * FROM {name} ORDER BY {pk}")
        lookups = {f[0]: run(FK[f[0]])[1] for f in fields if f[1] == "fk"}
    except mysql.connector.Error as e:
        flash(f"Database error: {e.msg}", "err")
        cols, rows, lookups = [], [], {}
    return page(TABLE_BODY, name, name=name, fields=fields, cols=cols, rows=rows,
                lookups=lookups, optional={"phone", "location", "expertise", "contact", "comments"})


@app.route("/t/<name>/insert", methods=["POST"])
def insert(name):
    pk, fields = TABLES[name]
    names = [f[0] for f in fields]
    vals = [request.form.get(n) or None for n in names]
    sql = f"INSERT INTO {name} ({', '.join(names)}) VALUES ({', '.join(['%s'] * len(names))})"
    try:
        run(sql, vals, fetch=False)
        flash(f"Row added to {name}.", "ok")
    except mysql.connector.Error as e:
        flash(f"Rejected by the database: {e.msg}", "err")   # shows constraint violations live
    return redirect(url_for("table", name=name))


@app.route("/t/<name>/delete/<int:pk>", methods=["POST"])
def delete(name, pk):
    pkcol = TABLES[name][0]
    try:
        n = run(f"DELETE FROM {name} WHERE {pkcol} = %s", (pk,), fetch=False)
        flash(f"Deleted {n} row from {name}.", "ok")
    except mysql.connector.Error as e:
        flash(f"Cannot delete: {e.msg}", "err")
    return redirect(url_for("table", name=name))


@app.route("/reports")
def reports():
    results = []
    try:
        for title, sql in REPORTS.items():
            cols, rows = run(sql)
            results.append((title, cols, rows))
    except mysql.connector.Error as e:
        flash(f"Database error: {e.msg}", "err")
    return page(REPORT_BODY, "reports", results=results)


if __name__ == "__main__":
    app.run(debug=True)
