# GitHub settings

## 1. Create the environments

Create these GitHub Environments under **Settings → Environments**:

* `dev`
* `prod`

The names are case-sensitive because they are part of the Snowflake OIDC subject.

Recommended protection:

* `dev`: required reviewers disabled for the first test.
* `prod`: required reviewers enabled before using the production deployment.

## 2. Add environment variables

Add the following variables separately inside each environment. Do not add them only as repository variables, because the database and deployer identity must change with the branch.

### `dev` environment

| Name | Value |
|---|---|
| `SNOWFLAKE_ACCOUNT` | Your Snowflake account identifier, such as `org-account` |
| `SNOWFLAKE_DATABASE` | `SNOWFLAKE_LEARNING_DB_DEV` |
| `SNOWFLAKE_WAREHOUSE` | `SNOWFLAKE_LEARNING_WH` |
| `SNOWFLAKE_ROLE` | `SNOWFLAKE_LEARNING_DEV_DEPLOYER_ROLE` |
| `SNOWFLAKE_USER` | `SNOWFLAKE_GITHUB_DEV_DEPLOYER` |

### `prod` environment

| Name | Value |
|---|---|
| `SNOWFLAKE_ACCOUNT` | Your Snowflake account identifier, such as `org-account` |
| `SNOWFLAKE_DATABASE` | `SNOWFLAKE_LEARNING_DB_PROD` |
| `SNOWFLAKE_WAREHOUSE` | `SNOWFLAKE_LEARNING_WH` |
| `SNOWFLAKE_ROLE` | `SNOWFLAKE_LEARNING_PROD_DEPLOYER_ROLE` |
| `SNOWFLAKE_USER` | `SNOWFLAKE_GITHUB_PROD_DEPLOYER` |

Do not create a password, private-key, or token secret for this OIDC workflow.

## 3. OIDC subjects

The Snowflake bootstrap script creates two users. Their subjects must match the GitHub repository and environment exactly:

```text
repo:moduru3534/liquibase-snowflake-learning:environment:dev
repo:moduru3534/liquibase-snowflake-learning:environment:prod
```

The workflow uses `environment: dev` for the `dev` branch and `environment: prod` for the `main` branch.

## 4. Branch protection

Recommended rules:

* Protect `dev` and `main`.
* Require pull requests before merging.
* Require at least one approval.
* Require the pull-request validation check to pass.
* Do not allow direct pushes to `dev` or `main`.
* Require the `prod` Environment approval for production deployments.

## 5. Branch flow

```text
feature/<ticket-or-topic> → dev → main
                                  |
                                  └── Snowflake prod deployment
```

A merge into `dev` deploys to `SNOWFLAKE_LEARNING_DB_DEV`. A merge into `main` deploys to `SNOWFLAKE_LEARNING_DB_PROD`.
