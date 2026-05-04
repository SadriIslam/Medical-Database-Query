-- =============================================================
-- indexes.sql
-- 16 B-tree indexes for medical_analytics database
-- Run AFTER all data is loaded
--
-- Usage:
--   \i indexes.sql
-- =============================================================

-- 11 JOIN PERFORMANCE INDEXES (foreign key columns)
CREATE INDEX IF NOT EXISTS idx_encounters_patient    ON encounters    (patient);
CREATE INDEX IF NOT EXISTS idx_encounters_provider   ON encounters    (provider);
CREATE INDEX IF NOT EXISTS idx_conditions_patient    ON conditions    (patient);
CREATE INDEX IF NOT EXISTS idx_conditions_encounter  ON conditions    (encounter);
CREATE INDEX IF NOT EXISTS idx_procedures_patient    ON procedures    (patient);
CREATE INDEX IF NOT EXISTS idx_procedures_encounter  ON procedures    (encounter);
CREATE INDEX IF NOT EXISTS idx_medications_patient   ON medications   (patient);
CREATE INDEX IF NOT EXISTS idx_observations_patient  ON observations  (patient);
CREATE INDEX IF NOT EXISTS idx_observations_encounter ON observations (encounter);
CREATE INDEX IF NOT EXISTS idx_imaging_patient       ON imaging_studies (patient);
CREATE INDEX IF NOT EXISTS idx_imaging_encounter     ON imaging_studies (encounter);

-- 5 DATE RANGE INDEXES (timestamp columns used in WHERE filters)
CREATE INDEX IF NOT EXISTS idx_encounters_start      ON encounters    (start);
CREATE INDEX IF NOT EXISTS idx_conditions_start      ON conditions    (start);
CREATE INDEX IF NOT EXISTS idx_procedures_start      ON procedures    (start);
CREATE INDEX IF NOT EXISTS idx_medications_start     ON medications   (start);
CREATE INDEX IF NOT EXISTS idx_observations_date     ON observations  (date);

-- Update planner statistics — REQUIRED after loading and indexing
ANALYZE;

SELECT '16 indexes created and ANALYZE complete' AS status;
