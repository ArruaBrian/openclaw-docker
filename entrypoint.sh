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

# ── Apply exec approvals (allowlist mode) ──────────────────────────
# security=allowlist: only allowlisted binaries run without asking
# ask=on-miss: anything NOT in allowlist prompts for approval
openclaw approvals defaults set security allowlist
openclaw approvals defaults set ask on-miss
openclaw approvals defaults set askFallback deny

echo "✅ Exec approvals configured: allowlist + ask on-miss"

echo "🚀 Starting OpenClaw gateway..."
exec openclaw gateway --allow-unconfigured --bind lan
