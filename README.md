# ubuntu-setup scripts

---

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
