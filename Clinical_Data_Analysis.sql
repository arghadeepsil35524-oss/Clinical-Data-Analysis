-- Data Cleaning 

-- Check for Duplicate Patient IDs

SELECT
    Patient_ID,
    COUNT(*) AS Duplicate_Count
FROM patient_data
GROUP BY Patient_ID
HAVING COUNT(*) > 1;

-- Find Missing Values

SELECT *
FROM patient_data
WHERE Age IS NULL
   OR Gender IS NULL
   OR Disease IS NULL
   OR BMI IS NULL;
   
-- Replace NULL BMI with Average BMI

set sql_safe_updates = 0;

UPDATE patient_data
SET BMI = (
    SELECT AVG(BMI)
    FROM (
        SELECT BMI
        FROM patient_data
        WHERE BMI IS NOT NULL
    ) AS avg_bmi
)
WHERE BMI IS NULL;

-- Standardize Gender Values

UPDATE patient_data
SET Gender =
CASE
    WHEN Gender IN ('M','Male','male') THEN 'Male'
    WHEN Gender IN ('F','Female','female') THEN 'Female'
    ELSE 'Other'
END;

-- Remove Invalid Ages

DELETE
FROM patient_data
WHERE Age < 0
   OR Age > 120;
   
-- Find Blank Values

SELECT *
FROM patient_data
WHERE TRIM(Disease) = '';

-- Replace Missing Country

UPDATE hospital_data
SET Country = 'Unknown'
WHERE Country IS NULL;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Some SQL Queries

-- Display all records from patient_data

SELECT * FROM patient_data;

-- Display patients receiving Drug A

SELECT *
FROM treatment_data
WHERE Treatment_Group = 'Drug A';

-- Display patients with Blood Pressure greater than 140

SELECT *
FROM treatment_data
WHERE Blood_Pressure > 140;

-- Find distinct diseases

SELECT DISTINCT Disease
FROM patient_data;

-- Display first 10 records

SELECT *
FROM patient_data
LIMIT 10;

-- Count total patients

SELECT COUNT(*) AS Total_Patients
FROM patient_data;

-- Average efficacy score

SELECT AVG(Efficacy_Score) AS Avg_Efficacy
FROM treatment_data;

-- Average BMI by disease

SELECT Disease,
AVG(BMI) AS Avg_BMI
FROM patient_data
GROUP BY Disease;

-- Number of patients in each country

SELECT Country,
COUNT(*) AS Total_patients
FROM hospital_data
GROUP BY Country;

-- Diseases having more than 50 patients

SELECT Disease,
COUNT(*) AS Total_patients
FROM patient_data
GROUP BY Disease
HAVING COUNT(*) > 50;

-- Days since enrollment 

SELECT Trial_ID,
DATEDIFF(CURDATE(), Enrollment_Date) AS Days
FROM hospital_data;

-- Categorize patients based on age

SELECT Patient_ID,
Age,
CASE
WHEN Age < 30 THEN 'Young'
WHEN Age BETWEEN 30 AND 60 THEN 'Adult'
ELSE 'Senior'
END AS Age_Group
FROM patient_data;

-- Find patients with ongoing trials

SELECT p.Patient_ID,
p.Disease,
h.Trial_Status
FROM patient_data p
JOIN treatment_data t
ON p.Patient_ID=t.Patient_ID
JOIN hospital_data h
ON t.Trial_ID=h.Trial_ID
WHERE h.Trial_Status='Ongoing';

-- Display patient, treatment and hospital information

SELECT p.Patient_ID,
p.Disease,
t.Treatment_Group,
h.Country,
h.Trial_Status
FROM patient_data p
JOIN treatment_data t
ON p.Patient_ID=t.Patient_ID
JOIN hospital_data h
ON t.Trial_ID=h.Trial_ID;

-- Find patients older than average age

SELECT *
FROM patient_data
WHERE Age >
(
SELECT AVG(Age)
FROM patient_data
);

-- Rank patients based on efficacy score

SELECT Patient_ID,
Efficacy_Score,
RANK() OVER(ORDER BY Efficacy_Score DESC) AS Ranking
FROM treatment_data;

-- Top efficacy score in each treatment group

WITH Ranked AS
(
SELECT *,
ROW_NUMBER() OVER
(
PARTITION BY Treatment_Group
ORDER BY Efficacy_Score DESC
) AS rn
FROM treatment_data
)

SELECT *
FROM Ranked
WHERE rn=1;

-- Percentage of patients with adverse events

SELECT
ROUND(
100.0 * SUM(CASE WHEN Adverse_Event='Yes' THEN 1 ELSE 0 END)
/
COUNT(*),2
) AS Adverse_Event_Percentage
FROM treatment_data;

-- Top 5 most expensive treatments

SELECT *
FROM treatment_data
ORDER BY Cost_USD DESC
LIMIT 5;

-- Create a view showing clinical trial statistics by country.

CREATE VIEW vw_country_trial_summary AS
SELECT
    h.Country,
    COUNT(DISTINCT h.Trial_ID) AS Total_Trials,
    COUNT(DISTINCT t.Patient_ID) AS Total_Patients,
    AVG(t.Efficacy_Score) AS Average_Efficacy,
    SUM(t.Cost_USD) AS Total_Treatment_Cost
FROM hospital_data h
JOIN treatment_data t
ON h.Trial_ID = t.Trial_ID
GROUP BY h.Country;

SELECT * FROM vw_country_trial_summary;

-- Create a view joining all three tables.

CREATE VIEW vw_clinical_trial_report AS
SELECT
    p.Patient_ID,
    p.Disease,
    p.Age,
    p.Gender,
    t.Treatment_Group,
    t.Efficacy_Score,
    t.Cost_USD,
    h.Study_Site,
    h.Country,
    h.Trial_Status
FROM patient_data p
JOIN treatment_data t
ON p.Patient_ID = t.Patient_ID
JOIN hospital_data h
ON t.Trial_ID = h.Trial_ID;

SELECT * FROM vw_clinical_trial_report;

