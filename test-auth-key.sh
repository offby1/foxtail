#!/bin/bash

echo "🔍 Testing Tailscale Auth Key from 1Password"
echo ""

# Configuration
OP_ITEM_NAME="${OP_ITEM_NAME:-Foxtail}"
OP_VAULT="${OP_VAULT:-Private}"
OP_FIELD_NAME="${OP_FIELD_NAME:-auth_key}"

echo "📍 Reading from: op://${OP_VAULT}/${OP_ITEM_NAME}/${OP_FIELD_NAME}"
echo ""

# Retrieve the key
TS_AUTHKEY=$(op read "op://${OP_VAULT}/${OP_ITEM_NAME}/${OP_FIELD_NAME}" 2>/dev/null)

if [ -z "$TS_AUTHKEY" ]; then
    echo "❌ Could not retrieve key from 1Password"
    exit 1
fi

echo "✅ Key retrieved successfully"
echo ""
echo "Key details:"
echo "  Length: ${#TS_AUTHKEY} characters"
echo "  Prefix: ${TS_AUTHKEY:0:15}..."
echo "  Suffix: ...${TS_AUTHKEY: -10}"
echo ""

# Check format
if [[ "$TS_AUTHKEY" == tskey-auth-* ]]; then
    echo "✅ Key format looks correct (starts with tskey-auth-)"
else
    echo "⚠️  Warning: Key doesn't start with 'tskey-auth-' (got: ${TS_AUTHKEY:0:10}...)"
    echo "   This might not be a valid Tailscale auth key"
fi

echo ""
echo "Key characteristics:"
HAS_WHITESPACE=$(echo "$TS_AUTHKEY" | grep -q '[[:space:]]' && echo "YES ⚠️" || echo "NO ✅")
HAS_NEWLINES=$(echo "$TS_AUTHKEY" | grep -q $'\n' && echo "YES ⚠️" || echo "NO ✅")
IS_CLEAN=$(echo "$TS_AUTHKEY" | grep -qE '^[a-zA-Z0-9-]+$' && echo "YES ✅" || echo "NO ⚠️")

echo "  Has whitespace: $HAS_WHITESPACE"
echo "  Has newlines: $HAS_NEWLINES"
echo "  Alphanumeric+dash only: $IS_CLEAN"

# Show cleaned version
TS_AUTHKEY_CLEAN=$(echo "$TS_AUTHKEY" | tr -d '[:space:]')
if [ "$TS_AUTHKEY" != "$TS_AUTHKEY_CLEAN" ]; then
    echo ""
    echo "⚠️  Whitespace detected - the start.sh script will automatically clean this"
    echo "  Cleaned length: ${#TS_AUTHKEY_CLEAN} characters"
fi

echo ""
echo "Next steps:"
if [ "$HAS_NEWLINES" = "YES ⚠️" ] || [ "$HAS_WHITESPACE" = "YES ⚠️" ]; then
    echo "  ✅ No action needed - start.sh will automatically strip whitespace"
    echo "  Just run: ./start.sh"
else
    echo "  1. Verify this is the correct auth key"
    echo "  2. Check if the key has expired at https://login.tailscale.com/admin/settings/keys"
    echo "  3. If needed, generate a new key and update 1Password"
    echo "  4. Make sure 'Reusable' is checked when generating the key"
fi
