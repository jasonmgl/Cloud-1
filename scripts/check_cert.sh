#! /usr/bin/env bash

set -euo pipefail

ANSIBLE_INVENTORY_FILE=ansible/inventory.ini
DOMAIN=$(grep -m1 -oE 'domain_name=[^ ]+' "$ANSIBLE_INVENTORY_FILE" | cut -d= -f2)

if [ -z "$DOMAIN" ]; then
    echo "No domain_name set in inventory.ini"
    exit 1
fi

echo "Checking certificate for $DOMAIN..."
echo | openssl s_client -connect "$DOMAIN":443 -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -issuer -subject -dates
echo | openssl s_client -connect "$DOMAIN":443 -servername "$DOMAIN" 2>&1 | grep -E "Verify return code"
