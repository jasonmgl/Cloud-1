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

# sudo apt update
# sudo apt install -y pipx curl unzip
missing=()
for bin in pipx curl unzip; do
    command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done
if [ "${#missing[@]}" -gt 0 ]; then
    printf '%s\n' "${RED}Missing required tools: ${missing[*]}. Ask an admin to install them (no sudo available here).${ENDCOLOR}"
    exit 1
fi
pipx ensurepath

if ! command -v aws >/dev/null 2>&1;then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install --install-dir "$HOME/.local/aws-cli" --bin-dir "$HOME/.local/bin"
    rm -rf aws/ aws*.zip
fi

if ! command -v ansible >/dev/null 2>&1; then
    pipx install --include-deps ansible
fi
ansible --version

ansible-galaxy collection install -r ansible/requirements.yaml

if ! command -v mise >/dev/null 2>&1; then
    curl https://mise.run | sh
fi
mise version -y

if ! command -v terraform >/dev/null 2>&1; then
    mise use --global terraform@latest
fi
mise exec terraform@latest -- terraform -chdir=terraform version

printf '%s\n' "${GREEN}All binary files have been successfully installed${ENDCOLOR}"
sleep 1