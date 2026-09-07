# Healthcare Analytics Data Warehouse

I designed and implemented a healthcare analytics data warehouse using CMS synthetic Medicare claims data. The project combines data preprocessing in R, relational data modeling in MySQL, SQL-based analysis, and an interactive R Shiny dashboard.

## Project Overview

The project uses CMS Synthetic Claims Data Files for beneficiaries in the Mountain and Pacific regions, covering 2008–2010. The source data includes beneficiary summary records, inpatient claims, outpatient claims, carrier claims, and prescription drug events.

```text
CMS Synthetic Claims Data
        ↓
R / RStudio
Filtering, cleaning and merging
        ↓
MySQL Healthcare Data Warehouse
        ↓
SQL Business Queries
        ↓
R Shiny Dashboard
```

## Data Warehouse Design

The conceptual model follows a constellation-style design centered on healthcare claims. Inpatient and outpatient claims are the primary analytical fact areas, with beneficiary, provider, diagnosis, procedure, pharmacy, carrier-claim, and prescription-drug information providing additional context.

The MySQL implementation in this repository includes:

- `Beneficiaries`
- `Inpatient_Claims`
- `Outpatient_Claims`
- `Carrier_Claims`
- `Prescription_Drugs`

See [`docs/schema.md`](./docs/schema.md) for the warehouse relationship diagram and table details.

## Data Preparation

The source files were processed in R before loading into MySQL. The preparation workflow included:

- Filtering CMS synthetic data to the assigned Mountain and Pacific states
- Selecting relevant beneficiary and claims fields
- Combining data across multiple years and samples
- Removing duplicate and irrelevant records
- Handling missing values
- Standardizing date and numeric formats
- Exporting cleaned files for database loading

## Business Analysis

### 1. Inpatient Cost by Demographic Group

Calculates total inpatient claim cost by sex and race code to compare healthcare spending patterns across demographic groups.

### 2. Average Reimbursement by Claim Type

| Claim Type | Average Reimbursement |
|---|---:|
| Inpatient | 1,949.63 |
| Outpatient | 547.91 |
| Carrier | 1,002.45 |

### 3. Claims for Beneficiaries with Chronic Conditions

Counts inpatient, outpatient, and carrier claims for beneficiaries flagged for diabetes or cancer. A sample of the query output is included in the `results/` folder.

### 4. Average Claim Duration

Uses the difference between claim-through and claim-from dates to compare the average claim span across claim types.

| Claim Type | Average Duration (Days) |
|---|---:|
| Inpatient | 5.8001 |
| Outpatient | 0.7679 |
| Carrier | 0.1295 |

## R Shiny Dashboard

The dashboard provides interactive views of the warehouse results, including:

- Inpatient costs by demographic group
- Outpatient claims distribution by diagnosis code
- Average reimbursement by claim type
- Average claim duration by claim type

Database credentials are read from environment variables and are not stored in the repository.

## Tech Stack

- **Database:** MySQL
- **SQL:** Schema design, joins, aggregations, unions, and analytical queries
- **Data Processing:** R / RStudio
- **Dashboard:** R Shiny
- **Visualization:** ggplot2
- **Database Connectivity:** DBI, RMySQL
- **Interactive Tables:** DT

## Repository Structure

```text
Healthcare-Analytics-Data-Warehouse/
├── README.md
├── .env.example
├── .gitignore
├── docs/
│   └── schema.md
├── sql/
│   └── healthcare_data_warehouse.sql
├── r/
│   └── healthcare_dashboard.R
└── results/
    ├── query1_inpatient_cost_by_demographics.csv
    ├── query2_average_reimbursement.csv
    ├── query3_chronic_condition_claims_sample.csv
    └── query4_average_claim_duration.csv
```

## Running the Project

1. Create the MySQL database and tables using `sql/healthcare_data_warehouse.sql`.
2. Load the cleaned CMS synthetic claims files into the corresponding tables.
3. Copy `.env.example` to `.env` and add the local MySQL credentials.
4. Install the required R packages:

```r
install.packages(c("shiny", "DBI", "RMySQL", "ggplot2", "DT", "dotenv"))
```

5. Run the dashboard:

```r
shiny::runApp("r/healthcare_dashboard.R")
```

## Data Note

The original CMS synthetic claims datasets are not included because of their size. The repository includes SQL analysis outputs used to demonstrate the project results.

## Author

Author: Sunil Purswani
