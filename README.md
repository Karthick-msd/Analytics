<<<<<<< HEAD

# Data Mart 360

**A dbt + Databricks data platform orchestrated with Apache Airflow that turns 12 raw operational feeds into governed, tested, analytics-ready marts — including customer RFM segmentation and churn-risk scoring.**

> Built by [Karthick](https://github.com/Karthick-msd) to demonstrate practical data-engineering and analytics-engineering skills: automated ingestion, layered transformation, orchestration, data quality, column-level governance, change tracking, grain-safe modeling, and business-focused data marts.

---

## Table of Contents

* [What This Project Does](#what-this-project-does)
* [Architecture](#architecture)
* [End-to-End Pipeline](#end-to-end-pipeline)
* [Tech Stack](#tech-stack)
* [Data Domains](#data-domains)
* [Layer-by-Layer Design](#layer-by-layer-design)
* [Orchestration with Airflow](#orchestration-with-airflow)
* [Gold Layer: The Business Questions It Answers](#gold-layer-the-business-questions-it-answers)
* [Governance: Column-Level Masking](#governance-column-level-masking)
* [Change Tracking: SCD2 via Snapshots](#change-tracking-scd2-via-snapshots)
* [Data Ingestion Automation](#data-ingestion-automation)
* [Testing and Data Quality](#testing-and-data-quality)
* [Containerized Development Environment](#containerized-development-environment)
* [Dashboard](#dashboard)
* [Repository Structure](#repository-structure)
* [How to Run the Pipeline](#how-to-run-the-pipeline)
* [Known Gaps / What I'd Build Next](#known-gaps--what-id-build-next)
* [About Me](#about-me)

---

## What This Project Does

Twelve source feeds — customers, orders, payments, returns, subscriptions, products, inventory, support tickets, web sessions, marketing campaigns, HR attendance, and a date dimension — land as CSV files in a Databricks Volume and flow through a layered dbt transformation pipeline into business-ready marts.

The pipeline produces:

* **Customer RFM segmentation** using Recency, Frequency, and Monetary scoring
* **RFM scorecards** with quintile-based customer segmentation
* **Churn-risk signals** based on support-ticket activity and subscription status
* **Employee attendance streak analysis** using gaps-and-islands logic
* **Order fulfillment economics** with centralized net-revenue calculation
* **Governed customer data** using Unity Catalog column-level masking
* **Historical customer tracking** using dbt snapshots / SCD Type 2
* **Automated pipeline execution** through Apache Airflow

The objective is not simply to transform CSV files into tables. The project demonstrates how a real data platform can separate ingestion, storage, transformation, governance, validation, and orchestration concerns.

---

# Architecture

                           LOCAL WINDOWS MACHINE
                                   │
                                   │ CSV files
                                   ▼
                         Local Watch Folder
                                   │
                                   │ watchdog
                                   ▼
                    Python Upload Automation
                                   │
                                   │ Databricks Files REST API
                                   ▼
                         Databricks Volume
                                   │
                                   ▼
                              RAW LAYER
                         read_files() views
                                   │
                                   ▼
                            BRONZE LAYER
                     Incremental append-only Delta
                                   │
                                   ▼
                           STAGING LAYER
                   Clean / Parse / Deduplicate
                    / Mask / Standardize fields
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
             SCD2 Snapshot                  INTERMEDIATE
             Customers only             Grain-safe enrichment
                    │                             │
                    └──────────────┬──────────────┘
                                   ▼
                              GOLD LAYER
                     RFM / Churn / Scorecards
                                   │
                                   ▼
                              BI Dashboard


                 ORCHESTRATION / EXECUTION CONTROL
                 ----------------------------------

                  Windows Host
                       │
                       ▼
                  WSL2
                       │
                       ▼
                Docker Desktop
                       │
                       ▼
              Containerized Airflow
                       │
                       ▼
                  Airflow DAG
                       │
             ┌─────────┼──────────┐
             ▼         ▼          ▼
       Source Check  dbt Build  dbt Test
             │         │          │
             └─────────┴──────────┘
                       │
                       ▼
                Pipeline Completion
```

The orchestration layer is intentionally separated from the transformation layer:

* **Airflow** determines **when and in what order** pipeline tasks execute.
* **dbt** determines **how the data is transformed**.
* **Databricks** provides the distributed compute and Delta Lake platform.
* **Docker** provides a reproducible Airflow runtime.
* **WSL2 + Docker Desktop** provide the local development environment on Windows.

---

# End-to-End Pipeline

The complete pipeline follows this sequence:

1. CSV arrives in local watch folder
              │
              ▼
2. Watchdog detects new file
              │
              ▼
3. Python uploads file to Databricks Volume
              │
              ▼
4. Airflow starts pipeline
              │
              ▼
5. Source Check
              │
              ▼
6. dbt Build
              │
              ▼
7. dbt Test
              │
              ▼
8. Gold marts updated
              │
              ▼
9. BI dashboard consumes Gold layer

The Airflow DAG establishes the dependency chain:


source_check
      │
      ▼
  dbt_build
      │
      ▼
   dbt_test


This provides an explicit execution dependency instead of manually running dbt commands one after another.

---

# Tech Stack

| Layer                       | Tools                                         |
| --------------------------- | --------------------------------------------- |
| **Cloud Data Platform**     | Databricks                                    |
| **Compute**                 | Apache Spark / Spark SQL                      |
| **Storage Format**          | Delta Lake                                    |
| **Transformation**          | dbt                                           |
| **Orchestration**           | Apache Airflow                                |
| **Containerization**        | Docker                                        |
| **Local Linux Environment** | WSL2                                          |
| **Container Runtime**       | Docker Desktop                                |
| **Governance**              | Databricks Unity Catalog                      |
| **Change Tracking**         | dbt snapshots                                 |
| **Data Quality**            | dbt schema tests + dbt_utils                  |
| **Ingestion Automation**    | Python + watchdog + Databricks Files REST API |
| **Version Control**         | Git / GitHub                                  |
| **BI / Reporting**          | Dashboard layer built on Gold marts           |

---

# Data Domains

The project currently models the following domains:

**Customers · Orders · Payments · Returns · Subscriptions · Products · Inventory · Support Tickets · Web Sessions · Marketing Campaigns · HR Attendance · Date**

---

# Layer-by-Layer Design

## Raw

`read_files()` reads each source CSV directly from the Databricks Volume with schema inference.

The raw layer is implemented as lightweight views and is intentionally kept close to the incoming source representation.

The purpose of Raw is to preserve a simple path back to the source rather than immediately applying business logic.

---

## Bronze

Bronze is materialized as an **incremental, append-only Delta table**.

The Bronze layer does not attempt to clean or reinterpret the source data.

Each row is stamped with metadata such as:

* `_bronze_loaded_at`
* `_dbt_run_id`
* `_source_table`

The design principle is:

> Bronze is the call recording of the pipeline — preserve what the source actually sent and when it arrived before applying transformations.

This makes the Bronze layer useful for debugging ingestion and downstream transformation issues.

---

## Staging

This is where most source-level cleaning and standardization happens.

### Null normalization

The `parse_null()` macro converts multiple representations such as:


NA
N/A
n/a
--
unknown
blank strings

into actual SQL `NULL` values.

### Multi-format dates

The `parse_multi_format_date()` macro handles inconsistent date representations by attempting multiple formats using `TRY_TO_DATE()` and `COALESCE()`.

Examples include:


yyyy-MM-dd
MM/dd/yyyy
dd-MMM-yyyy
MMMM d, yyyy


### Additional transformations

The staging layer also performs:

* Data type normalization
* Deduplication
* Customer-name backfill
* Column standardization
* Clustering on commonly filtered/joined columns
* Unity Catalog masking on sensitive fields
* Schema-level quality validation

---

# Intermediate Layer

The Intermediate layer exists to create reusable, grain-safe business transformations before data reaches Gold.

Examples include:

### `int_customers_orders`

Maintains a customer-level grain after deduplicating customer records before joining them to orders.

It derives:

* Customer tenure
* New-customer order indicators
* Customer-order enrichment

### `int_orders_fulfilment`

Aggregates payment and return information to **one row per order before joining**.

This prevents fan-out caused by multiple payments or returns for the same order.

The model centrally calculates:

net_revenue = paid_amount - refunded_amount


This ensures downstream marts do not independently recalculate the same business definition.

### `int_product_inventory`

Maintains warehouse-level grain because downstream warehouse operations require that level of detail.

### `int_employee_attendance`

Transforms daily attendance records into employee-level summary metrics and mismatch statistics.

---

# Orchestration with Airflow

Apache Airflow is used as the workflow orchestration layer for the project.

Instead of manually executing:

# bash
dbt build
dbt test

the pipeline is controlled by an Airflow DAG.

The current workflow is intentionally simple and demonstrates the core orchestration pattern:


Source Check
     │
     ▼
dbt Build
     │
     ▼
dbt Test

## Source Check

The first task validates that the required input/source data is available before downstream transformation begins.

This creates a gate between ingestion and transformation.


Source available?
      │
   ┌──┴──┐
   │     │
  YES    NO
   │     │
   ▼     ▼
dbt build  Stop pipeline
```

---

## dbt Build

After the source validation passes, Airflow triggers the dbt transformation workflow.

Conceptually:

```bash
dbt build
```

`dbt build` is used because it provides a single entry point for executing the required dbt resources according to dependency order.

This includes the project's layered transformations, snapshots, and relevant tests associated with the build process.

---

## dbt Test

After the build completes successfully, Airflow executes the validation stage.

Conceptually:

```bash
dbt test
```

This makes data quality a pipeline dependency rather than an optional manual step.

The pipeline therefore follows:


Source Check
     ↓
Transformation
     ↓
Validation

A successful DAG run means the pipeline passed through the required execution stages.

---

# Airflow + Docker + WSL2

Airflow is run in a containerized local development environment.

The environment is structured as:

Windows
   │
   ▼
WSL2
   │
   ▼
Docker Desktop
   │
   ▼
Airflow Containers
   │
   ├── Airflow Web UI
   ├── Scheduler
   └── Task execution environment
```

Docker provides a consistent runtime for Airflow rather than installing the complete Airflow stack directly into the Windows Python environment.

This separation is useful because Airflow dependencies and supporting services remain isolated from the host machine.

The project therefore demonstrates familiarity with:

* Docker Compose-based service management
* Containerized Airflow execution
* WSL2-based Linux tooling on Windows
* Airflow DAG development
* Task dependency management
* Running dbt workloads from orchestration infrastructure

---

# Why Airflow Was Added

Databricks can itself orchestrate jobs and pipelines, but Airflow was added to demonstrate familiarity with an orchestration tool widely used for workflow dependency management across heterogeneous systems.

The architectural separation is:

Airflow
    = orchestration

dbt
    = transformation

Databricks
    = compute + storage platform

Python
    = ingestion automation

This allows the same DAG pattern to be extended later with additional tasks such as:

File arrival
    ↓
Source validation
    ↓
Databricks ingestion
    ↓
dbt build
    ↓
dbt test
    ↓
Data quality alert
    ↓
BI refresh

---

# Gold Layer: The Business Questions It Answers

## `RFM.sql`

Calculates customer-level Recency, Frequency, and Monetary metrics.

The model first works at the correct order/customer grain before applying window logic, avoiding a common issue where multi-line orders are unintentionally double-counted.

---

## `rfm_scorecard.sql`

Applies `NTILE(5)` to generate quintile scores for:

* Recency
* Frequency
* Monetary value

The resulting customer groups include segments such as:

* **Champions**
* **At Risk**
* **Hibernating / Lost**
* **New / Promising**
* **Needs Attention**

---

## `churn_risk.sql`

Combines support-ticket activity with subscription status to identify customers with potential churn-risk signals.

---

## `churn_reason.sql`

Uses gaps-and-islands logic to identify attendance streaks.

The transformation:

1. Detects a new streak when a sufficient gap occurs.
2. Creates a running streak identifier.
3. Collapses records into one row per streak.
4. Calculates streak duration.
5. Ranks the longest streaks by employee.

---

# Governance: Column-Level Masking

Sensitive fields are protected through Databricks Unity Catalog rather than maintaining separate masked and unmasked physical tables.

For example, the customer ID masking function follows the concept:

```sql
CREATE OR REPLACE FUNCTION data_mart.governance.mask_customer_id(customer_id STRING)
RETURNS STRING
RETURN CASE
    WHEN is_account_group_member('pii_readers')
        THEN customer_id
    ELSE '*****'
END
```

The staging table attaches the function to the protected column:

```sql
ALTER TABLE {{ this }}
ALTER COLUMN customer_id
SET MASK data_mart.governance.mask_customer_id
```

This means access control is enforced at the data-platform layer rather than relying entirely on application logic.

Users without the required access group see a masked value instead of the original customer ID.

---

# Change Tracking: SCD2 via Snapshots

The `customers_snapshot` uses dbt's **check strategy** to maintain historical changes.

This approach was selected because the source does not provide a reliable mutable `updated_at` timestamp.

The snapshot checks fields such as:


customer_name
email_id
phone_number
city
state
country

When one of these tracked attributes changes, a new historical version is created.

This provides SCD Type 2 behavior with historical validity information.

A practical implementation lesson from the project was that using a static field such as `signup_date` as an `updated_at` timestamp would not reliably detect changes to existing customer records.

---

# Data Ingestion Automation

A Python script:


scripts/watch_and_upload.py

uses `watchdog` to monitor a local folder for new CSV files.

The script:

1. Detects a new file.
2. Waits for the file lock to clear.
3. Retries if the file is still being written.
4. Uploads the file to a Databricks Volume.
5. Makes the data available for downstream processing.

The Databricks Files REST API is used for file transfer.

This creates an automated path from:


Local CSV
   ↓
Watchdog
   ↓
Databricks Volume
   ↓
Raw
   ↓
Bronze
   ↓
Staging
   ↓
Intermediate
   ↓
Gold

---

# Testing and Data Quality

The project uses dbt tests to validate data quality.

Examples include:

### Primary-key validation


unique
not_null

on important identifiers such as:

customer_id
employee_id


### Accepted values

Categorical values such as:

```text
customer_segment
order_status
subscription_status
```

are validated against expected values.

### Data-format validation

`dbt_utils.expression_is_true` is used to validate numeric-as-string fields before they propagate to downstream models.

### Empty-string validation

`dbt_utils.not_empty_string` is used on required textual fields such as email.

### Metadata

Column-level metadata includes information such as:

```text
contains_pii
owner
source_system
```

This supports documentation and governance.

---

# Containerized Development Environment

The local orchestration environment uses:

```text
Windows
   ↓
WSL2
   ↓
Docker Desktop
   ↓
Airflow
```

Docker is used to avoid installing Airflow and all of its dependencies directly into the host Python environment.

This also makes it easier to reproduce the Airflow environment and separate orchestration dependencies from the rest of the project.

The Airflow project is maintained separately from the dbt project configuration.

Conceptually:

```text
airflow_project/
│
├── dags/
├── logs/
├── plugins/
├── config/
├── docker-compose.yaml
└── .env
```

The DAG definitions live in the `dags/` directory.

---

# Dashboard

A BI layer sits on top of the Gold marts and provides business-facing views of the transformed data.

The dashboard currently includes:

* **Customer value by RFM segment**
* **Average leave duration by department**
* **Support tickets by subscription status**

![Data Mart 360 dashboard — RFM segment value, average leave duration by department, and raised tickets by subscription status](assets/dashboard-overview.png)

The Gold layer therefore acts as the analytical contract between the transformation pipeline and the reporting layer.

---

# Repository Structure

```text
data_mart_360/

├── models/
│   ├── raw/
│   │   └── # thin read_files() views per source
│   │
│   ├── bronze/
│   │   └── # incremental append-only Delta models
│   │
│   ├── staging/
│   │   └── # cleaned, parsed, masked, deduped models
│   │
│   ├── intermediate/
│   │   └── # grain-safe fact/dimension enrichment
│   │
│   └── gold/
│       └── # RFM, churn, scorecards, business marts
│
├── snapshots/
│   └── customers_snapshot.sql
│
├── macros/
│   ├── governance/
│   │   ├── mask_customer_id.sql
│   │   └── grant_pii_access.sql
│   │
│   ├── parse_null.sql
│   └── parse_multi_format_date.sql
│
├── scripts/
│   └── watch_and_upload.py
│
├── seeds/
├── tests/
├── analyses/
└── dbt_project.yml
```

The Airflow orchestration environment is maintained separately:

```text
airflow_project/

├── dags/
│   └── data_mart_360_dag.py
│
├── logs/
├── plugins/
├── config/
├── docker-compose.yaml
└── .env
```

---

# How to Run the Pipeline

## 1. Start Docker Desktop

Docker Desktop provides the container runtime used by the Airflow environment.

Ensure Docker is running and configured to use the Linux container environment.

---

## 2. Start the Airflow environment

From the Airflow project directory:

```bash
docker compose up -d
```

The Airflow services start inside Docker containers.

The Airflow web interface can then be used to view the DAG, trigger runs, and inspect task logs.

---

## 3. Trigger the DAG

Run the `data_mart_360` DAG from the Airflow UI.

The expected execution flow is:

```text
source_check
      ↓
dbt_build
      ↓
dbt_test
```

---

## 4. Validate the pipeline

Airflow task logs can be used to verify:

* Source availability
* dbt execution
* Transformation success
* Test results
* Task dependencies
* Pipeline failures

This makes Airflow the control plane for the complete transformation workflow.

---

# Current Engineering Design

The current architecture intentionally separates responsibilities:

| Component             | Responsibility                           |
| --------------------- | ---------------------------------------- |
| **Python / watchdog** | Detect and upload source files           |
| **Databricks Volume** | Source-file landing area                 |
| **Raw**               | Source representation                    |
| **Bronze**            | Append-only historical landing layer     |
| **Staging**           | Cleaning and standardization             |
| **Intermediate**      | Business enrichment and grain-safe joins |
| **Gold**              | Business-ready analytical marts          |
| **dbt**               | Transformation framework                 |
| **Airflow**           | Workflow orchestration                   |
| **Docker**            | Containerized runtime                    |
| **WSL2**              | Linux development environment on Windows |
| **Unity Catalog**     | Governance and access control            |
| **dbt tests**         | Data-quality validation                  |
| **BI Dashboard**      | Business consumption                     |

---

# Known Gaps / What I'd Build Next

The main orchestration layer is now implemented, but several areas can still be strengthened.

## 1. Secrets hygiene

The Databricks token/workspace configuration used by the ingestion script should be moved completely into environment variables or a secrets manager rather than being kept in source code.

---

## 2. CI/CD

Add a GitHub Actions workflow to automatically run:

```text
dbt build
dbt test
```

for pull requests and/or deployments.

The next step would be to connect code changes to controlled deployment of the transformation layer.

---

## 3. More business-rule tests

Expand the `tests/` directory with singular/custom tests for business rules such as:

* Revenue consistency
* Invalid subscription states
* Impossible dates
* Duplicate business keys
* Unexpected negative values

---

## 4. Seeds

Move static business mappings and reference values into version-controlled dbt seed files rather than keeping all mappings inside SQL `CASE` statements.

---

## 5. dbt documentation and lineage

Generate and publish `dbt docs` to expose:

* Model dependencies
* Column documentation
* Tests
* Data lineage
* Sources

---

## 6. More advanced orchestration

The current DAG intentionally demonstrates the fundamental dependency pattern:

```text
Source Check
      ↓
dbt Build
      ↓
dbt Test
```

The next orchestration iteration could introduce:

```text
File Sensor
      ↓
Ingestion
      ↓
Source Validation
      ↓
dbt Build
      ↓
dbt Test
      ↓
Data Quality Gate
      ↓
Notification / Alert
      ↓
BI Refresh
```

This would demonstrate more advanced Airflow concepts such as sensors, branching, retries, failure handling, notifications, and external task dependencies.

---

# Why This Project Is Relevant to Data Engineering

This project demonstrates more than SQL transformations.

It covers multiple layers of a modern data platform:

```text
                DATA ENGINEERING
                       │
       ┌───────────────┼────────────────┐
       │               │                │
   Ingestion      Transformation   Orchestration
       │               │                │
     Python           dbt             Airflow
       │               │                │
 Databricks        Databricks         Docker
 Volume            Spark SQL           WSL2
       │               │                │
       └───────────────┼────────────────┘
                       │
                 Data Quality
                       │
                    dbt tests
                       │
                 Data Governance
                       │
                 Unity Catalog
                       │
                 Business Marts
                       │
                    BI Layer
```

The project therefore demonstrates an end-to-end understanding of how data moves from source files to analytical consumption.

---

# About Me

I have around 7–8 years of operations experience in healthcare records and insurance-related processing, including team leadership, SLA ownership, process improvement, and large-scale data-quality work.

My transition into data engineering is focused on understanding the engineering decisions behind a pipeline rather than only making a query or model run.

This project reflects that approach through practical implementation of:

* SQL transformation
* dbt
* Databricks
* Delta Lake
* Airflow
* Docker
* WSL2
* Python
* Data quality
* Data governance
* SCD Type 2
* Incremental processing
* Grain-safe data modeling
* Business analytics

Open to **Analytics Engineer**, **Data Analyst**, and **Data Engineer** roles.

**Coimbatore-based or remote (India).**

---

## GitHub

[GitHub — Karthick-msd](https://github.com/Karthick-msd)

---

## Project Summary

**Data Mart 360 is an end-to-end data platform project demonstrating ingestion, transformation, governance, testing, and orchestration using Python, Databricks, dbt, Airflow, Docker, and WSL2.**

The core pipeline is:

```text
CSV
  ↓
Python Watchdog
  ↓
Databricks Volume
  ↓
Raw
  ↓
Bronze
  ↓
Staging
  ↓
Intermediate
  ↓
Gold
  ↓
BI Dashboard

Orchestrated by:

Airflow
  ↓
Source Check
  ↓
dbt Build
  ↓
dbt Test
```
=======
Welcome to your new dbt project!

### Using the starter project

Try running the following commands:
- dbt run
- dbt test


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
>>>>>>> 23ecdbe372044b56d1981a2241350cc956dbff9f
