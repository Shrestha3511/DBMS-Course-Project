-- =====================================================================
-- Project 31: Sample Data
-- =====================================================================
USE event_registration_db;

-- Categories
INSERT INTO categories (category_name) VALUES
('Seminar'), ('Workshop'), ('Cultural'), ('Conference');

-- Venues
INSERT INTO venues (venue_name, capacity, location) VALUES
('Auditorium A', 300, 'Block 1, Ground Floor'),
('Seminar Hall B', 120, 'Block 2, First Floor'),
('Open Air Theatre', 500, 'Central Lawn'),
('Conference Room C', 60, 'Admin Block, Second Floor');

-- Speakers
INSERT INTO speakers (full_name, expertise, contact) VALUES
('Dr. Ananya Rao', 'Artificial Intelligence', 'ananya.rao@example.com'),
('Mr. Karan Mehta', 'Cloud Computing', 'karan.mehta@example.com'),
('Prof. Leela Nair', 'Data Privacy Law', 'leela.nair@example.com'),
('Ms. Priya Sen', 'Classical Dance', 'priya.sen@example.com');

-- Coordinators
INSERT INTO coordinators (full_name, contact) VALUES
('Rohit Sharma', 'rohit.sharma@college.edu'),
('Sneha Iyer', 'sneha.iyer@college.edu'),
('Arjun Das', 'arjun.das@college.edu');

-- Participants
INSERT INTO participants (full_name, email, phone) VALUES
('Aditya Kumar', 'aditya.kumar@mail.com', '9800000001'),
('Bhavna Roy', 'bhavna.roy@mail.com', '9800000002'),
('Chirag Patel', 'chirag.patel@mail.com', '9800000003'),
('Divya Menon', 'divya.menon@mail.com', '9800000004'),
('Esha Gupta', 'esha.gupta@mail.com', '9800000005'),
('Farhan Ali', 'farhan.ali@mail.com', '9800000006'),
('Gauri Joshi', 'gauri.joshi@mail.com', '9800000007'),
('Harsh Vardhan', 'harsh.vardhan@mail.com', '9800000008');

-- Events
INSERT INTO events (event_name, category_id, start_date, end_date) VALUES
('TechFest 2026', 4, '2026-09-10', '2026-09-12'),
('AI & Cloud Workshop', 2, '2026-09-15', '2026-09-15'),
('Cultural Night', 3, '2026-09-20', '2026-09-20');

-- Event-Coordinators
INSERT INTO event_coordinators (event_id, coordinator_id) VALUES
(1, 1), (1, 2), (2, 2), (3, 3);

-- Sessions
INSERT INTO sessions (event_id, venue_id, speaker_id, session_date, start_time, end_time) VALUES
(1, 1, 1, '2026-09-10', '10:00:00', '11:30:00'),  -- TechFest day 1: AI talk
(1, 1, 2, '2026-09-11', '10:00:00', '11:30:00'),  -- TechFest day 2: Cloud talk
(1, 4, 3, '2026-09-12', '14:00:00', '15:30:00'),  -- TechFest day 3: Data privacy
(2, 2, 1, '2026-09-15', '09:30:00', '12:30:00'),  -- AI & Cloud workshop session
(3, 3, 4, '2026-09-20', '18:00:00', '20:00:00');  -- Cultural night

-- Registrations (participant registers for an event)
INSERT INTO registrations (participant_id, event_id, registration_date, status) VALUES
(1, 1, '2026-08-25', 'confirmed'),
(2, 1, '2026-08-25', 'confirmed'),
(3, 1, '2026-08-26', 'confirmed'),
(4, 2, '2026-08-27', 'confirmed'),
(5, 2, '2026-08-27', 'confirmed'),
(6, 3, '2026-08-28', 'confirmed'),
(7, 3, '2026-08-28', 'confirmed'),
(1, 2, '2026-08-29', 'confirmed'),   -- Aditya also attends the workshop
(8, 1, '2026-08-30', 'cancelled');  -- Harsh cancelled

-- Payments (one per non-free registration; workshop and cultural night have a fee)
INSERT INTO payments (registration_id, amount, payment_date, mode) VALUES
(4, 500.00, '2026-08-27', 'upi'),
(5, 500.00, '2026-08-27', 'card'),
(6, 100.00, '2026-08-28', 'cash'),
(7, 100.00, '2026-08-28', 'upi'),
(8, 500.00, '2026-08-29', 'upi');
-- TechFest (event 1) registrations 1,2,3 are free -> no payment row

-- Attendance
INSERT INTO attendance (registration_id, session_id, status) VALUES
(1, 1, 'present'), (1, 2, 'present'), (1, 3, 'absent'),
(2, 1, 'present'), (2, 2, 'absent'),  (2, 3, 'absent'),
(3, 1, 'absent'),  (3, 2, 'present'), (3, 3, 'present'),
(4, 4, 'present'),
(5, 4, 'present'),
(6, 5, 'present'),
(7, 5, 'present'),
(8, 4, 'present');

-- Certificates (issued only where attendance threshold met - see Review 2 report for the 60% rule)
INSERT INTO certificates (registration_id, issue_date, eligibility_status) VALUES
(1, '2026-09-13', 'eligible'),        -- 2/3 sessions present = 67%
(2, '2026-09-13', 'not eligible'),    -- 1/3 = 33%
(3, '2026-09-13', 'eligible'),        -- 2/3 = 67%
(4, '2026-09-16', 'eligible'),
(5, '2026-09-16', 'eligible'),
(6, '2026-09-21', 'eligible'),
(7, '2026-09-21', 'eligible'),
(8, '2026-09-16', 'eligible');

-- Feedback
INSERT INTO feedback (registration_id, session_id, rating, comments) VALUES
(1, 1, 5, 'Excellent session on AI fundamentals'),
(1, 2, 4, 'Good overview of cloud services'),
(3, 2, 5, 'Very engaging speaker'),
(4, 4, 4, 'Practical and hands-on'),
(5, 4, 5, 'Loved the live demo'),
(6, 5, 5, 'Beautiful performances'),
(7, 5, 4, 'Great cultural showcase');
