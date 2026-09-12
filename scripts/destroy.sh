#! /usr/bin/env bash

if [[ -t 1 ]]; then
    RED=$'\e[31m'
    GREEN=$'\e[32m'
    ENDCOLOR=$'\e[0m'
else
    RED=''
    GREEN=''
    ENDCOLOR=''
fi

VAULT_FILE="ansible/group_vars/all/vault.yaml"
VAULT_PASS="ansible/.vault_password"

export CLOUDFLARE_API_TOKEN=$(ansible-vault view "$VAULT_FILE" --vault-password-file "$VAULT_PASS" \
    | grep '^vault_dns_api_token:' \
    | sed 's/^vault_dns_api_token:[[:space:]]*//')

set -euo pipefail

if command -v mise exec terraform@latest -- terraform >/dev/null 2>&1; then
    mise exec terraform@latest -- terraform -chdir=terraform destroy -auto-approve
fi

printf '%s\n' "${GREEN}AWS infrastructure has been successfully destroyed${ENDCOLOR}"
sleep 1
