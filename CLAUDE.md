# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Foxtail is a Docker-based project that runs a containerized Firefox browser connected to a Tailscale VPN mesh network, accessible via a web browser through noVNC. No VNC client or tunnel setup required. Name is a portmanteau of Tailscale + Chromium (though it actually runs Firefox on the Kasm base image).

## Common Commands

Uses [Taskfile](https://taskfile.dev) — run `task` with no arguments to list all commands.

```bash
task start            # Retrieve auth key from 1Password and start
task stop             # Stop and remove the container
task restart          # Stop and restart
task build            # Rebuild the Docker image from scratch
task logs             # Stream container logs
task status           # Check running container processes
task debug            # Start with verbose logging
task test-auth        # Validate 1Password CLI and auth key
task tailscale-status # Show Tailscale connection inside container
```

Access the browser at `https://localhost:6901` after starting.

## Architecture

The container runs four processes managed by **Supervisor** (inherited from the `kasmweb/firefox:1.15.0` base image):

1. **Tailscale daemon** (userspace networking, no `/dev/net/tun` required)
2. **Xvfb** — virtual X11 display on `:99`
3. **Firefox** — browser on the virtual display
4. **x11vnc + noVNC** — bridges X11 to the web UI

**Startup sequence** (`docker-entrypoint.sh`): starts as root → brings up Tailscale and authenticates using `TS_AUTHKEY` → drops privileges to `kasm-user` via `gosu` → hands off to Kasm's standard entrypoint.

**Secret handling**: `start.sh` calls the 1Password CLI (`op`) at runtime to fetch the Tailscale auth key; the key is passed as an environment variable and never written to disk or committed.

## Key Configuration

All runtime configuration is via environment variables (set in `docker-compose.yml` or overridden in shell):

| Variable | Purpose |
|---|---|
| `TS_AUTHKEY` | Tailscale auth key (injected by `start.sh`) |
| `TAILSCALE_HOSTNAME` | Device name on the tailnet (default: `foxtail`) |
| `TAILSCALE_TAGS` | Optional ACL tags (comma-separated) |
| `OP_VAULT` / `OP_ITEM_NAME` / `OP_FIELD_NAME` | 1Password item locators |
| `VNC_PW` / `VNC_VIEW_ONLY_PW` | Kasm web UI credentials |
| `DEBUG` | Enable verbose logging in shell scripts |

Docker Compose requires `NET_ADMIN` and `NET_RAW` capabilities for Tailscale, uses `100.100.100.100` (Tailscale MagicDNS) as DNS, and allocates 512 MB shared memory for Firefox stability.

## Shell Script Conventions

- Status output uses emoji prefixes: `✅` success, `❌` error, `⚠️` warning, `🔐` credential ops, `🐛` debug
- Error messages include actionable next steps, not just the error
- `DEBUG=true` triggers `set -x` and extra diagnostic output
