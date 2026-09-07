-- Healthcare Analytics Data Warehouse
-- Author: Sunil Purswani

CREATE DATABASE IF NOT EXISTS MedicareSystem;
USE MedicareSystem;

-- ============================================================
-- TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS Beneficiaries (
    Beneficiary_ID VARCHAR(50) PRIMARY KEY,
    Birth_Date DATE,
    Death_Date DATE NULL,
    Sex CHAR(1),
    Race_Code INT,
    ESRD_Indicator CHAR(1),
    State_Code INT,
    County_Code INT,
    HI_Coverage_Months INT,
    SMI_Coverage_Months INT,
    HMO_Coverage_Months INT,
    Plan_Coverage_Months INT,
    Alzheimer_Flag INT,
    CHF_Flag INT,
    Chronic_Kidney_Flag INT,
    Cancer_Flag INT,
    COPD_Flag INT,
    Depression_Flag INT,
    Diabetes_Flag INT,
    Ischemic_Heart_Flag INT,
    Osteoporosis_Flag INT,
    RA_OA_Flag INT,
    Stroke_TIA_Flag INT,
    Reimburse_IP FLOAT,
    Res_IP FLOAT,
    PPP_IP FLOAT,
    Reimburse_OP FLOAT,
    Res_OP FLOAT,
    PPP_OP FLOAT,
    Reimburse_Carrier FLOAT,
    Res_Carrier FLOAT,
    PPP_Carrier FLOAT,
    Year INT
);

CREATE TABLE IF NOT EXISTS Carrier_Claims (
    Claim_ID VARCHAR(50) PRIMARY KEY,
    Beneficiary_ID VARCHAR(50) NOT NULL,
    Claim_From_Date DATE,
    Claim_Through_Date DATE,
    Diagnosis_Code VARCHAR(10),
    Provider_NPI BIGINT,
    HCPCS_Code VARCHAR(10),
    Line_NCH_Payment_Amount FLOAT,
    FOREIGN KEY (Beneficiary_ID) REFERENCES Beneficiaries(Beneficiary_ID)
);

CREATE TABLE IF NOT EXISTS Inpatient_Claims (
    Claim_ID BIGINT PRIMARY KEY,
    Beneficiary_ID VARCHAR(50) NOT NULL,
    Claim_From_Date DATE,
    Claim_Through_Date DATE,
    Claim_Payment_Amount FLOAT,
    Diagnosis_Code VARCHAR(10),
    Procedure_Code INT,
    FOREIGN KEY (Beneficiary_ID) REFERENCES Beneficiaries(Beneficiary_ID)
);

CREATE TABLE IF NOT EXISTS Outpatient_Claims (
    Claim_ID VARCHAR(255),
    Beneficiary_ID VARCHAR(50) NOT NULL,
    Claim_From_Date DATE,
    Claim_Through_Date DATE,
    Claim_Payment_Amount FLOAT,
    Diagnosis_Code VARCHAR(10),
    FOREIGN KEY (Beneficiary_ID) REFERENCES Beneficiaries(Beneficiary_ID)
);

CREATE TABLE IF NOT EXISTS Prescription_Drugs (
    Drug_ID INT AUTO_INCREMENT PRIMARY KEY,
    Beneficiary_ID VARCHAR(50) NOT NULL,
    Service_Date DATE,
    Product_Service_ID BIGINT,
    Quantity_Dispensed INT,
    Days_Supply INT,
    Patient_Payment_Amount FLOAT,
    Total_Rx_Cost_Amount FLOAT,
    FOREIGN KEY (Beneficiary_ID) REFERENCES Beneficiaries(Beneficiary_ID)
);

-- The cleaned CMS synthetic CSV files can be loaded using MySQL Workbench
-- or LOAD DATA LOCAL INFILE after updating the paths for the local system.

-- ============================================================
-- BUSINESS ANALYSIS
-- ============================================================

-- Query 1: Total inpatient cost by demographic group
SELECT
    b.Sex AS Gender,
    b.Race_Code AS Race,
    SUM(ic.Claim_Payment_Amount) AS Total_Inpatient_Cost
FROM Beneficiaries b
JOIN Inpatient_Claims ic
    ON b.Beneficiary_ID = ic.Beneficiary_ID
GROUP BY b.Sex, b.Race_Code
ORDER BY Total_Inpatient_Cost DESC;

-- Query 2: Average reimbursement by claim type
SELECT
    'Inpatient' AS Claim_Type,
    AVG(b.Reimburse_IP) AS Avg_Reimbursement
FROM Beneficiaries b
UNION ALL
SELECT
    'Outpatient' AS Claim_Type,
    AVG(b.Reimburse_OP) AS Avg_Reimbursement
FROM Beneficiaries b
UNION ALL
SELECT
    'Carrier' AS Claim_Type,
    AVG(b.Reimburse_Carrier) AS Avg_Reimbursement
FROM Beneficiaries b;

-- Query 3: Claims for beneficiaries with diabetes or cancer
SELECT
    b.Beneficiary_ID,
    b.Diabetes_Flag,
    b.Cancer_Flag,
    COUNT(DISTINCT ic.Claim_ID) AS Inpatient_Claims,
    COUNT(DISTINCT op.Claim_ID) AS Outpatient_Claims,
    COUNT(DISTINCT cc.Claim_ID) AS Carrier_Claims
FROM Beneficiaries b
LEFT JOIN Inpatient_Claims ic
    ON b.Beneficiary_ID = ic.Beneficiary_ID
LEFT JOIN Outpatient_Claims op
    ON b.Beneficiary_ID = op.Beneficiary_ID
LEFT JOIN Carrier_Claims cc
    ON b.Beneficiary_ID = cc.Beneficiary_ID
WHERE b.Diabetes_Flag = 1
   OR b.Cancer_Flag = 1
GROUP BY
    b.Beneficiary_ID,
    b.Diabetes_Flag,
    b.Cancer_Flag
ORDER BY
    Inpatient_Claims DESC,
    Outpatient_Claims DESC,
    Carrier_Claims DESC;

-- Query 4: Average claim duration by claim type
-- The metric is calculated from claim-through date minus claim-from date.
SELECT
    'Inpatient' AS Claim_Type,
    AVG(DATEDIFF(ic.Claim_Through_Date, ic.Claim_From_Date)) AS Avg_Claim_Duration_Days
FROM Inpatient_Claims ic
UNION ALL
SELECT
    'Outpatient' AS Claim_Type,
    AVG(DATEDIFF(op.Claim_Through_Date, op.Claim_From_Date)) AS Avg_Claim_Duration_Days
FROM Outpatient_Claims op
UNION ALL
SELECT
    'Carrier' AS Claim_Type,
    AVG(DATEDIFF(cc.Claim_Through_Date, cc.Claim_From_Date)) AS Avg_Claim_Duration_Days
FROM Carrier_Claims cc;
