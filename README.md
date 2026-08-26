# Liquibase + Snowflake GitHub Actions Starter

This starter deploys the `employee_information_bronze` table to Snowflake through Liquibase and GitHub Actions.

For the complete beginner setup, follow [`docs/complete-setup-guide.md`](docs/complete-setup-guide.md).

## Target setup

* Repository: GitHub
* Authentication: GitHub Actions OIDC / Snowflake workload identity federation
* Branches: `feature/*`, `dev`, `main`
* Merge into `dev`: automatically deploys to `SNOWFLAKE_LEARNING_DB_DEV`
* Merge into `main`: automatically deploys to `SNOWFLAKE_LEARNING_DB_PROD`
* Schema: `trading_use_case`
* Table: `employee_information_bronze`

The database name is selected by the GitHub Environment variable `SNOWFLAKE_DATABASE` and passed to Liquibase as the `${database_name}` changelog parameter.

## Repository layout

```text
.
├── .github/workflows/deploy.yml
├── liquibase/
│   ├── changelog-root.xml
│   ├── liquibase.properties.example
│   └── objects/trading_use_case/tables/
├── scripts/
├── snowflake/01_bootstrap_oidc.sql
└── docs/complete-setup-guide.md
```

## Safety note

The migration uses `create table` and Liquibase tracking, not `create or replace table`, to avoid accidentally replacing an existing table on a later run.
