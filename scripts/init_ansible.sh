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

ANSIBLE_CONFIG=ansible/ansible.cfg ansible-inventory -i ansible/inventory.ini --list --yaml > ansible/inventory.yaml

ANSIBLE_ROLES_PATH=ansible/roles ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbook.yaml --syntax-check
ANSIBLE_ROLES_PATH=ansible/roles ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbook.yaml
