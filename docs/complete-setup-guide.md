# Complete beginner setup: Liquibase + Snowflake + GitHub Actions

This guide starts from zero and ends with this deployment flow:

```text
feature/*  →  dev  →  main
                |       |
                |       └── SNOWFLAKE_LEARNING_DB_PROD
                └────────── SNOWFLAKE_LEARNING_DB_DEV
```

The same Liquibase code is promoted through both environments. The database name is selected at deployment time:

| GitHub branch | GitHub Environment | Database |
|---|---|---|
| `dev` | `dev` | `SNOWFLAKE_LEARNING_DB_DEV` |
| `main` | `prod` | `SNOWFLAKE_LEARNING_DB_PROD` |

The SQL uses `${database_name}`. GitHub supplies the value through the selected Environment, and Liquibase replaces the parameter during deployment.

## What you will create

* A GitHub repository.
* Three branch types: `main`, `dev`, and `feature/*`.
* Two GitHub Environments: `dev` and `prod`.
* Two Snowflake service users that authenticate through GitHub Actions OIDC.
* One Liquibase changeset for `trading_use_case.employee_information_bronze`.
* A workflow that validates pull requests and deploys automatically after merges.

OIDC is used so GitHub Actions receives a short-lived token instead of storing a Snowflake password or private key. Snowflake supports GitHub Actions through workload identity federation, and the Snowflake GitHub Action exports the OIDC authentication variables for later steps. See the [Snowflake OIDC documentation](https://docs.snowflake.com/en/developer-guide/snowflake-cli/cicd/github-action).

## Before you start

You need:

* A GitHub account with permission to create repositories and GitHub Environments.
* A Snowflake account.
* A Snowflake administrator who can run the bootstrap SQL once.
* Git installed on your Windows computer.
* The starter ZIP file from this setup.

Use a development Snowflake account or development databases first. Do not test the first run against an important production database.

## Step 1: Create the empty GitHub repository first

Create the repository before configuring Snowflake. The repository name is part of the OIDC trust rule.

1. Open GitHub.
2. Select **New repository**.
3. Enter a name, for example:

```text
liquibase-snowflake-learning
```

4. Choose the correct organization or your personal account.
5. Select **Private** unless the repository is intentionally public.
6. Select **Add a README file**.
7. Select **Create repository**.

Record these two values exactly, including capitalization:

```text
github owner: moduru3534
github repository: liquibase-snowflake-learning
```

For example:

```text
github owner: moduru3534
github repository: liquibase-snowflake-learning
```

## Step 2: Download and prepare the starter files

1. Download `liquibase_snowflake_starter.zip`.
2. Extract it to a temporary folder.
3. The extracted folder is named `liquibase-snowflake-starter`.
4. Do not rename the files inside it.

The important files are:

```text
.github/workflows/deploy.yml
liquibase/changelog-root.xml
liquibase/objects/trading_use_case/tables/employee_information_bronze.xml
liquibase/objects/trading_use_case/tables/sql/employee_information_bronze.sql
snowflake/01_bootstrap_oidc.sql
docs/github-settings.md
```

## Step 3: Clone the GitHub repository to your computer

Open PowerShell and run:

```powershell
cd C:\work
git clone https://github.com/moduru3534/liquibase-snowflake-learning.git
cd liquibase-snowflake-learning
```

If `git` is not recognized, install [Git for Windows](https://git-scm.com/download/win) and reopen PowerShell.

## Step 4: Create the `dev` branch

The GitHub repository currently contains only the initial README on `main`. Create and publish `dev`:

```powershell
git checkout -b dev
git push -u origin dev
```

You now have:

```text
main
 dev
```

Do not push the complete starter to `main` yet. The `main` deployment is the production deployment.

## Step 5: Configure the Snowflake OIDC bootstrap file

Open this file from the extracted starter folder:

```text
snowflake/01_bootstrap_oidc.sql
```

The bootstrap file is already configured for this repository:

```text
repo:moduru3534/liquibase-snowflake-learning:environment:dev
repo:moduru3534/liquibase-snowflake-learning:environment:prod
```

Do not replace these values with `madan-tt-project` or any other repository name.

Do not change `environment:dev` to a branch name. These subjects refer to GitHub Environments, and the workflow will use `environment: dev` and `environment: prod`.

## Step 6: Run the one-time Snowflake bootstrap

Ask a Snowflake administrator to open the edited file and run it in Snowsight.

The script creates or verifies:

* `SNOWFLAKE_LEARNING_DB_DEV`
* `SNOWFLAKE_LEARNING_DB_DEV.TRADING_USE_CASE`
* `SNOWFLAKE_LEARNING_DB_PROD`
* `SNOWFLAKE_LEARNING_DB_PROD.TRADING_USE_CASE`
* A development deployer role and service user.
* A production deployer role and service user.
* Warehouse, database, schema, and table-creation grants.
* GitHub OIDC trust for this exact repository and the `dev` or `prod` Environment.

Run it with the required administrative privileges. Do not run it as the Liquibase deployer role.

After it finishes, verify the objects:

```sql
show databases like 'SNOWFLAKE_LEARNING_DB%';
show schemas in database SNOWFLAKE_LEARNING_DB_DEV;
show users like 'SNOWFLAKE_GITHUB%';
show roles like 'SNOWFLAKE_LEARNING%DEPLOYER_ROLE';
```

## Step 7: Create GitHub Environments

In the GitHub repository:

1. Open **Settings**.
2. Select **Environments**.
3. Select **New environment**.
4. Create an environment named exactly:

```text
dev
```

5. Create another environment named exactly:

```text
prod
```

Environment names are case-sensitive because they are part of the OIDC subject.

### Configure the `dev` Environment

Inside the `dev` Environment, add these **Variables**. Use **Variables**, not Secrets, for this OIDC starter:

| Variable name | Value |
|---|---|
| `SNOWFLAKE_ACCOUNT` | Your Snowflake account identifier, without `https://` |
| `SNOWFLAKE_DATABASE` | `SNOWFLAKE_LEARNING_DB_DEV` |
| `SNOWFLAKE_WAREHOUSE` | `SNOWFLAKE_LEARNING_WH` |
| `SNOWFLAKE_ROLE` | `SNOWFLAKE_LEARNING_DEV_DEPLOYER_ROLE` |
| `SNOWFLAKE_USER` | `SNOWFLAKE_GITHUB_DEV_DEPLOYER` |

For example, the account value may look like:

```text
myorg-myaccount
```

Use the account identifier expected by your Snowflake account. Do not include a full JDBC URL.

### Configure the `prod` Environment

Inside the `prod` Environment, add these **Variables**:

| Variable name | Value |
|---|---|
| `SNOWFLAKE_ACCOUNT` | Your Snowflake account identifier, without `https://` |
| `SNOWFLAKE_DATABASE` | `SNOWFLAKE_LEARNING_DB_PROD` |
| `SNOWFLAKE_WAREHOUSE` | `SNOWFLAKE_LEARNING_WH` |
| `SNOWFLAKE_ROLE` | `SNOWFLAKE_LEARNING_PROD_DEPLOYER_ROLE` |
| `SNOWFLAKE_USER` | `SNOWFLAKE_GITHUB_PROD_DEPLOYER` |

Do not add a Snowflake password, private key, or token for this OIDC workflow.

### Protect the `prod` Environment

Inside the `prod` Environment:

* Add yourself or an administrator as a required reviewer.
* Restrict deployment branches to `main` if your GitHub plan provides that option.

For the first `dev` test, leave required reviewers disabled for `dev` so the deployment can run automatically.

## Step 8: Copy the starter files into the local repository

Copy everything inside the extracted `liquibase-snowflake-starter` folder into your cloned repository folder.

The repository should look like this:

```text
<repository>/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── liquibase/
│   ├── changelog-root.xml
│   ├── liquibase.properties.example
│   └── objects/
├── snowflake/
│   └── 01_bootstrap_oidc.sql
├── scripts/
├── docs/
└── README.md
```

The bootstrap SQL in the local repository should contain your real GitHub owner and repository name, not `<github_org>` and `<github_repo>`.

## Step 9: Commit the starter to `dev`

From the repository folder, run:

```powershell
git status
git add .
git commit -m "add liquibase snowflake deployment"
git push origin dev
```

Because this is a push to `dev`, GitHub Actions will start the development deployment.

The workflow will:

1. Check out the repository.
2. Request a GitHub OIDC token.
3. Authenticate as `SNOWFLAKE_GITHUB_DEV_DEPLOYER`.
4. Read `SNOWFLAKE_DATABASE` from the `dev` Environment.
5. Pass that value to Liquibase as `database_name`.
6. Deploy to `SNOWFLAKE_LEARNING_DB_DEV.TRADING_USE_CASE`.

The actual Liquibase command receives the equivalent of:

```text
--changelog-parameters.database_name=SNOWFLAKE_LEARNING_DB_DEV
```

## Step 10: Check the first GitHub Actions run

In GitHub:

1. Open the **Actions** tab.
2. Select **liquibase snowflake deployment**.
3. Open the run for the `dev` branch.
4. Open the `deploy-dev` job.
5. Confirm that these steps pass:

```text
configure snowflake oidc
test snowflake connection
setup liquibase
deploy liquibase changes
verify table
```

A successful run means the table was deployed to the development database.

## Step 11: Verify the table in Snowflake

Run this query in Snowsight:

```sql
select
    column_name,
    data_type,
    numeric_precision,
    numeric_scale
from snowflake_learning_db_dev.information_schema.columns
where table_schema = 'TRADING_USE_CASE'
  and table_name = 'EMPLOYEE_INFORMATION_BRONZE'
order by ordinal_position;
```

You should see these columns in this order:

```text
day_id
emp_id
emp_email
emp_name
emp_salary
dept_id
dept_name
dept_code
creation_dt
```

Also check the Liquibase history:

```sql
select id, author, exectype
from snowflake_learning_db_dev.trading_use_case.databasechangelog
order by dateexecuted;
```

Liquibase uses its changelog and lock tables to record applied changes and prevent concurrent updates.

## Step 12: Create and use a feature branch

After the first `dev` deployment works, use feature branches for all normal database changes.

Create a feature branch from `dev`:

```powershell
git checkout dev
git pull origin dev
git checkout -b feature/add-employee-change
```

For every new database change:

1. Create a new changeset with a new `id`.
2. Include the new changeset from `liquibase/changelog-root.xml`.
3. Do not edit a changeset that has already been deployed.
4. Commit and push the feature branch.

Push the branch:

```powershell
git add .
git commit -m "add employee information change"
git push -u origin feature/add-employee-change
```

## Step 13: Open a pull request from feature to `dev`

In GitHub:

1. Open a pull request.
2. Set the base branch to `dev`.
3. Set the compare branch to `feature/add-employee-change`.
4. Review the Liquibase files.
5. Wait for the validation check to pass.
6. Merge the pull request.

A pull request runs Liquibase validation. It does not deploy database changes.

After the merge, the push to `dev` automatically deploys the new changeset to:

```text
SNOWFLAKE_LEARNING_DB_DEV.TRADING_USE_CASE
```

## Step 14: Promote `dev` to `main`

When the development deployment is tested:

1. Open a second pull request.
2. Set the base branch to `main`.
3. Set the compare branch to `dev`.
4. Review the changes.
5. Wait for validation to pass.
6. Merge the pull request.

The merge creates a push to `main`. The workflow then selects the `prod` Environment and deploys to:

```text
SNOWFLAKE_LEARNING_DB_PROD.TRADING_USE_CASE
```

If required reviewers are enabled, approve the `prod` Environment deployment from the Actions run.

## Step 15: Configure branch protection

After the first successful test, protect both `dev` and `main` in **Settings → Branches**.

Recommended rules:

* Require a pull request before merging.
* Require at least one approval.
* Require the validation status check to pass.
* Do not allow direct pushes.
* Require the `prod` Environment approval for production.

The intended process is:

```text
feature/my-change
        ↓ pull request
       dev  → automatic dev deployment
        ↓ pull request
      main  → automatic prod deployment
```

## Step 16: Understand the parameterization

The table SQL contains:

```sql
create table ${database_name}.trading_use_case.employee_information_bronze (
    day_id number(38,0),
    emp_id number(38,0),
    emp_email varchar(16777216),
    emp_name varchar(16777216),
    emp_salary number(38,0),
    dept_id number(38,0),
    dept_name varchar(16777216),
    dept_code varchar(16777216),
    creation_dt timestamp_ltz(9) default current_timestamp()
);
```

The workflow gets the database from the selected GitHub Environment:

```text
push to dev  → vars.SNOWFLAKE_DATABASE = SNOWFLAKE_LEARNING_DB_DEV
push to main → vars.SNOWFLAKE_DATABASE = SNOWFLAKE_LEARNING_DB_PROD
```

Liquibase then receives that value as the `database_name` changelog parameter. Therefore, the SQL file is shared between environments and does not contain a hardcoded environment name.

## Important note about `create or replace`

Your original Snowflake statement used `create or replace table`. The starter intentionally uses `create table` in a Liquibase changeset.

That is safer because Liquibase tracks the changeset and runs it once. `create or replace` can remove and recreate an existing table, which can destroy data and reset table properties. Use a new changeset for future changes, such as `addColumn`, rather than replacing the whole table.

## Optional local validation

GitHub Actions is the first working deployment path. Local validation is optional.

For local Snowflake login through a browser:

1. Copy `liquibase/liquibase.properties.example` to `liquibase/liquibase.properties`.
2. Replace the account, database, warehouse, and role values.
3. Run:

```powershell
liquibase --defaults-file=liquibase/liquibase.properties validate
liquibase --defaults-file=liquibase/liquibase.properties update-sql
```

Do not commit `liquibase.properties`. It is already excluded by `.gitignore`.

## Troubleshooting checklist

### OIDC authentication fails

Check all of these values:

* The Snowflake `subject` exactly matches `repo:<owner>/<repo>:environment:dev` or `environment:prod`.
* The GitHub Environment is named exactly `dev` or `prod`.
* The workflow job contains `environment: dev` or `environment: prod`.
* The workflow permissions include `id-token: write`.
* The GitHub repository owner and name use the correct capitalization.

### The wrong database is selected

Check the Environment variables, not repository variables:

```text
dev  → SNOWFLAKE_LEARNING_DB_DEV
prod → SNOWFLAKE_LEARNING_DB_PROD
```

Also confirm that the deploy job has the correct `environment:` value.

### Permission denied in Snowflake

Confirm that the selected role has:

* Usage on the warehouse.
* Usage on the database.
* Usage on `trading_use_case`.
* Create table on `trading_use_case`.

### Liquibase says the changeset already ran

That is normally correct. Liquibase is preventing the same changeset from running again. Create a new changeset with a new `id` for the next database change.

### Liquibase validation fails

Check:

* XML syntax.
* The path in `changelog-root.xml`.
* That every included file exists.
* That the changeset `id` and `author` are present.

## Final success checklist

* [ ] GitHub repository created.
* [ ] `main` branch exists.
* [ ] `dev` branch exists.
* [ ] A `feature/*` branch was created.
* [ ] Snowflake bootstrap completed.
* [ ] GitHub `dev` Environment configured.
* [ ] GitHub `prod` Environment configured.
* [ ] `SNOWFLAKE_DATABASE` is different in each Environment.
* [ ] Pull request validation passed.
* [ ] `dev` deployment created the table in `SNOWFLAKE_LEARNING_DB_DEV`.
* [ ] `main` deployment created the table in `SNOWFLAKE_LEARNING_DB_PROD`.
* [ ] Branch protection enabled.

## Reference files

* [Snowflake GitHub Actions OIDC](https://docs.snowflake.com/en/developer-guide/snowflake-cli/cicd/github-action)
* [Snowflake authentication overview](https://docs.snowflake.com/en/user-guide/security-authentication-overview)
* [Liquibase setup action](https://github.com/liquibase/setup-liquibase)
