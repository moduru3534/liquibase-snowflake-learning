-- liquibase snowflake oidc bootstrap
--
-- Repository: moduru3534/liquibase-snowflake-learning
-- GitHub Environments: dev and prod
--
-- This script reuses the existing roles and service users:
--   trading_dev_cicd_role       -> madan_trading_github_dev
--   trading_prod_cicd_role      -> madan_trading_github_prod
--
-- Run once in Snowsight with a role that can create/alter service users and grant privileges.
-- The database and schema objects are expected to already exist.
--
-- Important: GitHub Environment names must be exactly dev and prod. If your GitHub
-- Environment names are DEV and PROD, change both subjects below and the workflow.

use role accountadmin;

create role if not exists trading_dev_cicd_role;
create role if not exists trading_prod_cicd_role;

create user if not exists madan_trading_github_dev
    type = service
    comment = 'GitHub Actions Liquibase deployer for trading development';

create user if not exists madan_trading_github_prod
    type = service
    comment = 'GitHub Actions Liquibase deployer for trading production';

-- Configure the existing DEV service user.
alter user madan_trading_github_dev set default_role = trading_dev_cicd_role;
alter user madan_trading_github_dev set default_warehouse = snowflake_learning_wh;
alter user madan_trading_github_dev set workload_identity = (
    type = oidc
    issuer = 'https://token.actions.githubusercontent.com'
    subject = 'repo:moduru3534/liquibase-snowflake-learning:environment:dev'
);

-- Configure the existing PROD service user.
alter user madan_trading_github_prod set default_role = trading_prod_cicd_role;
alter user madan_trading_github_prod set default_warehouse = snowflake_learning_wh;
alter user madan_trading_github_prod set workload_identity = (
    type = oidc
    issuer = 'https://token.actions.githubusercontent.com'
    subject = 'repo:moduru3534/liquibase-snowflake-learning:environment:prod'
);

-- Attach the existing deployment roles to the existing service users.
grant role trading_dev_cicd_role to user madan_trading_github_dev;
grant role trading_prod_cicd_role to user madan_trading_github_prod;

-- Required privileges for Liquibase and the Snowflake JDBC connection.
-- Existing broader grants are not revoked by this script.
grant usage on warehouse snowflake_learning_wh
    to role trading_dev_cicd_role;
grant usage on database snowflake_learning_db_dev
    to role trading_dev_cicd_role;
grant usage on schema snowflake_learning_db_dev.trading_use_case
    to role trading_dev_cicd_role;
grant create table on schema snowflake_learning_db_dev.trading_use_case
    to role trading_dev_cicd_role;

grant usage on warehouse snowflake_learning_wh
    to role trading_prod_cicd_role;
grant usage on database snowflake_learning_db_prod
    to role trading_prod_cicd_role;
grant usage on schema snowflake_learning_db_prod.trading_use_case
    to role trading_prod_cicd_role;
grant create table on schema snowflake_learning_db_prod.trading_use_case
    to role trading_prod_cicd_role;

-- Verify the configured workload identities after this script completes.
show user workload identity authentication methods for user madan_trading_github_dev;
show user workload identity authentication methods for user madan_trading_github_prod;
