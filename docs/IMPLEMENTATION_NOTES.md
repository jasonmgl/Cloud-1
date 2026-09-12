# Implementation notes

How each capability of this project is implemented, with pointers into the code.

## Deployment is a single automated command

`make` takes a bare instance to a fully running site with no manual steps: Ansible installs Docker, configures the firewall, copies the application, obtains a certificate, and starts the containers. See [PLAYBOOK.md](./PLAYBOOK.md) for the task-by-task breakdown.

## The site comes back up on its own after a reboot

Docker itself is enabled as a systemd service (`roles/docker/tasks/docker_engine.yaml`), so it starts on boot. Every service in `src/docker-compose.yml` uses `restart: unless-stopped`, so Docker recreates them automatically once it's back up, no manual restart needed.

## Data survives a reboot

`mariadb`, `wordpress`, and `nginx` each use a plain Docker-managed named volume. Named volumes live independently of container lifecycle and are unaffected by a host reboot.

## Deployable to multiple servers at once

Ansible runs a play against every host in the target inventory group in parallel by default. Adding another server just means adding another line to `inventory.ini`; nothing in the playbook assumes a single target.

## Runs against a minimal fresh instance

The playbook doesn't assume anything beyond SSH access and Python.   
Docker, ufw, and certbot are all installed by the playbook itself rather than expected to pre-exist. `ansible_python_interpreter` is left to Ansible's interpreter auto-discovery instead of being pinned to a specific Python version that might not exist on a given image.

## One process per container

`mariadb`, `wordpress`, and `nginx` each run a single long-lived daemon (`mysqld`, `php-fpm`, `nginx`). Their entrypoint scripts (`db_init.sh`, `wp_init.sh`, `docker-entrypoint.sh`) do one-time setup and then `exec` into that daemon, so the final running process is always just the one service.

## Locked-down public access

`roles/security/tasks/main.yaml` configures `ufw` to allow only SSH, HTTP, and HTTPS, denying everything else by default. MariaDB has no port published to the host at all (`expose`, not `ports` in the compose file), so it's only reachable from the other containers over the internal Docker network, never from outside.

## WordPress and the database work together

`db_init.sh` waits for `mysqld` to accept connections before creating the database and user, with the privileges and character set that WordPress needs. `wp_init.sh`'s `wp core install` succeeding against that database is the functional proof the two interoperate. This only holds for a fresh deploy: changing `sql_password` afterward doesn't propagate to an existing database or `wp-config.php` without wiping the volumes first.

## Portable to a fresh instance

Nothing is hardcoded to the machine used during development: the Docker repo architecture is read from the target (`dpkg --print-architecture`), the distribution codename is read from Ansible facts, the deployment path (`/opt/inception`) doesn't depend on which user connects, and the Python interpreter is auto-discovered rather than pinned.

## Idempotent

Re-running `make` produces the same result: `apt`/`template`/`file` tasks are naturally idempotent, `ufw` tasks check current state before changing it, certbot skips reissuing a certificate that isn't due for renewal, and `docker compose up` only recreates what actually changed.

## No hardcoded secrets in the code source

All passwords and the Cloudflare API token live in `ansible/group_vars/all/vault.yaml`, encrypted with Ansible Vault. `.env` on the target is rendered from those variables at deploy time and is never committed. `.gitignore` also excludes `.vault_pass`.
