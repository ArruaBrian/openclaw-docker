FROM ghcr.io/openclaw/openclaw:latest

USER root

# ── System deps: browser + document tools ──────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    # PDF tools
    poppler-utils \
    # Office docs (docx, xlsx → text)
    libreoffice-calc \
    libreoffice-writer \
    # Excel/CSV processing
    python3 python3-pip \
    # General utils
    curl jq \
    && rm -rf /var/lib/apt/lists/*

# ── Python tools for REAL document generation ──────────────────────
RUN pip3 install --no-cache-dir --break-system-packages \
    # Excel generation & manipulation
    openpyxl \
    xlsxwriter \
    pandas \
    tabulate \
    # Word document generation
    python-docx \
    # PDF generation
    reportlab \
    fpdf2 \
    # PDF manipulation (merge, split, watermark)
    pypdf \
    # HTML → PDF (uses chromium)
    weasyprint \
    # Markdown → anything
    markdown \
    # Charts & graphs for reports
    matplotlib \
    # Jinja2 for document templates
    jinja2

# ── Helper scripts for Discord file sending ────────────────────────
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# ── Bootstrap workspace with AGENTS.md ─────────────────────────────
COPY workspace/AGENTS.md /home/node/workspace/AGENTS.md

# ── Fix permissions once at build time ─────────────────────────────
RUN mkdir -p /home/node/.openclaw /home/node/workspace \
    && chown -R 1000:1000 /home/node/.openclaw /home/node/workspace

# ── Entrypoint that configures and launches ────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER node
EXPOSE 18789

ENTRYPOINT ["/entrypoint.sh"]
