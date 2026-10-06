-- =====================================================================
-- Project 31: Event Registration and Venue Scheduling System
-- Review 2 - DDL Script (MySQL 8.0+)
-- Normalized to Third Normal Form (3NF)
-- =====================================================================

DROP DATABASE IF EXISTS event_registration_db;
CREATE DATABASE event_registration_db;
USE event_registration_db;

-- ---------------------------------------------------------------------
-- 1. CATEGORIES
-- ---------------------------------------------------------------------
CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
);

-- ---------------------------------------------------------------------
-- 2. VENUES
-- ---------------------------------------------------------------------
CREATE TABLE venues (
    venue_id   INT AUTO_INCREMENT PRIMARY KEY,
    venue_name VARCHAR(100) NOT NULL,
    capacity   INT NOT NULL CHECK (capacity > 0),
    location   VARCHAR(150)
);

-- ---------------------------------------------------------------------
-- 3. SPEAKERS
-- ---------------------------------------------------------------------
CREATE TABLE speakers (
    speaker_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name  VARCHAR(100) NOT NULL,
    expertise  VARCHAR(150),
    contact    VARCHAR(50)
);

-- ---------------------------------------------------------------------
-- 4. COORDINATORS
-- ---------------------------------------------------------------------
CREATE TABLE coordinators (
    coordinator_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name      VARCHAR(100) NOT NULL,
    contact        VARCHAR(50)
);

-- ---------------------------------------------------------------------
-- 5. PARTICIPANTS
-- ---------------------------------------------------------------------
CREATE TABLE participants (
    participant_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name      VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL UNIQUE,
    phone          VARCHAR(15)
);

-- ---------------------------------------------------------------------
-- 6. EVENTS
-- ---------------------------------------------------------------------
CREATE TABLE events (
    event_id     INT AUTO_INCREMENT PRIMARY KEY,
    event_name   VARCHAR(150) NOT NULL,
    category_id  INT NOT NULL,
    start_date   DATE NOT NULL,
    end_date     DATE NOT NULL,
    CONSTRAINT fk_events_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id),
    CONSTRAINT chk_event_dates CHECK (end_date >= start_date)
);

-- ---------------------------------------------------------------------
-- 7. EVENT_COORDINATORS (resolves the M:N between events and coordinators)
-- ---------------------------------------------------------------------
CREATE TABLE event_coordinators (
    event_id       INT NOT NULL,
    coordinator_id INT NOT NULL,
    PRIMARY KEY (event_id, coordinator_id),
    CONSTRAINT fk_ec_event FOREIGN KEY (event_id)
        REFERENCES events(event_id) ON DELETE CASCADE,
    CONSTRAINT fk_ec_coordinator FOREIGN KEY (coordinator_id)
        REFERENCES coordinators(coordinator_id)
);

-- ---------------------------------------------------------------------
-- 8. SESSIONS
-- ---------------------------------------------------------------------
CREATE TABLE sessions (
    session_id   INT AUTO_INCREMENT PRIMARY KEY,
    event_id     INT NOT NULL,
    venue_id     INT NOT NULL,
    speaker_id   INT NOT NULL,
    session_date DATE NOT NULL,
    start_time   TIME NOT NULL,
    end_time     TIME NOT NULL,
    CONSTRAINT fk_sessions_event FOREIGN KEY (event_id)
        REFERENCES events(event_id) ON DELETE CASCADE,
    CONSTRAINT fk_sessions_venue FOREIGN KEY (venue_id)
        REFERENCES venues(venue_id),
    CONSTRAINT fk_sessions_speaker FOREIGN KEY (speaker_id)
        REFERENCES speakers(speaker_id),
    CONSTRAINT chk_session_times CHECK (end_time > start_time),
    -- Business rule: no venue may host two overlapping sessions
    CONSTRAINT uq_venue_slot UNIQUE (venue_id, session_date, start_time)
);

-- ---------------------------------------------------------------------
-- 9. REGISTRATIONS
-- ---------------------------------------------------------------------
CREATE TABLE registrations (
    registration_id   INT AUTO_INCREMENT PRIMARY KEY,
    participant_id     INT NOT NULL,
    event_id           INT NOT NULL,
    registration_date  DATE NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'confirmed',
    CONSTRAINT fk_reg_participant FOREIGN KEY (participant_id)
        REFERENCES participants(participant_id),
    CONSTRAINT fk_reg_event FOREIGN KEY (event_id)
        REFERENCES events(event_id) ON DELETE CASCADE,
    -- Business rule: no duplicate registration
    CONSTRAINT uq_participant_event UNIQUE (participant_id, event_id),
    CONSTRAINT chk_status CHECK (status IN ('confirmed','cancelled','waitlisted'))
);

-- ---------------------------------------------------------------------
-- 10. PAYMENTS
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    payment_id      INT AUTO_INCREMENT PRIMARY KEY,
    registration_id INT NOT NULL UNIQUE,
    amount          DECIMAL(10,2) NOT NULL,
    payment_date    DATE NOT NULL,
    mode            VARCHAR(20) NOT NULL,
    CONSTRAINT fk_payments_registration FOREIGN KEY (registration_id)
        REFERENCES registrations(registration_id) ON DELETE CASCADE,
    -- Business rule: non-negative payments
    CONSTRAINT chk_amount_nonneg CHECK (amount >= 0),
    CONSTRAINT chk_mode CHECK (mode IN ('cash','upi','card','netbanking'))
);

-- ---------------------------------------------------------------------
-- 11. ATTENDANCE
-- ---------------------------------------------------------------------
CREATE TABLE attendance (
    attendance_id   INT AUTO_INCREMENT PRIMARY KEY,
    registration_id INT NOT NULL,
    session_id      INT NOT NULL,
    status          VARCHAR(10) NOT NULL,
    CONSTRAINT fk_att_registration FOREIGN KEY (registration_id)
        REFERENCES registrations(registration_id) ON DELETE CASCADE,
    CONSTRAINT fk_att_session FOREIGN KEY (session_id)
        REFERENCES sessions(session_id) ON DELETE CASCADE,
    CONSTRAINT uq_registration_session UNIQUE (registration_id, session_id),
    CONSTRAINT chk_att_status CHECK (status IN ('present','absent'))
);

-- ---------------------------------------------------------------------
-- 12. CERTIFICATES
-- ---------------------------------------------------------------------
CREATE TABLE certificates (
    certificate_id     INT AUTO_INCREMENT PRIMARY KEY,
    registration_id    INT NOT NULL UNIQUE,
    issue_date         DATE NOT NULL,
    eligibility_status VARCHAR(15) NOT NULL,
    CONSTRAINT fk_cert_registration FOREIGN KEY (registration_id)
        REFERENCES registrations(registration_id) ON DELETE CASCADE,
    CONSTRAINT chk_eligibility CHECK (eligibility_status IN ('eligible','not eligible'))
);

-- ---------------------------------------------------------------------
-- 13. FEEDBACK
-- ---------------------------------------------------------------------
CREATE TABLE feedback (
    feedback_id      INT AUTO_INCREMENT PRIMARY KEY,
    registration_id  INT NOT NULL,
    session_id       INT NOT NULL,
    rating           INT NOT NULL,
    comments         VARCHAR(500),
    CONSTRAINT fk_fb_registration FOREIGN KEY (registration_id)
        REFERENCES registrations(registration_id) ON DELETE CASCADE,
    CONSTRAINT fk_fb_session FOREIGN KEY (session_id)
        REFERENCES sessions(session_id) ON DELETE CASCADE,
    CONSTRAINT uq_registration_session_fb UNIQUE (registration_id, session_id),
    CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5)
);

-- ---------------------------------------------------------------------
-- Helpful indexes on frequently-searched attributes
-- ---------------------------------------------------------------------
CREATE INDEX idx_sessions_event ON sessions(event_id);
CREATE INDEX idx_sessions_venue_date ON sessions(venue_id, session_date);
CREATE INDEX idx_registrations_event ON registrations(event_id);
CREATE INDEX idx_participants_email ON participants(email);
CREATE INDEX idx_attendance_registration ON attendance(registration_id);
