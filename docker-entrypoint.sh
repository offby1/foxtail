#!/bin/bash
set -e

echo "🦎 Foxtail starting..."

# Start Tailscale as root in background (detached)
if [ -n "$TS_AUTHKEY" ]; then
    echo "Starting Tailscale daemon..."

    # Start tailscaled in background
    nohup tailscaled --state=/var/lib/tailscale/tailscaled.state \
                     --socket=/var/run/tailscale/tailscaled.sock \
                     --tun=userspace-networking > /var/log/tailscaled.log 2>&1 &

    # Wait for daemon to be ready
    sleep 3

    # Connect to Tailscale
    HOSTNAME="${TAILSCALE_HOSTNAME:-foxtail}"
    TAGS="${TAILSCALE_TAGS:-}"

    TAILSCALE_CMD="tailscale up --authkey=\"$TS_AUTHKEY\" --hostname=\"$HOSTNAME\" --accept-routes"
    if [ -n "$TAGS" ]; then
        TAILSCALE_CMD="$TAILSCALE_CMD --advertise-tags=\"$TAGS\""
    fi

    echo "Connecting to Tailscale as: $HOSTNAME"
    eval "$TAILSCALE_CMD"

    echo "✅ Tailscale connected!"
    tailscale status

    # Show Tailscale IP
    TS_IP=$(tailscale ip -4)
    echo "Tailscale IP: $TS_IP"
else
    echo "⚠️  No TS_AUTHKEY provided, skipping Tailscale setup"
fi

# Now drop to kasm-user and start Kasm services
echo "Starting Kasm browser environment as kasm-user..."

# Switch to kasm-user and run Kasm's original entrypoint
exec gosu kasm-user /dockerstartup/kasm_default_profile.sh /dockerstartup/vnc_startup.sh /dockerstartup/kasm_startup.sh "$@"
