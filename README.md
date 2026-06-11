<div align="center">
  <img src="logo.svg" alt="Foxtail Logo" width="200"/>

  # Foxtail

  > (Fire)**fox** + **Tail**(scale) = Foxtail

  A Firefox browser that lives on your Tailscale network — accessible from any device on your tailnet, directly in a browser tab.
</div>

---

Foxtail runs Firefox inside Docker and joins it to your tailnet as a named node. From any device on your tailnet you open a tab, and you're in. No port forwarding. No public exposure. No VPN client on the remote device.

**Some things this is good for:**

- Browse the web through your home or office network from anywhere
- Reach internal services on your tailnet (dashboards, dev servers, NAS) without exposing them
- Give a teammate a shared browser pointed at your internal resources
- Test how a site behaves from a specific network's perspective

## How it uses Tailscale

**Userspace networking** — Tailscale runs entirely in userspace inside the container. No `/dev/net/tun`, no host networking, no special kernel modules. It works anywhere Docker runs.

**MagicDNS** — the browser resolves `.ts.net` hostnames out of the box. Internal services are reachable by name, not IP.

**Auth keys + 1Password** — the auth key is fetched at runtime from 1Password CLI and injected as an environment variable. It never touches disk or a config file.

**Ephemeral nodes** — use an ephemeral auth key and the device disappears from your tailnet automatically when the container stops. No stale devices to clean up.

## Prerequisites

1. **Docker Desktop** installed and running
2. **Task** installed:
   ```bash
   brew install go-task
   ```
3. **1Password CLI** installed and configured:
   ```bash
   brew install --cask 1password-cli
   op signin
   ```
4. **Tailscale account** with an auth key stored in 1Password

## Setup

### 1. Store a Tailscale auth key in 1Password

Generate a key at https://login.tailscale.com/admin/settings/keys, then save it in 1Password:

- **Vault**: `Private` (or set `OP_VAULT`)
- **Item name**: `Foxtail` (or set `OP_ITEM_NAME`)
- **Field name**: `auth_key`

Key options to consider:
- **Reusable** — lets you recreate the container without generating a new key each time
- **Ephemeral** — the tailnet device is removed automatically when the container stops

### 2. Configure credentials

```bash
cp .env.example .env
# Edit .env and set VNC_PW and VNC_VIEW_ONLY_PW
```

### 3. Start

```bash
task start
```

### 4. Open the browser

```
https://localhost:6901
```

- **Username**: `kasm_user`
- **Password**: *(your `VNC_PW` from `.env`, default: `foxtail`)*

## Usage

Run `task` with no arguments to see all available commands.

| Command | Description |
|---|---|
| `task start` | Fetch auth key from 1Password and start |
| `task stop` | Stop and remove the container |
| `task restart` | Stop and restart |
| `task build` | Rebuild the Docker image from scratch |
| `task logs` | Stream container logs |
| `task status` | Check running container processes |
| `task debug` | Start with verbose logging |
| `task test-auth` | Validate 1Password CLI and auth key |
| `task tailscale-status` | Show Tailscale connection inside the container |

## Configuration

### Custom hostname

```bash
TAILSCALE_HOSTNAME=my-browser task start
```

### Custom 1Password item

```bash
OP_VAULT="Personal" OP_ITEM_NAME="Tailscale Keys" task start
```

### Tailscale ACL tags

```bash
TAILSCALE_TAGS="tag:browser,tag:docker" task start
```

## Architecture

```
┌─────────────────────────────────────┐
│     Docker Container                │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ Tailscale (userspace mode)   │  │
│  │ - No /dev/net/tun required   │  │
│  │ - Connected to your tailnet  │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ Xvfb (Virtual Display)       │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ Firefox                      │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ x11vnc → noVNC               │  │
│  │ (Web-based VNC interface)    │  │
│  └──────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
              │
              │ Port 6901
              ▼
     Your Web Browser
    (https://localhost:6901)
```

Built on [`kasmweb/firefox`](https://hub.docker.com/r/kasmweb/firefox). Supervisor manages all four processes inside the container. The entrypoint starts Tailscale as root, connects to your tailnet, then drops to an unprivileged user before handing off to Kasm.

## Troubleshooting

### Auth key not found
```bash
task test-auth

# Or check manually
op whoami
op read "op://Private/Foxtail/auth_key"
```

### Container won't start
```bash
task logs
task tailscale-status
```

### Can't access noVNC
- Verify the container is running: `docker-compose ps`
- Check port 6901 isn't in use: `lsof -i :6901`
- Check noVNC logs: `task logs` and search for `novnc`

## Security notes

- The Tailscale auth key is fetched at runtime from 1Password — never stored in a file or image layer
- VNC credentials are set via `.env` which is gitignored
- The container requires `NET_ADMIN` and `NET_RAW` capabilities for Tailscale userspace networking
- Tailscale state persists in a Docker volume — delete it with `docker volume rm foxtail_tailscale-state` to force re-authentication

## License

MIT
