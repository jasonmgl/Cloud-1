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

set -euo pipefail

if command -v aws >/dev/null 2>&1; then
    rm -f "$HOME/.local/bin/aws"
    rm -f "$HOME/.local/bin/aws_completer"
    rm -rf "$HOME/.local/aws-cli"
fi

# moved to scripts/destroy.sh
# if command -v mise exec terraform@latest -- terraform >/dev/null 2>&1; then
#     mise exec terraform@latest -- terraform -chdir=terraform destroy -auto-approve
# fi

if command -v ansible >/dev/null 2>&1; then
    (cd "$HOME" && pipx uninstall ansible) || true
fi

# if command -v pipx >/dev/null 2>&1; then
#     sudo apt remove pipx -y
# fi

if command -v mise -v >/dev/null 2>&1; then
    mise uninstall terraform -y --all
    mise implode -y
fi

printf '%s\n' "${GREEN}All binary files have been successfully uninstalled${ENDCOLOR}"
sleep 1
