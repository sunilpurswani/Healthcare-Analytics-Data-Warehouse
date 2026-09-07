# Data Warehouse Schema

The project uses beneficiary records as the central entity connecting the main healthcare claim datasets.

```mermaid
erDiagram
    Beneficiaries ||--o{ Inpatient_Claims : has
    Beneficiaries ||--o{ Outpatient_Claims : has
    Beneficiaries ||--o{ Carrier_Claims : has
    Beneficiaries ||--o{ Prescription_Drugs : has

    Beneficiaries {
        varchar Beneficiary_ID PK
        date Birth_Date
        date Death_Date
        char Sex
        int Race_Code
        int State_Code
        int County_Code
        int Diabetes_Flag
        int Cancer_Flag
        float Reimburse_IP
        float Reimburse_OP
        float Reimburse_Carrier
        int Year
    }

    Inpatient_Claims {
        bigint Claim_ID PK
        varchar Beneficiary_ID FK
        date Claim_From_Date
        date Claim_Through_Date
        float Claim_Payment_Amount
        varchar Diagnosis_Code
        int Procedure_Code
    }

    Outpatient_Claims {
        varchar Claim_ID
        varchar Beneficiary_ID FK
        date Claim_From_Date
        date Claim_Through_Date
        float Claim_Payment_Amount
        varchar Diagnosis_Code
    }

    Carrier_Claims {
        varchar Claim_ID PK
        varchar Beneficiary_ID FK
        date Claim_From_Date
        date Claim_Through_Date
        varchar Diagnosis_Code
        bigint Provider_NPI
        varchar HCPCS_Code
        float Line_NCH_Payment_Amount
    }

    Prescription_Drugs {
        int Drug_ID PK
        varchar Beneficiary_ID FK
        date Service_Date
        bigint Product_Service_ID
        int Quantity_Dispensed
        int Days_Supply
        float Patient_Payment_Amount
        float Total_Rx_Cost_Amount
    }
```

## Conceptual Design

The original project was designed as a constellation-style healthcare warehouse. Inpatient and outpatient claims formed the primary analytical fact areas, while shared healthcare dimensions such as beneficiaries, providers, diagnosis codes, procedure codes, pharmacies, and medication events supported cross-functional analysis.

The SQL implementation in this repository focuses on the tables directly used in the project analysis and dashboard.

## Relationships

- A beneficiary can have multiple inpatient claims.
- A beneficiary can have multiple outpatient claims.
- A beneficiary can have multiple carrier claims.
- A beneficiary can have multiple prescription drug events.
- Claim-level diagnosis and procedure attributes support clinical and utilization analysis.
- Reimbursement fields in the beneficiary data support financial comparisons across claim categories.
