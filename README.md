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

## Auto-Approve

Edit `config/allowlist.json` to add tools that should run without asking:

```json
{
  "autoApprove": [
    "read_file",
    "list_directory",
    "your_custom_tool"
  ]
}
```

Tools NOT in the list will still prompt for confirmation.

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
