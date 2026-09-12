# Starting a fresh vault

If no vault password was shared with you (e.g. starting a new deployment rather than joining an existing team's), create your own.

## 1. Generate a vault password

```bash
openssl rand -base64 32 > ansible/.vault_password
```

## 2. Create the vault file

Create `ansible/group_vars/all/vault.yaml` with these keys:

```yaml
vault_sql_password: <change-me>
vault_sql_root_password: <change-me>
vault_wp_admin_password: <change-me>
vault_wp_user_password: <change-me>
vault_dns_api_token: <change-me>
```

`ansible/group_vars/all/vars.yaml` references these under their plain names (e.g. `sql_password: "{{ vault_sql_password }}"`), so the keys above must match exactly.

## 3. Encrypt it

```bash
ansible-vault encrypt ansible/group_vars/all/vault.yaml --vault-password-file ansible/.vault_password
```

`ansible/ansible.cfg` already points `vault_password_file` at `ansible/.vault_password`, so `make up`/`make provision` will decrypt it automatically from here on.
