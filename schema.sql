-- =============================================================
-- schema.sql
-- Full 17-table schema for medical_analytics database
-- PostgreSQL 18 | CS 8260 Spring 2026
--
-- Usage:
--   psql -U postgres
--   CREATE DATABASE medical_analytics;
--   \c medical_analytics
--   \i schema.sql
-- =============================================================

DROP TABLE IF EXISTS claims_transactions CASCADE;
DROP TABLE IF EXISTS claims CASCADE;
DROP TABLE IF EXISTS supplies CASCADE;
DROP TABLE IF EXISTS devices CASCADE;
DROP TABLE IF EXISTS careplans CASCADE;
DROP TABLE IF EXISTS allergies CASCADE;
DROP TABLE IF EXISTS immunizations CASCADE;
DROP TABLE IF EXISTS imaging_studies CASCADE;
DROP TABLE IF EXISTS observations CASCADE;
DROP TABLE IF EXISTS medications CASCADE;
DROP TABLE IF EXISTS procedures CASCADE;
DROP TABLE IF EXISTS conditions CASCADE;
DROP TABLE IF EXISTS encounters CASCADE;
DROP TABLE IF EXISTS payer_transitions CASCADE;
DROP TABLE IF EXISTS payers CASCADE;
DROP TABLE IF EXISTS providers CASCADE;
DROP TABLE IF EXISTS organizations CASCADE;
DROP TABLE IF EXISTS patients CASCADE;

CREATE TABLE patients (
    id UUID PRIMARY KEY, birthdate DATE, deathdate DATE,
    ssn TEXT, drivers TEXT, passport TEXT, prefix TEXT,
    first TEXT, last TEXT, suffix TEXT, maiden TEXT,
    marital TEXT, race TEXT, ethnicity TEXT, gender TEXT,
    birthplace TEXT, address TEXT, city TEXT, state TEXT,
    county TEXT, fips TEXT, zip TEXT, lat TEXT, lon TEXT,
    healthcare_expenses TEXT, healthcare_coverage TEXT
);

CREATE TABLE providers (
    id UUID PRIMARY KEY, organization UUID, name TEXT,
    gender TEXT, speciality TEXT, address TEXT, city TEXT,
    state TEXT, zip TEXT, lat TEXT, lon TEXT,
    encounters TEXT, procedures TEXT
);

CREATE TABLE organizations (
    id UUID PRIMARY KEY, name TEXT, address TEXT, city TEXT,
    state TEXT, zip TEXT, lat TEXT, lon TEXT,
    phone TEXT, revenue TEXT, utilization TEXT
);

CREATE TABLE payers (
    id UUID PRIMARY KEY, name TEXT, address TEXT, city TEXT,
    state_headquartered TEXT, zip TEXT, phone TEXT,
    amount_covered TEXT, amount_uncovered TEXT, revenue TEXT,
    covered_encounters TEXT, uncovered_encounters TEXT,
    covered_medications TEXT, uncovered_medications TEXT,
    covered_procedures TEXT, uncovered_procedures TEXT,
    covered_immunizations TEXT, uncovered_immunizations TEXT,
    unique_customers TEXT, qols_avg TEXT, member_months TEXT
);

CREATE TABLE encounters (
    id UUID PRIMARY KEY, start TIMESTAMPTZ, stop TIMESTAMPTZ,
    patient UUID, organization UUID, provider UUID, payer UUID,
    encounterclass TEXT, code TEXT, description TEXT,
    base_encounter_cost TEXT, total_claim_cost TEXT,
    payer_coverage TEXT, reasoncode TEXT, reasondescription TEXT
);

CREATE TABLE conditions (
    start TIMESTAMPTZ, stop TIMESTAMPTZ,
    patient UUID, encounter UUID, code TEXT, description TEXT
);

CREATE TABLE procedures (
    start TIMESTAMPTZ, stop TIMESTAMPTZ,
    patient UUID, encounter UUID, code TEXT, description TEXT,
    base_cost TEXT, reasoncode TEXT, reasondescription TEXT
);

CREATE TABLE medications (
    start TIMESTAMPTZ, stop TIMESTAMPTZ,
    patient UUID, payer UUID, encounter UUID,
    code TEXT, description TEXT, base_cost TEXT,
    payer_coverage TEXT, dispenses TEXT, totalcost TEXT,
    reasoncode TEXT, reasondescription TEXT
);

CREATE TABLE observations (
    date TIMESTAMPTZ, patient UUID, encounter UUID,
    category TEXT, code TEXT, description TEXT,
    value TEXT, units TEXT, type TEXT
);

CREATE TABLE immunizations (
    date TIMESTAMPTZ, patient UUID, encounter UUID,
    code TEXT, description TEXT, base_cost TEXT
);

CREATE TABLE imaging_studies (
    id UUID, date TIMESTAMPTZ, patient UUID, encounter UUID,
    series_uid TEXT, bodysite_code TEXT, bodysite_description TEXT,
    modality_code TEXT, modality_description TEXT,
    instance_uid TEXT, sop_code TEXT, sop_description TEXT,
    procedure_code TEXT
);

CREATE TABLE allergies (
    start TIMESTAMPTZ, stop TIMESTAMPTZ,
    patient UUID, encounter UUID, code TEXT, system TEXT,
    description TEXT, type TEXT, category TEXT,
    reaction1 TEXT, description1 TEXT, severity1 TEXT,
    reaction2 TEXT, description2 TEXT, severity2 TEXT
);

CREATE TABLE devices (
    start TIMESTAMPTZ, stop TIMESTAMPTZ,
    patient UUID, encounter UUID, code TEXT,
    description TEXT, udi TEXT
);

CREATE TABLE careplans (
    id UUID, start TIMESTAMPTZ, stop TIMESTAMPTZ,
    patient UUID, encounter UUID, code TEXT, description TEXT,
    reasoncode TEXT, reasondescription TEXT
);

CREATE TABLE supplies (
    date DATE, patient UUID, encounter UUID,
    code TEXT, description TEXT, quantity TEXT
);

CREATE TABLE payer_transitions (
    patient UUID, memberid TEXT, start_year TEXT, end_year TEXT,
    payer UUID, secondary_payer UUID, plan_ownership TEXT, owner_name TEXT
);

CREATE TABLE claims (
    id UUID PRIMARY KEY, patientid UUID, providerid UUID,
    primarypatientinsuranceid UUID, secondarypatientinsuranceid UUID,
    departmentid TEXT, patientdepartmentid TEXT,
    diagnosis1 TEXT, diagnosis2 TEXT, diagnosis3 TEXT,
    diagnosis4 TEXT, diagnosis5 TEXT, diagnosis6 TEXT,
    diagnosis7 TEXT, diagnosis8 TEXT,
    referringproviderid UUID, appointmentid UUID,
    currentillnessdate TEXT, servicedate TEXT,
    supervisingproviderid UUID,
    status1 TEXT, status2 TEXT, statusp TEXT,
    outstanding1 TEXT, outstanding2 TEXT, outstandingp TEXT,
    lastbilleddate1 TEXT, lastbilleddate2 TEXT, lastbilleddatep TEXT,
    healthcareclaimtypeid1 TEXT, healthcareclaimtypeid2 TEXT
);

CREATE TABLE claims_transactions (
    id UUID, claimid UUID, chargeid TEXT, patientid UUID,
    type TEXT, amount TEXT, method TEXT, fromdate TEXT, todate TEXT,
    placeofservice UUID, procedurecode TEXT, modifier1 TEXT, modifier2 TEXT,
    diagnosisref1 TEXT, diagnosisref2 TEXT, diagnosisref3 TEXT, diagnosisref4 TEXT,
    units TEXT, departmentid TEXT, notes TEXT, unitamount TEXT,
    transferoutid TEXT, transfertype TEXT, payments TEXT, adjustments TEXT,
    transfers TEXT, outstanding TEXT, appointmentid TEXT, linenote TEXT,
    patientinsuranceid UUID, feescheduleid TEXT, providerid UUID,
    supervisingproviderid UUID
);

SELECT '17 tables created successfully' AS status;
