#!/bin/bash
set -e

# Configuration
OP_ITEM_NAME="${OP_ITEM_NAME:-Foxtail}"
OP_VAULT="${OP_VAULT:-Private}"
OP_FIELD_NAME="${OP_FIELD_NAME:-auth_key}"
TAILSCALE_HOSTNAME="${TAILSCALE_HOSTNAME:-foxtail}"
TAILSCALE_TAGS="${TAILSCALE_TAGS:-}"
DEBUG="${DEBUG:-false}"

# Enable debug mode if requested
if [ "$DEBUG" = "true" ]; then
    set -x
    echo "🐛 Debug mode enabled"
fi

# Warn if running with default credentials
if [ ! -f ".env" ] || ! grep -qE '^VNC_PW=.+' .env 2>/dev/null; then
    echo "⚠️  No VNC_PW set in .env — using default password 'foxtail'"
    echo "   To set a custom password: cp .env.example .env && \$EDITOR .env"
    echo ""
fi

echo "🔐 Retrieving Tailscale auth key from 1Password..."

if [ "$DEBUG" = "true" ]; then
    echo "  Vault: ${OP_VAULT}"
    echo "  Item: ${OP_ITEM_NAME}"
    echo "  Field: ${OP_FIELD_NAME}"
fi

# Check if op CLI is installed
if ! command -v op &> /dev/null; then
    echo "❌ Error: 1Password CLI (op) is not installed"
    echo "Install it from: https://developer.1password.com/docs/cli/get-started/"
    exit 1
fi

# Retrieve the auth key from 1Password
# Using 'op read' to get the password field from the item
TS_AUTHKEY=$(op read "op://${OP_VAULT}/${OP_ITEM_NAME}/${OP_FIELD_NAME}" 2>/dev/null)

# Strip any whitespace/newlines that may have been saved with the key
TS_AUTHKEY=$(echo "$TS_AUTHKEY" | tr -d '[:space:]')

if [ -z "$TS_AUTHKEY" ]; then
    echo "❌ Error: Could not retrieve Tailscale auth key from 1Password"
    echo ""
    echo "Expected vault: ${OP_VAULT}"
    echo "Expected item: ${OP_ITEM_NAME}"
    echo "Expected field: ${OP_FIELD_NAME}"
    echo ""
    echo "Make sure:"
    echo "  1. You're signed in to 1Password CLI: op signin"
    echo "  2. The item exists in the '${OP_VAULT}' vault with name '${OP_ITEM_NAME}'"
    echo "  3. The Tailscale auth key is stored in the password field"
    echo ""
    echo "You can customize these with environment variables:"
    echo "  OP_VAULT='MyVault' OP_ITEM_NAME='MyItem' ./start.sh"
    exit 1
fi

if [ "$DEBUG" = "true" ]; then
    echo "✅ Auth key retrieved successfully (length after cleanup: ${#TS_AUTHKEY} chars)"
else
    echo "✅ Auth key retrieved successfully"
fi
echo "🚀 Starting Foxtail container..."

# Export variables for docker-compose
export TS_AUTHKEY
export TAILSCALE_HOSTNAME
export TAILSCALE_TAGS
export DEBUG

# Start the container
if [ "$DEBUG" = "true" ]; then
    echo ""
    echo "🐛 Starting container with debug logging..."
    docker-compose up -d
    echo ""
    echo "Waiting for services to start..."
    sleep 5
    echo ""
    echo "📋 Container status:"
    docker ps | grep foxtail || echo "  Container not found!"
    echo ""
    echo "📋 Supervisor process status:"
    docker exec foxtail supervisorctl status 2>&1 || echo "  Could not check supervisor status"
    echo ""
    echo "📋 Recent logs:"
    docker logs foxtail --tail 30
else
    docker-compose up -d
fi

echo ""
echo "✅ Container started!"
echo ""
echo "📡 Tailscale device name: ${TAILSCALE_HOSTNAME}"
echo "🌐 Access browser at: https://localhost:6901"
echo "   Username: kasm_user"
echo "   Password: ${VNC_PW:-foxtail}"
echo ""
if [ "$DEBUG" = "true" ]; then
    echo "🐛 Debug mode enabled - watching logs (Ctrl+C to exit)..."
    echo ""
    docker logs -f foxtail
else
    echo "To view logs: docker-compose logs -f"
    echo "To enable debug mode: DEBUG=true ./start.sh"
    echo "To stop: docker-compose down"
fi
