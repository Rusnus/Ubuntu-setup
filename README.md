# ubuntu-setup scripts

> Bash scripts for hardening and securing a fresh Ubuntu 22.04 / 24.04 server.
Each module is independent - run them all at once or pick what you need.

# What it does

| Module | What it configures | 
|---|---|
| `users` | Creates an admin user, uploads SSH key, locks root password |
| `ssh` | Disables password auth, root login, weak ciphers; adds login banner |
| `firewall` | ufw default-deny policy, SSH rate limiting |
| `fail2ban` | Bans IPs after repeated SSH failures |
| `updates` | Enables unattended-upgrades for automatic security patches |
| `hardening` | sysctl tweaks, resource limits, auditd rules (CIS Benchmark) |

# Requirements

1. Ubuntu 22.04 LTS or 24.04 LTS
2. Root access (`sudo`)
3. SSH public key ready on your local machine

# Quick start

```bash
# 1. Clone the repo
git clone https://github.com/Rusnus/Ubuntu-setup.git
cd Ubuntu-setup

# 2. (OPTIONAL) Configure via enviponment variables
export ADMIN_USER="deploy"
export SSH_PORT="22"
export SSH_KEY_FILE="$HOME/.ssh/id_ed25519.pub"
export SSH_ALLOW_USERS="deploy"

# 3. Run everything
sudo bash setup.sh --all

# Or run individual modules
sudo bash setup.sh --ssh --firewall
```

>  **WARNING:** Run `--ssh` only after your public key is in `~/.ssh/authorized_keys`on the server, or you will lock yourself out.
