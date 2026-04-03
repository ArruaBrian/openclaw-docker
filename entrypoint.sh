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

# ── Exec approvals ─────────────────────────────────────────────────
# exec-approvals.json is bind-mounted from ./config/ into ~/.openclaw/
# OpenClaw reads it automatically on gateway start — no CLI needed
if [ -f /home/node/.openclaw/exec-approvals.json ]; then
  echo "✅ exec-approvals.json loaded (allowlist mode, ask on-miss)"
else
  echo "⚠️  No exec-approvals.json found — using OpenClaw defaults"
fi

echo "🚀 Starting OpenClaw gateway..."
exec openclaw gateway --allow-unconfigured --bind lan
