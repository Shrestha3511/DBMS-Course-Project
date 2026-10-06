# DBMS Course Project

**Name:** Shrestha Mal
**Roll Number:** 25WU0102258
**Section:** AIML Whales
**Project Title:** Design and Implementation of a Database Management System for Event Registration and Venue Scheduling System

**Description:** A normalized (3NF) MySQL database with a Flask web UI for managing events, sessions, venues, registrations, payments, attendance, certificates and feedback.

## Repository structure

| Folder | Contents |
|---|---|
| Presentation-I | Problem description PPT/PDF |
| Presentation-II | PPT/PDF, ER diagram image, SQL files, Presentation-II query |
| Presentation-III | PPT/PDF, source code (app.py), UI screenshots |
| Project-Report | Final project report (PDF) |

## How to run the UI

1. Run `01_DDL.sql`, `02_SampleData.sql` and `03_Queries_and_Views.sql` in MySQL (once).
2. `pip install flask mysql-connector-python`
3. Set the MySQL password in `UI app.py`.
4. `python app.py` and open http://127.0.0.1:5000
