# OpenClaw — Custom Docker Setup

## Quick Start

```bash
# 1. Copy env and fill in your tokens
cp .env.example .env

# 2. Build and run (first time takes a bit, after that it's instant)
docker compose up -d --build

# 3. Subsequent deploys — no reinstall, just restart
docker compose up -d
```

## What's included

- **Chromium headless** — baked into the image, no reinstall on restart
- **Document tools** — LibreOffice, poppler (PDF), openpyxl, python-docx
- **Discord file sending** — `send-to-discord.sh` script
- **Auto-approve allowlist** — edit `config/allowlist.json`
- **Persistent volumes** — data and workspace survive rebuilds

## Exec Approvals (Command Security)

OpenClaw uses `exec-approvals.json` to control which commands run automatically vs which ones ask first.

Edit `config/exec-approvals.json` to manage the allowlist. Patterns are glob paths to binaries:

```json
{
  "agents": {
    "main": {
      "security": "allowlist",
      "ask": "on-miss",
      "allowlist": [
        { "pattern": "/usr/bin/curl" },
        { "pattern": "/usr/local/bin/generate-*.sh" },
        { "pattern": "/usr/bin/python3" }
      ]
    }
  }
}
```

- Commands matching allowlist patterns → run without asking
- Commands NOT in allowlist → prompt for approval (ask: on-miss)
- No rebuild needed — the file is bind-mounted

## Document Generation Scripts (available inside container)

| Script | Description |
|--------|-------------|
| `generate-excel.sh <output.xlsx> [data.json]` | Generate Excel with formatting, headers, styles |
| `generate-docx.sh <output.docx> [input.md\|json]` | Generate Word docs from markdown or structured JSON |
| `generate-pdf.sh <output.pdf> [input.md\|json]` | Generate styled PDFs with tables, bullets, headings |
| `send-to-discord.sh <file> <channel-id> [msg]` | Send any file to a Discord channel |

All scripts accept piped input: `echo '[{"name":"John"}]' | generate-excel.sh report.xlsx`

### Python libraries available for custom scripts

- **Excel**: `xlsxwriter`, `openpyxl`, `pandas`
- **Word**: `python-docx`
- **PDF**: `fpdf2`, `reportlab`, `weasyprint`, `pypdf`
- **Charts**: `matplotlib`
- **Templates**: `jinja2`, `markdown`

## Rebuild without losing data

```bash
docker compose up -d --build
```

Volumes are named and persistent — your `.openclaw` config and workspace stay intact.
