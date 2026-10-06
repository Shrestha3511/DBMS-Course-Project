-- =====================================================================
-- Project 31: SQL Queries and Views for Reporting
-- =====================================================================
USE event_registration_db;

-- ---------------------------------------------------------------------
-- Q1. EVENT SEATS REPORT (join + aggregation)
-- Seats booked vs. total venue capacity used per event
-- ---------------------------------------------------------------------
SELECT
    e.event_name,
    COUNT(DISTINCT r.registration_id) AS seats_booked,
    SUM(v.capacity) AS total_capacity_across_sessions
FROM events e
JOIN registrations r ON r.event_id = e.event_id AND r.status = 'confirmed'
JOIN sessions s ON s.event_id = e.event_id
JOIN venues v ON v.venue_id = s.venue_id
GROUP BY e.event_id, e.event_name;

-- ---------------------------------------------------------------------
-- Q2. REGISTRATION SUMMARY (join, per event, confirmed vs cancelled)
-- ---------------------------------------------------------------------
SELECT
    e.event_name,
    SUM(CASE WHEN r.status = 'confirmed' THEN 1 ELSE 0 END) AS confirmed_count,
    SUM(CASE WHEN r.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_count,
    COUNT(*) AS total_registrations
FROM registrations r
JOIN events e ON e.event_id = r.event_id
GROUP BY e.event_id, e.event_name;

-- ---------------------------------------------------------------------
-- Q3. ATTENDANCE REPORT (join across registration -> attendance -> session)
-- Attendance percentage per participant per event
-- ---------------------------------------------------------------------
SELECT
    p.full_name,
    e.event_name,
    COUNT(a.attendance_id) AS sessions_recorded,
    SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) AS sessions_present,
    ROUND(100.0 * SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) / COUNT(a.attendance_id), 1) AS attendance_pct
FROM registrations r
JOIN participants p ON p.participant_id = r.participant_id
JOIN events e ON e.event_id = r.event_id
JOIN attendance a ON a.registration_id = r.registration_id
GROUP BY r.registration_id, p.full_name, e.event_name;

-- ---------------------------------------------------------------------
-- Q4. CERTIFICATE ELIGIBILITY REPORT (join)
-- ---------------------------------------------------------------------
SELECT
    p.full_name,
    e.event_name,
    c.eligibility_status,
    c.issue_date
FROM certificates c
JOIN registrations r ON r.registration_id = c.registration_id
JOIN participants p ON p.participant_id = r.participant_id
JOIN events e ON e.event_id = r.event_id
ORDER BY e.event_name, c.eligibility_status;

-- ---------------------------------------------------------------------
-- Q5. REVENUE REPORT (join + aggregation)
-- Total revenue collected per event
-- ---------------------------------------------------------------------
SELECT
    e.event_name,
    COUNT(pay.payment_id) AS paid_registrations,
    SUM(pay.amount) AS total_revenue
FROM payments pay
JOIN registrations r ON r.registration_id = pay.registration_id
JOIN events e ON e.event_id = r.event_id
GROUP BY e.event_id, e.event_name
ORDER BY total_revenue DESC;

-- ---------------------------------------------------------------------
-- Q6. SPEAKER SCHEDULE REPORT (join across sessions -> events -> venues)
-- ---------------------------------------------------------------------
SELECT
    sp.full_name AS speaker_name,
    e.event_name,
    v.venue_name,
    s.session_date,
    s.start_time,
    s.end_time
FROM sessions s
JOIN speakers sp ON sp.speaker_id = s.speaker_id
JOIN events e ON e.event_id = s.event_id
JOIN venues v ON v.venue_id = s.venue_id
ORDER BY sp.full_name, s.session_date, s.start_time;

-- ---------------------------------------------------------------------
-- Q7. FEEDBACK REPORT (join + aggregation)
-- Average rating per session, with speaker name
-- ---------------------------------------------------------------------
SELECT
    e.event_name,
    sp.full_name AS speaker_name,
    s.session_date,
    ROUND(AVG(f.rating), 2) AS avg_rating,
    COUNT(f.feedback_id) AS feedback_count
FROM feedback f
JOIN sessions s ON s.session_id = f.session_id
JOIN speakers sp ON sp.speaker_id = s.speaker_id
JOIN events e ON e.event_id = s.event_id
GROUP BY s.session_id, e.event_name, sp.full_name, s.session_date
ORDER BY avg_rating DESC;

-- ---------------------------------------------------------------------
-- Q8. NESTED QUERY - Participants who attended every session of an event
-- they registered for (subquery with NOT EXISTS)
-- ---------------------------------------------------------------------
SELECT p.full_name, e.event_name
FROM registrations r
JOIN participants p ON p.participant_id = r.participant_id
JOIN events e ON e.event_id = r.event_id
WHERE r.status = 'confirmed'
  AND NOT EXISTS (
      SELECT 1 FROM attendance a
      WHERE a.registration_id = r.registration_id
        AND a.status = 'absent'
  );

-- ---------------------------------------------------------------------
-- Q9. NESTED QUERY - Events whose revenue is above the average revenue
-- across all events (subquery in WHERE)
-- ---------------------------------------------------------------------
SELECT e.event_name, SUM(pay.amount) AS revenue
FROM events e
JOIN registrations r ON r.event_id = e.event_id
JOIN payments pay ON pay.registration_id = r.registration_id
GROUP BY e.event_id, e.event_name
HAVING SUM(pay.amount) > (
    SELECT AVG(event_revenue) FROM (
        SELECT SUM(pay2.amount) AS event_revenue
        FROM registrations r2
        JOIN payments pay2 ON pay2.registration_id = r2.registration_id
        GROUP BY r2.event_id
    ) AS sub
);

-- ---------------------------------------------------------------------
-- Q10. Venues never double-booked check (self-join demonstrating the
-- no-overlap rule holds true in the data)
-- ---------------------------------------------------------------------
SELECT s1.session_id AS session_a, s2.session_id AS session_b, s1.venue_id
FROM sessions s1
JOIN sessions s2
  ON s1.venue_id = s2.venue_id
 AND s1.session_id < s2.session_id
 AND s1.session_date = s2.session_date
 AND s1.start_time < s2.end_time
 AND s2.start_time < s1.end_time;
-- Expect: zero rows returned if no venue overlap rule is respected

-- =====================================================================
-- VIEWS
-- =====================================================================

-- View 1: Event seats availability
CREATE OR REPLACE VIEW vw_event_seats AS
SELECT
    e.event_id,
    e.event_name,
    COUNT(DISTINCT r.registration_id) AS seats_booked
FROM events e
LEFT JOIN registrations r ON r.event_id = e.event_id AND r.status = 'confirmed'
GROUP BY e.event_id, e.event_name;

-- View 2: Revenue per event
CREATE OR REPLACE VIEW vw_event_revenue AS
SELECT
    e.event_id,
    e.event_name,
    COALESCE(SUM(pay.amount), 0) AS total_revenue
FROM events e
LEFT JOIN registrations r ON r.event_id = e.event_id
LEFT JOIN payments pay ON pay.registration_id = r.registration_id
GROUP BY e.event_id, e.event_name;

-- View 3: Participant attendance summary
CREATE OR REPLACE VIEW vw_attendance_summary AS
SELECT
    r.registration_id,
    p.full_name,
    e.event_name,
    COUNT(a.attendance_id) AS total_sessions,
    SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) AS attended,
    ROUND(100.0 * SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) / NULLIF(COUNT(a.attendance_id),0), 1) AS attendance_pct
FROM registrations r
JOIN participants p ON p.participant_id = r.participant_id
JOIN events e ON e.event_id = r.event_id
LEFT JOIN attendance a ON a.registration_id = r.registration_id
GROUP BY r.registration_id, p.full_name, e.event_name;

-- View 4: Speaker schedule
CREATE OR REPLACE VIEW vw_speaker_schedule AS
SELECT
    sp.speaker_id,
    sp.full_name AS speaker_name,
    e.event_name,
    v.venue_name,
    s.session_date,
    s.start_time,
    s.end_time
FROM sessions s
JOIN speakers sp ON sp.speaker_id = s.speaker_id
JOIN events e ON e.event_id = s.event_id
JOIN venues v ON v.venue_id = s.venue_id;

-- Example usage of views:
-- SELECT * FROM vw_event_seats;
-- SELECT * FROM vw_event_revenue ORDER BY total_revenue DESC;
-- SELECT * FROM vw_attendance_summary WHERE attendance_pct >= 60;
-- SELECT * FROM vw_speaker_schedule ORDER BY speaker_name, session_date;
