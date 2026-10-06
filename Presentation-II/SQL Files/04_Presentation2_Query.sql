-- =====================================================================
-- Project 31: Event Registration and Venue Scheduling System
-- Presentation-II: query given during the presentation
-- =====================================================================
USE event_registration_db;

-- Question:
-- Display the coordinators, the sessions and the attendance
-- of the Cultural Night event.

SELECT c.full_name AS coordinator_name,
       s.session_date, s.start_time, s.end_time,
       p.full_name AS participant_name,
       a.status AS attendance_status
FROM events e
JOIN event_coordinators ec ON ec.event_id = e.event_id
JOIN coordinators c ON c.coordinator_id = ec.coordinator_id
JOIN sessions s ON s.event_id = e.event_id
LEFT JOIN attendance a ON a.session_id = s.session_id
LEFT JOIN registrations r ON r.registration_id = a.registration_id
LEFT JOIN participants p ON p.participant_id = r.participant_id
WHERE e.event_name = 'Cultural Night';

-- Output (2 rows):
-- coordinator_name | session_date | start_time | end_time | participant_name | attendance_status
-- Arjun Das        | 2026-09-20   | 18:00:00   | 20:00:00 | Farhan Ali       | present
-- Arjun Das        | 2026-09-20   | 18:00:00   | 20:00:00 | Gauri Joshi      | present
