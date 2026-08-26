#!/usr/bin/env bash
set -euo pipefail

liquibase \
  --defaults-file=liquibase/liquibase.properties \
  update
