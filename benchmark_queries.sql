-- =============================================================
-- benchmark_queries.sql
-- ALL 60 real benchmark queries with EXPLAIN ANALYZE
-- Q1-Q20  (Week 2) + Q61-Q100 (Final Phase)
-- Q21-Q60 are synthetic — see data/benchmark_final_100.csv
--
-- HOW TO USE:
--   Open pgAdmin → Query Tool
--   Paste one query → press F5
--   Copy Planning Time and Execution Time from Messages tab
-- =============================================================

-- ==============================================================
-- WEEK 2 QUERIES  Q1–Q20
-- ==============================================================

-- Q1  exec=0.623ms   Simple patient-encounter join
EXPLAIN ANALYZE
SELECT p.first, p.last, e.start, e.description
FROM patients p JOIN encounters e ON p.id = e.patient LIMIT 100;

-- Q2  exec=29.091ms  Time range filter 2020-2022
EXPLAIN ANALYZE
SELECT e.start, e.description, c.description AS condition
FROM encounters e JOIN conditions c ON e.id = c.encounter
WHERE e.start BETWEEN '2020-01-01' AND '2022-12-31';

-- Q3  exec=46.911ms  Aggregation — encounter count per patient
EXPLAIN ANALYZE
SELECT e.patient, COUNT(e.id) AS total_encounters
FROM encounters e GROUP BY e.patient
ORDER BY total_encounters DESC LIMIT 100;

-- Q4  exec=0.102ms   4-table join all indexed — FASTEST
EXPLAIN ANALYZE
SELECT p.first, p.last, e.start, pr.description, c.description
FROM patients p
JOIN encounters e  ON p.id = e.patient
JOIN procedures pr ON e.id = pr.encounter
JOIN conditions c  ON e.id = c.encounter
WHERE e.start >= '2021-01-01' LIMIT 500;

-- Q5  exec=671.251ms Vital signs lookup — no index on category — SLOWEST
EXPLAIN ANALYZE
SELECT o.patient, o.description, o.value, o.units
FROM observations o JOIN encounters e ON o.encounter = e.id
WHERE o.category = 'vital-signs'
AND e.start BETWEEN '2019-01-01' AND '2021-01-01';

-- Q6  exec=190.674ms Provider encounter count
EXPLAIN ANALYZE
SELECT pr.name, COUNT(e.id) AS total_encounters
FROM providers pr JOIN encounters e ON pr.id = e.provider
GROUP BY pr.name ORDER BY total_encounters DESC LIMIT 50;

-- Q7  exec=141.435ms Patient conditions list
EXPLAIN ANALYZE
SELECT p.first, p.last, c.description, c.start
FROM patients p
JOIN encounters e ON p.id = e.patient
JOIN conditions c ON e.id = c.encounter
ORDER BY c.start DESC LIMIT 200;

-- Q8  exec=74.316ms  Medication lookup per patient
EXPLAIN ANALYZE
SELECT p.first, p.last, m.description, m.start
FROM patients p
JOIN encounters e ON p.id = e.patient
JOIN medications m ON e.id = m.encounter LIMIT 300;

-- Q9  exec=10.994ms  Procedures by date range
EXPLAIN ANALYZE
SELECT pr.description, pr.start, pr.base_cost
FROM procedures pr
WHERE pr.start BETWEEN '2019-01-01' AND '2021-12-31' LIMIT 500;

-- Q10 exec=488.375ms Count conditions per patient
EXPLAIN ANALYZE
SELECT e.patient, COUNT(DISTINCT c.code) AS unique_conditions
FROM encounters e JOIN conditions c ON e.id = c.encounter
GROUP BY e.patient ORDER BY unique_conditions DESC LIMIT 100;

-- Q11 exec=1.140ms   Immunizations by date
EXPLAIN ANALYZE
SELECT i.patient, i.description, i.date
FROM immunizations i
WHERE i.date BETWEEN '2020-01-01' AND '2022-12-31' LIMIT 500;

-- Q12 exec=3.462ms   Observations by category=laboratory
EXPLAIN ANALYZE
SELECT o.patient, o.description, o.value, o.units
FROM observations o WHERE o.category = 'laboratory' LIMIT 1000;

-- Q13 exec=26.391ms  Medications with date filter
EXPLAIN ANALYZE
SELECT p.first, p.last, e.start, m.description
FROM patients p
JOIN encounters e ON p.id = e.patient
JOIN medications m ON e.id = m.encounter
WHERE e.start BETWEEN '2020-01-01' AND '2023-01-01' LIMIT 300;

-- Q14 exec=52.425ms  Encounter class aggregation
EXPLAIN ANALYZE
SELECT e.encounterclass, COUNT(*) AS total
FROM encounters e GROUP BY e.encounterclass ORDER BY total DESC;

-- Q15 exec=27.161ms  Most common conditions
EXPLAIN ANALYZE
SELECT c.description, COUNT(*) AS total
FROM conditions c GROUP BY c.description ORDER BY total DESC LIMIT 50;

-- Q16 exec=2.638ms   Imaging studies by date range
EXPLAIN ANALYZE
SELECT i.patient, i.modality_description, i.date
FROM imaging_studies i
WHERE i.date BETWEEN '2018-01-01' AND '2022-01-01' LIMIT 500;

-- Q17 exec=5.440ms   5-table join all indexed post-2020
EXPLAIN ANALYZE
SELECT p.first, p.last, e.start, c.description, m.description, pr.description
FROM patients p
JOIN encounters e  ON p.id = e.patient
JOIN conditions c  ON e.id = c.encounter
JOIN medications m ON e.id = m.encounter
JOIN procedures pr ON e.id = pr.encounter
WHERE e.start >= '2020-01-01' LIMIT 200;

-- Q18 exec=3.320ms   Allergy lookup per patient
EXPLAIN ANALYZE
SELECT p.first, p.last, a.description, a.category
FROM patients p
JOIN encounters e ON p.id = e.patient
JOIN allergies a  ON e.id = a.encounter LIMIT 200;

-- Q19 exec=0.350ms   Supplies by date range
EXPLAIN ANALYZE
SELECT s.patient, s.description, s.quantity, s.date
FROM supplies s
WHERE s.date BETWEEN '2019-01-01' AND '2023-01-01' LIMIT 300;

-- Q20 exec=1073.446ms Full patient profile aggregate
EXPLAIN ANALYZE
SELECT p.first, p.last,
       COUNT(DISTINCT e.id)   AS visits,
       COUNT(DISTINCT c.code) AS conditions,
       COUNT(DISTINCT m.code) AS medications
FROM patients p
JOIN encounters e ON p.id = e.patient
JOIN conditions c ON e.id = c.encounter
JOIN medications m ON e.id = m.encounter
GROUP BY p.first, p.last ORDER BY visits DESC LIMIT 50;


EXPLAIN ANALYZE
SELECT p.first, p.last, COUNT(DISTINCT m.code) AS unique_meds
FROM patients p
JOIN encounters e  ON p.id = e.patient
JOIN medications m ON e.id = m.encounter
GROUP BY p.first, p.last ORDER BY unique_meds DESC LIMIT 50;

-- Q62  exec=760.811ms   plan=11.946ms
EXPLAIN ANALYZE
SELECT o.description, COUNT(*) AS reading_count
FROM observations o
WHERE o.type = 'numeric' AND o.category = 'vital-signs'
GROUP BY o.description LIMIT 30;

-- Q63  exec=0.041ms     plan=21.855ms  (0 rows — date filter eliminates all)
EXPLAIN ANALYZE
SELECT e.patient, e.encounterclass, e.start, c.description
FROM encounters e JOIN conditions c ON e.id = c.encounter
WHERE e.start >= '2022-01-01' LIMIT 300;

-- Q64  exec=830.339ms   plan=17.842ms
EXPLAIN ANALYZE
SELECT pr.name, pr.speciality, COUNT(DISTINCT e.patient) AS unique_patients
FROM providers pr JOIN encounters e ON pr.id = e.provider
GROUP BY pr.name, pr.speciality ORDER BY unique_patients DESC LIMIT 40;

-- Q65  exec=90.900ms    plan=1.028ms
EXPLAIN ANALYZE
SELECT p.first, p.last, p.gender, COUNT(e.id) AS visits
FROM patients p JOIN encounters e ON p.id = e.patient
WHERE p.gender = 'M'
GROUP BY p.first, p.last, p.gender ORDER BY visits DESC LIMIT 100;

-- Q66  exec=343.631ms   plan=0.165ms
EXPLAIN ANALYZE
SELECT i.modality_description, COUNT(*) AS total_studies
FROM imaging_studies i
GROUP BY i.modality_description ORDER BY total_studies DESC;

-- Q67  exec=15.651ms    plan=0.278ms
EXPLAIN ANALYZE
SELECT m.description, COUNT(*) AS total_prescriptions
FROM medications m
WHERE m.start BETWEEN '2018-01-01' AND '2023-01-01'
GROUP BY m.description ORDER BY total_prescriptions DESC LIMIT 50;

-- Q68  exec=30.823ms    plan=4.419ms
EXPLAIN ANALYZE
SELECT p.first, p.last, a.description AS allergy, a.category
FROM patients p
JOIN encounters e ON p.id = e.patient
JOIN allergies a  ON e.id = a.encounter
WHERE a.category = 'medication' LIMIT 200;

-- Q69  exec=135.528ms   plan=0.274ms
EXPLAIN ANALYZE
SELECT c.description, COUNT(DISTINCT c.patient) AS affected_patients
FROM conditions c
WHERE c.start BETWEEN '2015-01-01' AND '2023-01-01'
GROUP BY c.description ORDER BY affected_patients DESC LIMIT 50;

-- Q70  exec=10.441ms    plan=0.275ms
EXPLAIN ANALYZE
SELECT e.patient, COUNT(e.id) AS total_encounters
FROM encounters e
WHERE e.start >= '2020-01-01'
GROUP BY e.patient ORDER BY total_encounters DESC LIMIT 100;

-- Q71  exec=21.809ms    plan=0.303ms
EXPLAIN ANALYZE
SELECT e.encounterclass, COUNT(*) AS total_encounters
FROM encounters e
WHERE e.start BETWEEN '2018-01-01' AND '2023-01-01'
GROUP BY e.encounterclass;

-- Q72  exec=567.103ms   plan=0.909ms
EXPLAIN ANALYZE
SELECT p.race, COUNT(DISTINCT p.id) AS patient_count
FROM patients p JOIN encounters e ON p.id = e.patient
GROUP BY p.race ORDER BY patient_count DESC;

-- Q73  exec=39.176ms    plan=0.247ms
EXPLAIN ANALYZE
SELECT c.code, c.description, COUNT(*) AS total
FROM conditions c
GROUP BY c.code, c.description ORDER BY total DESC LIMIT 20;

-- Q74  exec=3.778ms     plan=1.068ms
EXPLAIN ANALYZE
SELECT e.patient, e.start, pr.description
FROM encounters e JOIN procedures pr ON e.id = pr.encounter
WHERE pr.start BETWEEN '2020-01-01' AND '2022-01-01' LIMIT 400;

-- Q75  exec=315.990ms   plan=0.214ms
EXPLAIN ANALYZE
SELECT o.patient, COUNT(*) AS obs_count
FROM observations o
WHERE o.category = 'laboratory'
GROUP BY o.patient ORDER BY obs_count DESC LIMIT 50;

-- Q76  exec=2.263ms     plan=0.812ms
EXPLAIN ANALYZE
SELECT p.first, p.last, e.start, e.encounterclass
FROM patients p JOIN encounters e ON p.id = e.patient
WHERE e.encounterclass = 'inpatient' LIMIT 200;

-- Q77  exec=79.684ms    plan=0.213ms
EXPLAIN ANALYZE
SELECT pr.description, COUNT(*) AS total_procedures
FROM procedures pr
WHERE pr.start >= '2019-01-01'
GROUP BY pr.description ORDER BY total_procedures DESC LIMIT 30;

-- Q78  exec=1.162ms     plan=0.100ms
EXPLAIN ANALYZE
SELECT i.patient, i.description, i.date
FROM immunizations i WHERE i.date >= '2021-01-01' LIMIT 500;

-- Q79  exec=210.927ms   plan=3.433ms
EXPLAIN ANALYZE
SELECT e.patient,
       COUNT(DISTINCT pr.code) AS unique_procedures,
       COUNT(DISTINCT c.code)  AS unique_conditions
FROM encounters e
JOIN procedures pr ON e.id = pr.encounter
JOIN conditions c  ON e.id = c.encounter
WHERE e.start >= '2020-01-01'
GROUP BY e.patient LIMIT 100;

-- Q80  exec=571.295ms   plan=0.221ms
EXPLAIN ANALYZE
SELECT o.description, COUNT(*) AS reading_count
FROM observations o
WHERE o.type = 'numeric' AND o.category = 'laboratory'
GROUP BY o.description LIMIT 25;

-- Q81  exec=3.592ms     plan=0.947ms
EXPLAIN ANALYZE
SELECT p.first, p.last, p.birthdate, e.start
FROM patients p JOIN encounters e ON p.id = e.patient
WHERE e.start BETWEEN '2021-01-01' AND '2022-12-31'
AND p.gender = 'F' LIMIT 300;

-- Q82  exec=71.097ms    plan=0.950ms
EXPLAIN ANALYZE
SELECT m.description, COUNT(*) AS prescriptions
FROM medications m JOIN encounters e ON m.encounter = e.id
WHERE e.encounterclass = 'outpatient'
GROUP BY m.description ORDER BY prescriptions DESC LIMIT 40;

-- Q83  exec=214.874ms   plan=19.580ms
EXPLAIN ANALYZE
SELECT COUNT(DISTINCT e.patient) AS patients_with_imaging
FROM imaging_studies i JOIN encounters e ON i.encounter = e.id
WHERE i.date BETWEEN '2019-01-01' AND '2023-01-01';

-- Q84  exec=12.553ms    plan=0.313ms
EXPLAIN ANALYZE
SELECT e.patient, COUNT(e.id) AS total_encounters
FROM encounters e
WHERE e.start >= '2020-01-01'
GROUP BY e.patient ORDER BY total_encounters DESC LIMIT 50;

-- Q85  exec=104.202ms   plan=0.176ms
EXPLAIN ANALYZE
SELECT pr.description, COUNT(*) AS total_procedures
FROM procedures pr
GROUP BY pr.description ORDER BY total_procedures DESC LIMIT 30;

-- Q86  exec=11.654ms    plan=0.341ms
EXPLAIN ANALYZE
SELECT p.city, COUNT(DISTINCT p.id) AS patients
FROM patients p GROUP BY p.city ORDER BY patients DESC LIMIT 30;

-- Q87  exec=11.732ms    plan=1.409ms
EXPLAIN ANALYZE
SELECT e.patient, e.start, c.description, c.code
FROM encounters e JOIN conditions c ON e.id = c.encounter
WHERE c.code IN ('44054006','73211009','38341003') LIMIT 300;

-- Q88  exec=26.153ms    plan=0.417ms
EXPLAIN ANALYZE
SELECT o.patient, o.date, o.description, o.value
FROM observations o
WHERE o.description = 'Body Mass Index'
AND o.date BETWEEN '2018-01-01' AND '2023-01-01' LIMIT 500;

-- Q89  exec=77.547ms    plan=1.764ms
EXPLAIN ANALYZE
SELECT p.first, p.last,
       COUNT(DISTINCT e.id)   AS encounters,
       COUNT(DISTINCT m.code) AS medications
FROM patients p
JOIN encounters e  ON p.id = e.patient
JOIN medications m ON e.id = m.encounter
WHERE e.start >= '2019-01-01'
GROUP BY p.first, p.last ORDER BY encounters DESC LIMIT 50;

-- Q90  exec=152.117ms   plan=0.348ms
EXPLAIN ANALYZE
SELECT i.modality_description, i.bodysite_description, COUNT(*) AS total
FROM imaging_studies i
WHERE i.date BETWEEN '2020-01-01' AND '2023-01-01'
GROUP BY i.modality_description, i.bodysite_description
ORDER BY total DESC LIMIT 30;

-- Q91  exec=5.571ms     plan=2.864ms
EXPLAIN ANALYZE
SELECT e.patient, e.start, a.description AS allergy, m.description AS medication
FROM encounters e
JOIN allergies  a ON e.id = a.encounter
JOIN medications m ON e.id = m.encounter LIMIT 100;

-- Q92  exec=90.948ms    plan=0.967ms
EXPLAIN ANALYZE
SELECT pr.name, pr.speciality, e.encounterclass, COUNT(*) AS total
FROM providers pr JOIN encounters e ON pr.id = e.provider
GROUP BY pr.name, pr.speciality, e.encounterclass
ORDER BY total DESC LIMIT 40;

-- Q93  exec=27.140ms    plan=1.613ms
EXPLAIN ANALYZE
SELECT c.description, c.start, c.stop, e.encounterclass
FROM conditions c JOIN encounters e ON c.encounter = e.id
WHERE c.start >= '2021-01-01' LIMIT 300;

-- Q94  exec=1747.285ms  plan=0.274ms  ABSOLUTE SLOWEST — seq scan + external merge
EXPLAIN ANALYZE
SELECT o.patient, COUNT(DISTINCT o.code) AS unique_tests
FROM observations o
WHERE o.category = 'vital-signs'
GROUP BY o.patient ORDER BY unique_tests DESC LIMIT 50;

-- Q95  exec=89.960ms    plan=0.976ms
EXPLAIN ANALYZE
SELECT p.first, p.last, p.race, p.ethnicity, COUNT(e.id) AS total_visits
FROM patients p JOIN encounters e ON p.id = e.patient
GROUP BY p.first, p.last, p.race, p.ethnicity ORDER BY total_visits DESC LIMIT 50;

-- Q96  exec=12.791ms    plan=1.174ms  Merge Left Join
EXPLAIN ANALYZE
SELECT e.id, e.start, e.encounterclass,
       COUNT(DISTINCT c.code)  AS conditions,
       COUNT(DISTINCT pr.code) AS procedures
FROM encounters e
LEFT JOIN conditions c  ON e.id = c.encounter
LEFT JOIN procedures pr ON e.id = pr.encounter
WHERE e.start BETWEEN '2020-01-01' AND '2021-12-31'
GROUP BY e.id, e.start, e.encounterclass LIMIT 200;

-- Q97  exec=0.067ms     plan=1.552ms  3-table nested loop (0 rows matched)
EXPLAIN ANALYZE
SELECT m.description, m.start, p.first, p.last
FROM medications m
JOIN encounters e ON m.encounter = e.id
JOIN patients p   ON e.patient = p.id
WHERE m.start >= '2022-01-01' LIMIT 300;

-- Q98  exec=184.592ms   plan=0.281ms
EXPLAIN ANALYZE
SELECT o.code, o.description, COUNT(*) AS total_readings
FROM observations o
WHERE o.category = 'vital-signs'
AND o.date BETWEEN '2020-01-01' AND '2023-01-01'
GROUP BY o.code, o.description ORDER BY total_readings DESC LIMIT 20;

-- Q99  exec=52.471ms    plan=4.127ms
EXPLAIN ANALYZE
SELECT e.patient, e.start, e.encounterclass, pr.description AS procedure_done
FROM encounters e
JOIN procedures pr ON e.id = pr.encounter
JOIN conditions c  ON e.id = c.encounter
WHERE c.description ILIKE '%diabetes%' LIMIT 200;

-- Q100 exec=32.972ms    plan=4.082ms
EXPLAIN ANALYZE
SELECT p.first, p.last, e.start, o.description, o.value, o.units
FROM patients p
JOIN encounters e   ON p.id = e.patient
JOIN observations o ON e.id = o.encounter
WHERE o.description = 'Hemoglobin A1c/Hemoglobin.total in Blood'
LIMIT 200;
