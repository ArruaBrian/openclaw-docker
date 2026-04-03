#!/bin/sh
set -e

# ── Start headless Chromium in background ──────────────────────────
chromium --headless --no-sandbox --disable-gpu \
  --remote-debugging-address=127.0.0.1 \
  --remote-debugging-port=9222 \
  --remote-allow-origins=* &

echo "⏳ Waiting for Chromium to start..."
sleep 3

# ── Apply OpenClaw configuration ───────────────────────────────────
openclaw config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback true
openclaw config set browser.enabled true
openclaw config set browser.cdpUrl http://127.0.0.1:9222

# ── Apply auto-approve config if present ───────────────────────────
if [ -f /home/node/.openclaw/allowlist.json ]; then
  echo "✅ Allowlist found, applying auto-approve rules..."
  # OpenClaw reads this from its config dir automatically
fi

echo "🚀 Starting OpenClaw gateway..."
exec openclaw gateway --allow-unconfigured --bind lan
