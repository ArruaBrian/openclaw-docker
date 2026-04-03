#!/bin/sh
set -e

# ── Copy staged config files with correct ownership ───────────────
# These are baked into the image at /opt/openclaw-config/
# We copy them at runtime so they have correct perms on the named volume
# Always overwrite exec-approvals.json so allowlist updates take effect on redeploy
cp /opt/openclaw-config/exec-approvals.json /home/node/.openclaw/exec-approvals.json 2>/dev/null || true
cp -n /opt/openclaw-config/AGENTS.md /home/node/workspace/AGENTS.md 2>/dev/null || true

# ── Fix ownership (volumes may be created as root) ─────────────────
chown -R 1000:1000 /home/node/.openclaw /home/node/workspace

# ── Start headless Chromium in background (as root, chromium uses --no-sandbox) ──
chromium --headless --no-sandbox --disable-gpu \
  --remote-debugging-address=127.0.0.1 \
  --remote-debugging-port=9222 \
  --remote-allow-origins=* &

echo "⏳ Waiting for Chromium to start..."
sleep 3

# ── Drop to node user for all OpenClaw operations ─────────────────
# Apply config, then start gateway — all as uid 1000 (node)
exec su -s /bin/sh node -c '
  # ── Gateway config ───────────────────────────────────────────────
  openclaw config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback true
  openclaw config set browser.enabled true
  openclaw config set browser.cdpUrl http://127.0.0.1:9222

  # ── Exec policy: allowlist mode with ask on-miss ─────────────────
  # Both layers must agree — openclaw.json (requested) + exec-approvals.json (host)
  openclaw config set tools.exec.host gateway
  openclaw config set tools.exec.security allowlist
  openclaw config set tools.exec.ask on-miss

  if [ -f /home/node/.openclaw/exec-approvals.json ]; then
    echo "✅ exec-approvals.json loaded (allowlist + ask on-miss)"
  else
    echo "⚠️  No exec-approvals.json found"
  fi

  echo "🚀 Starting OpenClaw gateway..."
  exec openclaw gateway --allow-unconfigured --bind lan
'
