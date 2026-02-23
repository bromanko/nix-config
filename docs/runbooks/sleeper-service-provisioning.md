# Runbook: Provision sleeper-service (Hetzner host for Michael)

This runbook captures the repeatable flow to provision a new Hetzner machine and apply the `sleeper-service` NixOS config.

## Scope

- Create server in Hetzner Cloud
- Bootstrap NixOS on the machine
- Verify disk UUIDs and host settings
- Apply `nix-config` host config

## Prerequisites

- `hcloud` CLI authenticated (`HCLOUD_TOKEN` or configured context)
- SSH key named `Hetzner` present in Hetzner Cloud
- Local checkout of this repo (`~/Code/nix-config`)

## 1) Create the server

Use script defaults (Culture-themed name, US West, CPX11):

```sh
scripts/hetzner/create-server.sh
```

Default values:

- `SERVER_NAME=sleeper-service`
- `SERVER_TYPE=cpx11`
- `LOCATION=hil` (US West / Hillsboro)
- `SSH_KEY_NAME=Hetzner`

Override example:

```sh
SERVER_NAME=just-reading-instructions SERVER_TYPE=cpx22 scripts/hetzner/create-server.sh
```

## 2) Bootstrap NixOS

Run bootstrap against the server IPv4:

```sh
scripts/hetzner/bootstrap-nixos.sh <server-ip>
```

Notes:

- Script uses `nixos-infect` with `NO_SWAP=1` and `bootFs=/boot` for Hetzner CPX bootstrap compatibility.
- If no NixOS image was available, server is typically created as Debian first and then converted.

## 3) Confirm host config values

Check `lsblk -f` output and ensure UUIDs match host config:

- `hosts/nixos/x86_64-linux/sleeper-service/default.nix`
  - `fileSystems."/".device`
  - `fileSystems."/efi".device`

Also verify/adjust:

- `services.caddy.email`
- `services.caddy.virtualHosts."cal.bromanko.com"`

## 4) Apply NixOS config

```sh
# First successful apply after bootstrap should include bootloader install:
INSTALL_BOOTLOADER=1 scripts/hetzner/apply-host-config.sh <server-ip> sleeper-service

# Subsequent applies:
scripts/hetzner/apply-host-config.sh <server-ip> sleeper-service
```

## 5) Configure offsite object-storage backups

Create backup upload environment file on the host:

```sh
ssh root@<server-ip> 'cat > /var/lib/michael/backup-upload.env <<EOF
AWS_ACCESS_KEY_ID=<key>
AWS_SECRET_ACCESS_KEY=<secret>
AWS_REGION=us-east-1
MICHAEL_BACKUP_S3_BUCKET=<bucket-name>
MICHAEL_BACKUP_S3_ENDPOINT=https://<s3-compatible-endpoint>
MICHAEL_BACKUP_S3_PREFIX=michael/sqlite
EOF
chown michael:michael /var/lib/michael/backup-upload.env
chmod 0600 /var/lib/michael/backup-upload.env'
```

If you're using AWS S3 directly, omit `MICHAEL_BACKUP_S3_ENDPOINT`.

## 6) Quick validation

```sh
ssh root@<server-ip> 'systemctl status caddy --no-pager'
ssh root@<server-ip> 'systemctl status michael --no-pager'
ssh root@<server-ip> 'systemctl status michael-backup.timer --no-pager'
ssh root@<server-ip> 'systemctl start michael-backup.service'
ssh root@<server-ip> 'journalctl -u michael-backup -n 50 --no-pager'
```

`michael` may fail until app artifact and env file are deployed (expected).

## 7) Deploy Michael app artifact (from app repo)

From `~/Code/michael`:

```sh
nix build .#michael-backend
rsync -avz --delete ./result/ root@<server-ip>:/var/lib/michael/releases/current/
ssh root@<server-ip> 'chown -R michael:michael /var/lib/michael/releases && ln -sfn /var/lib/michael/releases/current /var/lib/michael/current && systemctl restart michael'
```

Create `/var/lib/michael/env` with required runtime variables, then restart `michael`.
