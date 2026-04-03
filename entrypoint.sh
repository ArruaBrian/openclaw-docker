#!/bin/sh
set -e

# ── Copy AGENTS.md to workspace ────────────────────────────────────
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
exec su -s /bin/sh node << 'NODEEOF'
  set -e

  # ── Gateway UI config ────────────────────────────────────────────
  openclaw config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback true
  openclaw config set browser.enabled true
  openclaw config set browser.cdpUrl http://127.0.0.1:9222

  # ── LAYER 1: Enable exec tool (disabled by default since Jan 2026)
  openclaw config set tools.profile coding

  # ── LAYER 2: Exec policy in openclaw.json (requested policy) ─────
  openclaw config set tools.exec.host gateway
  openclaw config set tools.exec.security allowlist
  openclaw config set tools.exec.ask on-miss

  # ── LAYER 3: Host exec-approvals via official CLI ────────────────
  # Three pattern forms per binary to cover all matching strategies:
  #   1. Full path:  /usr/bin/curl     (resolved path match)
  #   2. Wildcard:   */curl            (glob match)
  #   3. Bare name:  curl              (basename match, may be ignored in some versions)
  # Duplicates and rejected entries are harmless.
  
  # curl
  openclaw approvals allowlist add "/usr/bin/curl"
  openclaw approvals allowlist add "*/curl"
  openclaw approvals allowlist add "curl" 2>/dev/null || true
  # document generation scripts
  openclaw approvals allowlist add "/usr/local/bin/generate-pdf.sh"
  openclaw approvals allowlist add "*/generate-pdf.sh"
  openclaw approvals allowlist add "generate-pdf.sh" 2>/dev/null || true
  openclaw approvals allowlist add "/usr/local/bin/generate-excel.sh"
  openclaw approvals allowlist add "*/generate-excel.sh"
  openclaw approvals allowlist add "generate-excel.sh" 2>/dev/null || true
  openclaw approvals allowlist add "/usr/local/bin/generate-docx.sh"
  openclaw approvals allowlist add "*/generate-docx.sh"
  openclaw approvals allowlist add "generate-docx.sh" 2>/dev/null || true
  openclaw approvals allowlist add "/usr/local/bin/send-to-discord.sh"
  openclaw approvals allowlist add "*/send-to-discord.sh"
  openclaw approvals allowlist add "send-to-discord.sh" 2>/dev/null || true
  # python & libreoffice
  openclaw approvals allowlist add "/usr/bin/python3"
  openclaw approvals allowlist add "*/python3"
  openclaw approvals allowlist add "python3" 2>/dev/null || true
  openclaw approvals allowlist add "/usr/bin/libreoffice"
  openclaw approvals allowlist add "*/libreoffice"
  openclaw approvals allowlist add "libreoffice" 2>/dev/null || true
  # common utils (full path + bare name)
  for cmd in jq cat ls mkdir cp mv head tail wc sort grep find echo; do
    openclaw approvals allowlist add "/usr/bin/$cmd"
    openclaw approvals allowlist add "*/$cmd"
    openclaw approvals allowlist add "$cmd" 2>/dev/null || true
  done
  # bash/sh for shell wrapping
  openclaw approvals allowlist add "/bin/sh"
  openclaw approvals allowlist add "/bin/bash"
  openclaw approvals allowlist add "/usr/bin/bash"
  openclaw approvals allowlist add "sh" 2>/dev/null || true
  openclaw approvals allowlist add "bash" 2>/dev/null || true

  echo "✅ Tools: coding profile enabled"
  echo "✅ Exec: host=gateway, security=allowlist, ask=on-miss"
  echo "✅ Allowlist: binaries added via 'openclaw approvals allowlist add'"
  echo "🚀 Starting OpenClaw gateway..."
  exec openclaw gateway --allow-unconfigured --bind lan
NODEEOF
