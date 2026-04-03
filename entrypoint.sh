#!/bin/sh
set -e

# ── Copy staged config files with correct ownership ───────────────
cp /opt/openclaw-config/exec-approvals.json /home/node/.openclaw/exec-approvals.json 2>/dev/null || true
cp -n /opt/openclaw-config/AGENTS.md /home/node/workspace/AGENTS.md 2>/dev/null || true

# ── Fix ownership (volumes may be created as root) ─────────────────
chown -R 1000:1000 /home/node/.openclaw /home/node/workspace

# ── Start headless Chromium in background ──────────────────────────
chromium --headless --no-sandbox --disable-gpu \
  --remote-debugging-address=127.0.0.1 \
  --remote-debugging-port=9222 \
  --remote-allow-origins=* &

echo "⏳ Waiting for Chromium to start..."
sleep 3

# ── Drop to node user for all OpenClaw operations ─────────────────
exec su -s /bin/sh node -c '
  # ── Gateway UI config ────────────────────────────────────────────
  openclaw config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback true
  openclaw config set browser.enabled true
  openclaw config set browser.cdpUrl http://127.0.0.1:9222

  # ── LAYER 1: Enable tools with coding profile ───────────────────
  # Without this, exec tool is DISABLED by default (Jan 2026 security update)
  openclaw config set tools.profile coding

  # ── LAYER 2: Exec policy in openclaw.json ───────────────────────
  # host=gateway: run on gateway (no sandbox in this container)
  # security=allowlist: only allowlisted binaries auto-run
  # ask=on-miss: prompt for anything not in allowlist
  openclaw config set tools.exec.host gateway
  openclaw config set tools.exec.security allowlist
  openclaw config set tools.exec.ask on-miss

  # ── LAYER 3: exec-approvals.json (host policy) ─────────────────
  # Already copied above with matching security=allowlist, ask=on-miss
  # Contains binary path patterns for auto-approved commands

  echo "✅ Tools: coding profile enabled"
  echo "✅ Exec: host=gateway, security=allowlist, ask=on-miss"
  echo "✅ Allowlist: curl, python3, generate-*.sh, libreoffice, jq"
  echo "🚀 Starting OpenClaw gateway..."
  exec openclaw gateway --allow-unconfigured --bind lan
'
